"""
Encrypt Service Principal credentials for a Fabric Gateway connection.

This script fetches the gateway public key from the Fabric API and generates an
encrypted payload compatible with gateway credential APIs.

Requirements:
    - Python 3.9+
    - Azure CLI logged in (`az login`)
    - Packages: requests, pycryptodome
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
from base64 import b64decode, b64encode

import requests
from Crypto.Cipher import AES, PKCS1_OAEP
from Crypto.Hash import HMAC, SHA256
from Crypto.PublicKey import RSA
from Crypto.Random import get_random_bytes

FABRIC_RESOURCE = "https://api.fabric.microsoft.com"


def get_azure_cli_access_token(resource: str = FABRIC_RESOURCE) -> str:
    """Return an access token from Azure CLI for the requested resource."""
    command = [
        "az",
        "account",
        "get-access-token",
        "--resource",
        resource,
        "--output",
        "json",
    ]

    result = subprocess.run(command, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        raise RuntimeError(f"Azure CLI error: {result.stderr.strip()}")

    token_data = json.loads(result.stdout)
    return token_data["accessToken"]


def get_public_key_from_gateway(gateway_id: str, access_token: str) -> tuple[str, str]:
    """Fetch gateway RSA exponent and modulus from Fabric API."""
    url = f"{FABRIC_RESOURCE}/v1/gateways/{gateway_id}"
    headers = {
        "Authorization": f"Bearer {access_token}",
        "Accept": "application/json",
    }

    response = requests.get(url, headers=headers, timeout=30)
    response.raise_for_status()
    data = response.json()

    return data["publicKey"]["exponent"], data["publicKey"]["modulus"]


def map_generated_key_length(key: bytes) -> int:
    """Map key length to Fabric expected key-length flag."""
    if len(key) == 32:
        return 0
    if len(key) == 64:
        return 1
    raise ValueError(f"Unsupported key length: {len(key)}")


def get_signed_payload(ciphertext: bytes, iv: bytes, sign_key: bytes) -> str:
    """Build and sign payload metadata + ciphertext using HMAC-SHA256."""
    algorithms = bytes([0, 0])
    to_sign = algorithms + iv + ciphertext

    hmac = HMAC.new(sign_key, digestmod=SHA256)
    hmac.update(to_sign)
    signature = hmac.digest()

    full_payload = algorithms + signature + iv + ciphertext
    return b64encode(full_payload).decode("utf-8")


def encrypt_keys(modulus_b64: str, exponent_b64: str, symmetric_key: bytes, sign_key: bytes) -> str:
    """Encrypt AES and signing keys with gateway RSA public key (OAEP-SHA256)."""
    modulus_bytes = b64decode(modulus_b64 + "==")
    exponent_bytes = b64decode(exponent_b64 + "==")

    modulus_int = int.from_bytes(modulus_bytes, byteorder="big")
    exponent_int = int.from_bytes(exponent_bytes, byteorder="big")
    rsa_key = RSA.construct((modulus_int, exponent_int))

    cipher_rsa = PKCS1_OAEP.new(rsa_key, hashAlgo=SHA256)
    lengths = bytes([map_generated_key_length(symmetric_key), map_generated_key_length(sign_key)])
    combined_keys = lengths + symmetric_key + sign_key

    encrypted_keys = cipher_rsa.encrypt(combined_keys)
    return b64encode(encrypted_keys).decode("utf-8")


def build_credentials_json(tenant_id: str, client_id: str, client_secret: str) -> str:
    """Build compact credentialData payload expected by Fabric gateway APIs."""
    payload = {
        "credentialData": [
            {"name": "tenantId", "value": tenant_id},
            {"name": "servicePrincipalClientId", "value": client_id},
            {"name": "servicePrincipalSecret", "value": client_secret},
        ]
    }
    return json.dumps(payload, separators=(",", ":"))


def encrypt_credentials(credentials: str, gateway_id: str) -> str:
    """Run full encryption flow and return final encrypted credential string."""
    access_token = get_azure_cli_access_token()
    exponent_b64, modulus_b64 = get_public_key_from_gateway(gateway_id, access_token)

    aes_key = get_random_bytes(32)
    iv = get_random_bytes(16)
    sign_key = bytearray(get_random_bytes(64))

    cipher_aes = AES.new(aes_key, AES.MODE_CBC, iv)
    plaintext = credentials.encode("utf-8")
    padding_length = 16 - (len(plaintext) % 16)
    padded = plaintext + bytes([padding_length] * padding_length)
    ciphertext = cipher_aes.encrypt(padded)

    signed_payload = get_signed_payload(ciphertext, iv, sign_key)
    encrypted_keys = encrypt_keys(modulus_b64, exponent_b64, aes_key, sign_key)

    for index in range(len(sign_key)):
        sign_key[index] = 0

    return encrypted_keys + signed_payload


def parse_args() -> argparse.Namespace:
    """Parse command-line args (or use FABRIC_* environment variables)."""
    parser = argparse.ArgumentParser(description="Encrypt Fabric Gateway Service Principal credentials")
    parser.add_argument("--gateway-id", default=os.getenv("FABRIC_GATEWAY_ID"), help="Fabric Gateway ID")
    parser.add_argument("--tenant-id", default=os.getenv("FABRIC_TENANT_ID"), help="Microsoft Entra tenant ID")
    parser.add_argument("--client-id", default=os.getenv("FABRIC_CLIENT_ID"), help="Service Principal client ID")
    parser.add_argument("--client-secret", default=os.getenv("FABRIC_CLIENT_SECRET"), help="Service Principal client secret")
    return parser.parse_args()


def validate_required_args(args: argparse.Namespace) -> None:
    """Ensure all required values are present."""
    missing = [
        name
        for name, value in {
            "gateway-id": args.gateway_id,
            "tenant-id": args.tenant_id,
            "client-id": args.client_id,
            "client-secret": args.client_secret,
        }.items()
        if not value
    ]

    if missing:
        joined = ", ".join(missing)
        raise ValueError(f"Missing required values: {joined}. Use arguments or FABRIC_* environment variables.")


def main() -> None:
    """Entry point for script usage."""
    args = parse_args()
    validate_required_args(args)

    credentials = build_credentials_json(args.tenant_id, args.client_id, args.client_secret)
    encrypted = encrypt_credentials(credentials, args.gateway_id)
    print(encrypted)


if __name__ == "__main__":
    main()
