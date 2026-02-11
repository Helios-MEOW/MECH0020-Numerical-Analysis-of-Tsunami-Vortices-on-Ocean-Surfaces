# Notion Agent Tracking Setup (Fallback Path)

This project keeps your personal todo database untouched. Use a separate child database under page:

- Parent page ID: `d18abae6-d987-8387-a2cf-81860c4aa228`
- Parent URL: `https://www.notion.so/honto-ni-mendokusaii/MECH0020-Goals-d18abae6d9878387a2cf81860c4aa228`

## Required Database Properties

Create a dedicated database with:

- `Task` (title)
- `Status` (select): `Planned`, `In Progress`, `Blocked`, `Done`
- `Solution` (rich_text)
- `Result` (rich_text)
- `Updated` (date)

## API Setup

1. Create/confirm a Notion integration and share the parent page with it.
2. Set env vars:

```powershell
$env:NOTION_TOKEN = "secret_..."
$env:NOTION_VERSION = "2022-06-28"
```

## Create Child Tracking Database (PowerShell)

```powershell
$headers = @{
  Authorization = "Bearer $env:NOTION_TOKEN"
  "Notion-Version" = $env:NOTION_VERSION
  "Content-Type" = "application/json"
}

$body = @{
  parent = @{ type = "page_id"; page_id = "d18abae6-d987-8387-a2cf-81860c4aa228" }
  title = @(@{ type = "text"; text = @{ content = "MECH0020 Agent Tracking" } })
  properties = @{
    Task = @{ title = @{} }
    Status = @{ select = @{ options = @(
      @{ name = "Planned" },
      @{ name = "In Progress" },
      @{ name = "Blocked" },
      @{ name = "Done" }
    ) } }
    Solution = @{ rich_text = @{} }
    Result = @{ rich_text = @{} }
    Updated = @{ date = @{} }
  }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method Post -Uri "https://api.notion.com/v1/databases" -Headers $headers -Body $body
```

## Create/Update Task Entry Template

Use this template per work item in the separate agent-tracking database:

```text
Status:
Solution:
Result:
Evidence:
Updated:
```

## Example Entry Payload

```powershell
$databaseId = "<agent_tracking_database_id>"
$today = (Get-Date).ToString("yyyy-MM-dd")

$entry = @{
  parent = @{ database_id = $databaseId }
  properties = @{
    Task = @{ title = @(@{ type = "text"; text = @{ content = "UI dark theme + launch and IC fixes" } }) }
    Status = @{ select = @{ name = "Done" } }
    Solution = @{ rich_text = @(@{ type = "text"; text = @{ content = "Enabled dark theme, fixed launch pipeline, aligned IC preview/build with dispatcher-compatible ic_coeff." } }) }
    Result = @{ rich_text = @(@{ type = "text"; text = @{ content = "Launch no longer depends on missing ic_pattern handle and supports Evolution/Convergence/Sweep/Animation/Experimentation routing." } }) }
    Updated = @{ date = @{ start = $today } }
  }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method Post -Uri "https://api.notion.com/v1/pages" -Headers $headers -Body $entry
```
