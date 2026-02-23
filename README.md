# NLCSU Script Samples

Sample scripts maintained by the Netherlands Customer Success Unit (NL CSU).

This repository is intended as a practical starting point for field/customer-success scenarios. It is **not** an official product repository and does not represent commitments from Microsoft product engineering teams.

## Scope

Current sample set under `fabric/`:

- `gateway-connection-credentials`
  - PowerShell and Python samples for encrypting Service Principal credentials for Fabric connection creation scenarios.
  - Related REST API: https://learn.microsoft.com/en-us/rest/api/fabric/core/connections/create-connection?tabs=HTTP
- `workspace-runtime-audit`
  - PowerShell sample to find workspaces/items that appear to use Fabric Runtime 1.2.
- `lakehouse-shortcut-audit`
  - Notebook to detect lakehouse shortcuts that point to Delta multipart checkpoints.

## Folder Structure

- `fabric/gateway-connection-credentials/encrypt-gateway-credentials.ps1`
- `fabric/gateway-connection-credentials/encrypt-gateway-credentials.py`
- `fabric/gateway-connection-credentials/README.md`
- `fabric/workspace-runtime-audit/find-fabric-runtime12-workspaces.ps1`
- `fabric/lakehouse-shortcut-audit/find-multipart-shortcut-checkpoints.ipynb`
- `fabric/lakehouse-shortcut-audit/README.md`

## Usage Notes

- Review scripts before use and adapt them to your tenant/security requirements.
- Do not commit real credentials, secrets, or tokens.
- Prefer environment variables or secure secret stores for sensitive values.
- Do not include customer-identifiable data in code, notebooks, or outputs.

## Publishing Guardrails

- This repository is for sample code and field accelerators only.
- No production support or SLA is implied.
- Every contribution must avoid hardcoded secrets, tokens, and tenant-specific sensitive data.
- Keep scripts generic and reusable across customers.

## Disclaimer

These materials are provided **"as is"**, without warranty of any kind, express or implied, including but not limited to warranties of merchantability, fitness for a particular purpose, and non-infringement.

No guarantees, support obligations, or service-level commitments are provided. You are responsible for validating behavior, security, and compliance in your own environment before production use.

See [DISCLAIMER.md](DISCLAIMER.md) for the full disclaimer text.
