# Workspace Runtime Audit Samples

This folder contains a PowerShell script to find Microsoft Fabric workspaces that appear to use **Spark Runtime 1.2**, and list related Spark items.

## Why

Identifying Spark Runtime 1.2 usage is important for upgrade planning, compatibility validation, and reducing operational risk before runtime changes.

Use this script to quickly inventory affected workspaces and Spark assets so teams can prioritize remediation and migration work.

Reference guidance:

- https://learn.microsoft.com/en-us/fabric/data-engineering/runtime-1-2

## Included Script

- `find-fabric-runtime12-workspaces.ps1`

## What the script does

1. Authenticates with Azure (`Connect-AzAccount`).
2. Gets a Fabric API access token via `Get-AzAccessToken` (Power BI resource URL).
3. Enumerates all accessible Fabric workspaces from:
   - `GET https://api.fabric.microsoft.com/v1/workspaces`
4. For each workspace, checks multiple settings endpoints (best-effort) and searches for Runtime 1.2 indicators:
   - `/v1/workspaces/{workspaceId}/settings`
   - `/v1/workspaces/{workspaceId}/spark/settings`
   - `/v1/workspaces/{workspaceId}/sparkSettings`
   - `/v1/workspaces/{workspaceId}`
5. If a workspace appears to use Runtime 1.2, adds a workspace-level match and then lists Spark items in that workspace:
   - `Notebook`
   - `SparkJobDefinition`

## Prerequisites

- PowerShell 7+ (recommended)
- `Az.Accounts` module
- Access to Microsoft Fabric REST APIs for the target tenant/workspaces

Install module (if needed):

```powershell
Install-Module Az.Accounts -Scope CurrentUser
```

## Usage

Run and print results:

```powershell
./find-fabric-runtime12-workspaces.ps1
```

Run and also export CSV:

```powershell
./find-fabric-runtime12-workspaces.ps1 -OutputCsv .\runtime12-matches.csv
```

## Output columns

- `WorkspaceName`
- `WorkspaceId`
- `ItemType` (`Workspace`, `Notebook`, `SparkJobDefinition`)
- `ItemName`
- `ItemId`

## Notes / limitations

- Detection is **best-effort** because runtime settings can surface differently across APIs/workspaces.
- A workspace can be matched from settings even if no Spark items are returned.
- Script only scans workspaces the signed-in identity can access.
- Provided as-is, with no warranty or support commitments.
