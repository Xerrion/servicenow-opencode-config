# ServiceNow OpenCode Config

Agents, skills, and slash commands for ServiceNow development with [OpenCode](https://opencode.ai) and the [servicenow-devtools-mcp](https://github.com/lasn/servicenow-devtools-mcp) server.

## What's Included

| Type | Name | Description |
|---|---|---|
| **Agent** | `servicenow` | ServiceNow platform expert - investigations, debugging, record operations, change intelligence |
| **Agent** | `servicenow-dev` | Script development subagent - writes, deploys, and verifies platform artifacts |
| **Skill** | `servicenow-scripting` | Core server-side scripting standards (Script Includes, naming, error handling, JSDoc) |
| **Skill** | `servicenow-business-rules` | Business Rule timing, filter conditions, delegation patterns |
| **Skill** | `servicenow-client-scripts` | Client Scripts, UI Policies, GlideAjax, g_scratchpad patterns |
| **Skill** | `servicenow-gliderecord` | GlideRecord/GlideAggregate best practices, query patterns, anti-patterns |
| **Command** | `/sn-write` | Write and deploy a ServiceNow artifact (Business Rule, Script Include, etc.) |
| **Command** | `/sn-debug` | Full debug pipeline for incidents (trace, field mutations, flows, emails) |
| **Command** | `/sn-health` | Run all 7 investigation modules and triage findings |
| **Command** | `/sn-logic-map` | Generate lifecycle logic map of all automations on a table |
| **Command** | `/sn-review` | Code review pipeline for platform artifacts |
| **Command** | `/sn-updateset` | Inspect update sets and generate release notes |

## Prerequisites

1. [OpenCode](https://opencode.ai) installed and configured
2. [uv](https://docs.astral.sh/uv/getting-started/installation/) package manager (for running the MCP server)
3. ServiceNow instance credentials (username, password, instance URL)

## Quick Start

### macOS / Linux

```bash
# 1. Clone this repo
git clone <repo-url> ~/Projects/servicenow-opencode-config

# 2. Run the installer (creates symlinks into ~/.config/opencode/)
cd ~/Projects/servicenow-opencode-config
./install.sh

# 3. Add the MCP server to your opencode.jsonc
#    Copy the config from mcp-config-template.jsonc into your
#    opencode.jsonc under "mcpServers"

# 4. Set your ServiceNow credentials as environment variables
#    Add these to your shell profile (~/.zshrc, ~/.bashrc, etc.):
export SERVICENOW_INSTANCE_URL="https://your-instance.service-now.com"
export SERVICENOW_USERNAME="your-username"
export SERVICENOW_PASSWORD="your-password"
export SERVICENOW_ENV="dev"
```

### Windows (PowerShell)

```powershell
# 1. Clone this repo
git clone <repo-url> $HOME\Projects\servicenow-opencode-config

# 2. Run the installer (creates symlinks into ~/.config/opencode/)
cd $HOME\Projects\servicenow-opencode-config
.\install.ps1

# 3. Add the MCP server to your opencode.jsonc
#    Copy the config from mcp-config-template.jsonc into your
#    opencode.jsonc under "mcpServers"

# 4. Set your ServiceNow credentials as environment variables
#    Add these to your PowerShell profile ($PROFILE) or set them
#    in Settings > System > Environment Variables:
$env:SERVICENOW_INSTANCE_URL = "https://your-instance.service-now.com"
$env:SERVICENOW_USERNAME = "your-username"
$env:SERVICENOW_PASSWORD = "your-password"
$env:SERVICENOW_ENV = "dev"
```

> **Tip:** To persist environment variables on Windows, add the `$env:` lines to your PowerShell profile (`$PROFILE`), or set them permanently via Settings > System > About > Advanced system settings > Environment Variables.

## MCP Server Configuration

The MCP server connects OpenCode to your ServiceNow instance. Add the server entry to your `opencode.jsonc` file - see `mcp-config-template.jsonc` in this repo for the full template you can copy.

### Required Environment Variables

| Variable | Description |
|---|---|
| `SERVICENOW_INSTANCE_URL` | Instance URL (must start with `https://`) |
| `SERVICENOW_USERNAME` | ServiceNow username |
| `SERVICENOW_PASSWORD` | ServiceNow password |

### Optional Environment Variables

| Variable | Default | Description |
|---|---|---|
| `MCP_TOOL_PACKAGE` | `full` | Controls which tools are loaded (see packages below) |
| `SERVICENOW_ENV` | `dev` | Environment label. Set to `production` to enable write protection |
| `SCRIPT_ALLOWED_ROOT` | (empty) | Root directory for the `script_path` parameter on `artifact_create`/`artifact_update` |

### Tool Packages

The `MCP_TOOL_PACKAGE` variable controls which tools the server exposes. Preset packages:

- `full` - all standard tool groups (default)
- `core_readonly` - read-only core tools
- `itil` - ITIL process tools
- `developer` - development-focused tools
- `readonly` - read-only operations
- `analyst` - analysis and reporting
- `incident_management` - incident lifecycle tools
- `change_management` - change request tools
- `cmdb` - CMDB management tools
- `problem_management` - problem lifecycle tools
- `request_management` - request/RITM tools
- `knowledge_management` - knowledge base tools
- `service_catalog` - service catalog tools

## Usage

### Agents

Type `@servicenow` to switch to the ServiceNow agent in OpenCode. It handles platform operations, investigations, and debugging. When you ask it to write scripts, it automatically delegates to `@servicenow-dev`.

### Slash Commands

Type the command name directly in the chat:

- `/sn-write` - create or modify a ServiceNow artifact
- `/sn-debug INC0012345` - debug an incident
- `/sn-health` - run health investigations
- `/sn-logic-map incident` - map all automations on a table
- `/sn-review` - review a platform artifact's code
- `/sn-updateset` - inspect an update set

### Skills

Skills are loaded automatically by agents when needed. For example, when writing Business Rules, the `servicenow-business-rules` skill is loaded on demand - no manual action required.

## Updating

```bash
cd ~/Projects/servicenow-opencode-config   # macOS/Linux
cd $HOME\Projects\servicenow-opencode-config   # Windows
git pull
```

Since the installer creates symlinks, pulling updates automatically takes effect - no re-install needed.

## Uninstalling

macOS / Linux:

```bash
cd ~/Projects/servicenow-opencode-config
./uninstall.sh
```

Windows (PowerShell):

```powershell
cd $HOME\Projects\servicenow-opencode-config
.\uninstall.ps1
```

This only removes symlinks that point back into this repo. Your other OpenCode configs are untouched.

## Reinstalling / Force Overwrite

macOS / Linux:

```bash
./install.sh --force
```

Windows (PowerShell):

```powershell
.\install.ps1 -Force
```

Replaces existing files with symlinks to this repo.

## Troubleshooting

**"OpenCode config directory not found"** - Install OpenCode first, then re-run the installer.

**Commands or agents not showing up** - Restart OpenCode after installation for changes to take effect.

**MCP server not connecting** - Verify your environment variables are set correctly and the server itself works:

```bash
uv run servicenow-devtools-mcp --help
```

If this fails, check that you have `uv` installed and the `servicenow-devtools-mcp` package is accessible.

**"Symlink creation failed" (Windows)** - Enable Developer Mode in Windows Settings > For developers, or run PowerShell as Administrator. Windows requires elevated privileges or Developer Mode to create symbolic links.
