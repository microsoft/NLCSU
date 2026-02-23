# Encrypts Service Principal credentials for a Fabric Gateway connection.
# Requires Az.Accounts module and authenticated session via Connect-AzAccount.
# Uses AES-CBC + HMAC-SHA256 and RSA-OAEP-SHA256, aligned with existing logic.

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$GatewayId = $env:FABRIC_GATEWAY_ID,

    [Parameter(Mandatory = $false)]
    [string]$TenantId = $env:FABRIC_TENANT_ID,

    [Parameter(Mandatory = $false)]
    [string]$ClientId = $env:FABRIC_CLIENT_ID,

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret = $env:FABRIC_CLIENT_SECRET
)

function Convert-TokenToPlainText {
    param([object]$TokenValue)

    if ($TokenValue -is [string]) { return $TokenValue }
    if ($TokenValue -is [securestring]) { return [System.Net.NetworkCredential]::new('', $TokenValue).Password }

    return [string]$TokenValue
}

function Get-FabricAccessToken {
    $tokenResponse = Get-AzAccessToken -ResourceUrl 'https://api.fabric.microsoft.com'
    return Convert-TokenToPlainText -TokenValue $tokenResponse.Token
}

function Get-PublicKeyFromGateway {
    param([string]$GatewayId)

    $fabricToken = Get-FabricAccessToken
    $url = "https://api.fabric.microsoft.com/v1/gateways/$GatewayId"

    $headers = @{
        Authorization = "Bearer $fabricToken"
        Accept        = 'application/json'
    }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get
    return @{
        Exponent = $response.publicKey.exponent
        Modulus  = $response.publicKey.modulus
    }
}

function Add-Pkcs7Padding {
    param(
        [byte[]]$Data,
        [int]$BlockSize = 16
    )

    $padLen = $BlockSize - ($Data.Length % $BlockSize)
    return $Data + ([byte[]]@($padLen) * $padLen)
}

function Join-ByteArrays {
    param([byte[][]]$Arrays)

    $totalLength = ($Arrays | Measure-Object -Property Length -Sum).Sum
    $result = New-Object byte[] $totalLength
    $offset = 0

    foreach ($arr in $Arrays) {
        [Array]::Copy($arr, 0, $result, $offset, $arr.Length)
        $offset += $arr.Length
    }

    return $result
}

function Get-SignedPayload {
    param(
        [byte[]]$CipherText,
        [byte[]]$Iv,
        [byte[]]$SignKey
    )

    $algorithms = [byte[]](0, 0)
    $toSign = Join-ByteArrays -Arrays @($algorithms, $Iv, $CipherText)

    $hmac = New-Object System.Security.Cryptography.HMACSHA256
    $hmac.Key = $SignKey
    $signature = $hmac.ComputeHash($toSign)

    $fullPayload = Join-ByteArrays -Arrays @($algorithms, $signature, $Iv, $CipherText)
    return [Convert]::ToBase64String($fullPayload)
}

function Get-KeyLengthFlag {
    param([byte[]]$Key)

    if ($Key.Length -eq 32) { return 0 }
    if ($Key.Length -eq 64) { return 1 }

    throw "Unsupported key length: $($Key.Length)"
}

function Protect-SessionKeys {
    param(
        [string]$ModulusBase64,
        [string]$ExponentBase64,
        [byte[]]$SymmetricKey,
        [byte[]]$SignKey
    )

    $modulus = [Convert]::FromBase64String($ModulusBase64)
    $exponent = [Convert]::FromBase64String($ExponentBase64)

    $rsa = [System.Security.Cryptography.RSA]::Create()
    $rsa.ImportParameters([System.Security.Cryptography.RSAParameters]@{
        Modulus  = $modulus
        Exponent = $exponent
    })

    $lengthFlags = [byte[]]@(
        (Get-KeyLengthFlag -Key $SymmetricKey),
        (Get-KeyLengthFlag -Key $SignKey)
    )

    $combined = Join-ByteArrays -Arrays @($lengthFlags, $SymmetricKey, $SignKey)
    $encrypted = $rsa.Encrypt($combined, [System.Security.Cryptography.RSAEncryptionPadding]::OaepSHA256)

    return [Convert]::ToBase64String($encrypted)
}

function Get-EncryptedGatewayCredentials {
    param(
        [Parameter(Mandatory = $true)]
        [string]$GatewayId,

        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $publicKey = Get-PublicKeyFromGateway -GatewayId $GatewayId

    $credentialsJson = @{
        credentialData = @(
            @{ name = 'tenantId'; value = $TenantId },
            @{ name = 'servicePrincipalClientId'; value = $ClientId },
            @{ name = 'servicePrincipalSecret'; value = $ClientSecret }
        )
    } | ConvertTo-Json -Depth 3 -Compress

    $aesKey = New-Object byte[] 32
    $iv = New-Object byte[] 16
    $signKey = New-Object byte[] 64

    [System.Security.Cryptography.RandomNumberGenerator]::Fill($aesKey)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($iv)
    [System.Security.Cryptography.RandomNumberGenerator]::Fill($signKey)

    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Mode = 'CBC'
    $aes.Padding = 'None'
    $aes.Key = $aesKey
    $aes.IV = $iv

    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($credentialsJson)
    $padded = Add-Pkcs7Padding -Data $plainBytes
    $cipherText = $aes.CreateEncryptor().TransformFinalBlock($padded, 0, $padded.Length)

    $signedPayload = Get-SignedPayload -CipherText $cipherText -Iv $iv -SignKey $signKey
    $encryptedKeys = Protect-SessionKeys -ModulusBase64 $publicKey.Modulus -ExponentBase64 $publicKey.Exponent -SymmetricKey $aesKey -SignKey $signKey

    [Array]::Clear($signKey, 0, $signKey.Length)
    return $encryptedKeys + $signedPayload
}

if (-not $GatewayId -or -not $TenantId -or -not $ClientId -or -not $ClientSecret) {
    throw 'Provide GatewayId, TenantId, ClientId and ClientSecret via parameters or FABRIC_* environment variables.'
}

$encryptedCredentials = Get-EncryptedGatewayCredentials -GatewayId $GatewayId -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
Write-Output $encryptedCredentials
