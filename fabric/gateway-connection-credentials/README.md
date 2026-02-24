# Gateway Connection Credentials Samples

This folder contains sample scripts to prepare encrypted Service Principal credentials for Fabric connection creation scenarios that use an on-premises data gateway.

When creating connections through an on-premises gateway, credentials must be encrypted before they are sent to the Fabric Connections API. These scripts simplify that encryption step.

## Related Fabric REST API

- Create Connection:
  - https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/create-connection?tabs=HTTP

## Included Scripts

- `encrypt-gateway-credentials.ps1`
- `encrypt-gateway-credentials.py`

## Notes

- Scripts are sample-only and intended as a starting point.
- Applicable to on-premises gateway connection scenarios where encrypted credentials are required.
- Validate behavior and security requirements before production usage.
- Use secure secret handling; do not hardcode or commit real credentials.
- Provided as-is, with no warranty or support commitments.
