<#
.SYNOPSIS
Find Fabric workspaces/items that appear to use Spark Runtime 1.2.

.DESCRIPTION
The script scans all accessible Fabric workspaces, checks runtime-related settings,
and returns matching workspaces plus Spark items (Notebook/SparkJobDefinition).

.NOTES
- Requires Az.Accounts and an authenticated session (`Connect-AzAccount`).
- API coverage is best-effort because runtime settings can surface via different endpoints.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$OutputCsv
)

function Convert-TokenToPlainText {
    param([object]$TokenValue)

    if ($TokenValue -is [string]) { return $TokenValue }
    if ($TokenValue -is [securestring]) { return [System.Net.NetworkCredential]::new('', $TokenValue).Password }

    return [string]$TokenValue
}

function Get-FabricAuthHeader {
    $tokenResponse = Get-AzAccessToken -ResourceUrl 'https://analysis.windows.net/powerbi/api'
    $token = Convert-TokenToPlainText -TokenValue $tokenResponse.Token

    return @{ Authorization = "Bearer $token" }
}

function Get-AllFabricPages {
    param(
        [string]$BaseUrl,
        [hashtable]$Headers
    )

    $all = @()
    $url = $BaseUrl

    while ($url) {
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
        if ($response.value) {
            $all += $response.value
        }

        if ($response.continuationToken) {
            $separator = if ($BaseUrl -match '\?') { '&' } else { '?' }
            $escapedToken = [uri]::EscapeDataString($response.continuationToken)
            $url = "$BaseUrl${separator}continuationToken=$escapedToken"
        } else {
            $url = $null
        }
    }

    return $all
}

function Test-WorkspaceUsesRuntime12 {
    param(
        [string]$WorkspaceId,
        [hashtable]$Headers
    )

    $urls = @(
        "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/settings",
        "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/spark/settings",
        "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId/sparkSettings",
        "https://api.fabric.microsoft.com/v1/workspaces/$WorkspaceId"
    )

    foreach ($url in $urls) {
        try {
            $settings = Invoke-RestMethod -Method Get -Uri $url -Headers $Headers
            $json = $settings | ConvertTo-Json -Depth 40

            if ($json -match '(?i)"runtimeVersion"\s*:\s*"1\.2([^"]*)"|"defaultRuntimeVersion"\s*:\s*"1\.2([^"]*)"|"sparkRuntimeVersion"\s*:\s*"1\.2([^"]*)"|Runtime\s*1\.2|Spark\s*1\.2') {
                return $true
            }
        } catch {
            continue
        }
    }

    return $false
}

Write-Host 'Authenticating to Azure...'
Connect-AzAccount | Out-Null
$headers = Get-FabricAuthHeader

Write-Host 'Scanning Fabric workspaces for Runtime 1.2...'
$workspaces = Get-AllFabricPages -BaseUrl 'https://api.fabric.microsoft.com/v1/workspaces' -Headers $headers
$results = @()

foreach ($workspace in $workspaces) {
    if (-not (Test-WorkspaceUsesRuntime12 -WorkspaceId $workspace.id -Headers $headers)) {
        continue
    }

    $results += [pscustomobject]@{
        WorkspaceName = $workspace.displayName
        WorkspaceId   = $workspace.id
        ItemType      = 'Workspace'
        ItemName      = $workspace.displayName
        ItemId        = $workspace.id
    }

    $itemsUrl = "https://api.fabric.microsoft.com/v1/workspaces/$($workspace.id)/items"
    $items = Get-AllFabricPages -BaseUrl $itemsUrl -Headers $headers

    foreach ($item in $items | Where-Object { $_.type -in @('Notebook', 'SparkJobDefinition') }) {
        $results += [pscustomobject]@{
            WorkspaceName = $workspace.displayName
            WorkspaceId   = $workspace.id
            ItemType      = $item.type
            ItemName      = $item.displayName
            ItemId        = $item.id
        }
    }
}

$results = $results | Sort-Object WorkspaceName, ItemType, ItemName

if ($OutputCsv) {
    $results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8
    Write-Host "Saved CSV: $OutputCsv"
}

Write-Host ("Matches found: {0}" -f @($results).Count)
$results | Format-Table -AutoSize
