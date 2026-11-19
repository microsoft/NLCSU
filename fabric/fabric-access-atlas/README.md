# Fabric Access Atlas

A practical, interactive guide for Microsoft Fabric customers that simplifies
workspace roles, item permissions and data access decisions.

Use the atlas to understand who can open an item, which data they can read, and
which identity is used by a query or job. It brings the access paths together in
one visual reference, with common customer scenarios and links to Microsoft Learn.

## Open the atlas

Open [Fabric Access Atlas](https://microsoft.github.io/NLCSU/fabric/fabric-access-atlas/)
directly in your browser, or download the file to use it locally:

1. Open [index.html](./index.html) in GitHub.
2. Select **Download raw file** in the file toolbar. Save the file as `index.html`
   if your browser prompts for a name.
3. Open the downloaded file in a current version of Microsoft Edge, Chrome,
   Firefox or Safari, with JavaScript enabled.

The atlas is a single, self-contained HTML file. No installation, local server,
Fabric tenant, license or sign-in is required to read it. It makes no tenant/API
calls, collects no data and loads no external libraries, fonts or scripts.
Microsoft Learn and repository links need an internet connection when opened.
Using the Fabric features described still requires the applicable licensing,
capacity, permissions and feature availability.

**GitHub displays HTML source rather than running the interactive page.**

## Explore

- **Start with a scenario:** report consumer, SQL view-only consumer,
  notebook/pipeline operator, data engineer, workspace administrator or
  Real-Time reader.
- **Follow the map:** identity and groups, workspace or item access, then the
  relevant item family and data route.
- **Preview and open:** hover over or keyboard-focus a card for a summary.
  Map and scenario cards open full guidance in a new tab. Press **Escape** to
  dismiss a preview.
- **Check the details:** compare inherited permissions, effective identities and
  OneLake security behavior; use the linked Microsoft Learn sources for specifics.
- **On smaller screens:** scroll the map horizontally. Expand the map legend
  for abbreviations and permission terms.

Covered families include Lakehouse and OneLake, SQL data items, Power BI,
execution and orchestration, Real-Time and Fabric IQ, and supporting items such
as ML models, variable libraries, Maps and environments.

## Scope and limitations

- Reference snapshot: **18 November 2026**. Features and preview behavior can
  change; follow the current Microsoft Learn sources linked from each topic.
- This is a learning and planning aid, not a tenant audit, exhaustive permission
  specification or automatic least-privilege recommendation.
- Consider direct grants, group membership, workspace inheritance, connection
  identities and engine-specific policies together. Test with the intended
  consumer identity rather than an administrator.
- Provided **as is**, without warranty, production support or SLA. This is not
  official Microsoft product documentation or a product engineering commitment.

See the repository [disclaimer](../../DISCLAIMER.md) and
[MIT license](../../LICENSE.txt). The HTML also includes the MIT license notice
so it can be redistributed as a standalone file.
