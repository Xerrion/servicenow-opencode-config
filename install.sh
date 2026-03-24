#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# install.sh - Symlink ServiceNow agents, skills, and commands into OpenCode
#
# Usage: ./install.sh [--force]
#   --force  Replace existing files/symlinks instead of skipping
# ---------------------------------------------------------------------------

# -- Colors -----------------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'

# -- Resolve paths ----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${HOME}/.config/opencode"

# -- State ------------------------------------------------------------------

FORCE=false
LINKED=0
SKIPPED=0

# -- Parse flags ------------------------------------------------------------

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        *)
            printf "${RED}%s${RESET} Unknown option: %s\n" "✗" "$arg" >&2
            echo "Usage: $0 [--force]" >&2
            exit 1
            ;;
    esac
done

# -- Guard: OpenCode must be installed --------------------------------------

if [ ! -d "$CONFIG_DIR" ]; then
    printf "${RED}%s${RESET} OpenCode config directory not found. Install OpenCode first.\n" "✗" >&2
    exit 1
fi

# -- Directory name detection -----------------------------------------------
# OpenCode supports both singular (command/) and plural (commands/) directory
# names. We detect which variant exists, falling back to sensible defaults.

resolve_config_subdir() {
    local plural="$1"
    local singular="$2"
    local default="$3"

    if [ -d "${CONFIG_DIR}/${plural}" ]; then
        echo "${CONFIG_DIR}/${plural}"
    elif [ -d "${CONFIG_DIR}/${singular}" ]; then
        echo "${CONFIG_DIR}/${singular}"
    else
        mkdir -p "${CONFIG_DIR}/${default}"
        echo "${CONFIG_DIR}/${default}"
    fi
}

AGENTS_DIR="$(resolve_config_subdir "agents" "agent" "agents")"
SKILLS_DIR="$(resolve_config_subdir "skills" "skill" "skills")"
COMMANDS_DIR="$(resolve_config_subdir "commands" "command" "commands")"

# -- Symlink helper ---------------------------------------------------------

create_symlink() {
    local source="$1"
    local target="$2"
    local label="$3"

    # Source must exist - fail fast on bad repo state
    if [ ! -e "$source" ]; then
        printf "${RED}%s${RESET} Source not found: %s\n" "✗" "$source" >&2
        return 1
    fi

    # Already a symlink pointing to the correct source - nothing to do
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        printf "  Already linked %s\n" "$label"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    # Target exists (file, directory, or different symlink)
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ "$FORCE" = true ]; then
            rm -rf "$target"
            ln -s "$source" "$target"
            printf "${YELLOW}  Replaced %s${RESET}\n" "$label"
            LINKED=$((LINKED + 1))
            return 0
        else
            printf "${YELLOW}%s${RESET} Skipped %s (already exists, use --force to replace)\n" "→" "$label"
            SKIPPED=$((SKIPPED + 1))
            return 0
        fi
    fi

    # Happy path: target is free, create the symlink
    ln -s "$source" "$target"
    printf "${GREEN}%s${RESET} Linked %s\n" "✓" "$label"
    LINKED=$((LINKED + 1))
}

# -- Agents (individual .md files) ------------------------------------------

echo "Agents:"
for file in "${SCRIPT_DIR}/agents/"*.md; do
    name="$(basename "$file")"
    create_symlink "$file" "${AGENTS_DIR}/${name}" "$name"
done

# -- Skills (entire directories, not individual files) ----------------------

echo ""
echo "Skills:"
for dir in "${SCRIPT_DIR}/skills/"*/; do
    name="$(basename "$dir")"
    create_symlink "${SCRIPT_DIR}/skills/${name}" "${SKILLS_DIR}/${name}" "$name"
done

# -- Commands (individual .md files) ----------------------------------------

echo ""
echo "Commands:"
for file in "${SCRIPT_DIR}/commands/"*.md; do
    name="$(basename "$file")"
    create_symlink "$file" "${COMMANDS_DIR}/${name}" "$name"
done

# -- Summary ----------------------------------------------------------------

echo ""
echo "Done! ${LINKED} items linked, ${SKIPPED} skipped."
echo ""
echo "Next steps:"
echo "  1. Add the MCP server config to your opencode.jsonc"
echo "     See: mcp-config-template.jsonc"
echo "  2. Set your ServiceNow credentials as environment variables"
echo "     See: README.md"
