#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# uninstall.sh - Remove ServiceNow config items from OpenCode config dir
#
# Removes the known files and directories installed by install.sh.
# Use --yes to skip the confirmation prompt.
# ---------------------------------------------------------------------------

# -- Colors -----------------------------------------------------------------

GREEN='\033[0;32m'
DIM='\033[0;90m'
RESET='\033[0m'

# -- Resolve paths ----------------------------------------------------------

CONFIG_DIR="${HOME}/.config/opencode"

# -- Parse flags ------------------------------------------------------------

AUTO_YES=false
for arg in "$@"; do
    case "$arg" in
        --yes) AUTO_YES=true ;;
    esac
done

# -- State ------------------------------------------------------------------

REMOVED=0

# -- Guard: nothing to do if config dir missing -----------------------------

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Nothing to do - OpenCode config directory does not exist."
    exit 0
fi

# -- Confirmation prompt ----------------------------------------------------

if [ "$AUTO_YES" = false ]; then
    printf "This will remove 12 ServiceNow config items from ~/.config/opencode/. Continue? [y/N] "
    read -r answer
    case "$answer" in
        [yY]|[yY][eE][sS]) ;;
        *)
            echo "Aborted."
            exit 0
            ;;
    esac
fi

# -- Removal helpers --------------------------------------------------------

remove_file() {
    local target="$1"
    local label="$2"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return 0
    fi

    rm "$target"
    printf "${GREEN}%s${RESET} Removed %s\n" "✓" "$label"
    REMOVED=$((REMOVED + 1))
}

remove_dir() {
    local target="$1"
    local label="$2"

    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return 0
    fi

    rm -rf "$target"
    printf "${GREEN}%s${RESET} Removed %s\n" "✓" "$label"
    REMOVED=$((REMOVED + 1))
}

# -- Agents -----------------------------------------------------------------

echo "Agents:"
for name in servicenow.md servicenow-dev.md; do
    remove_file "${CONFIG_DIR}/agents/${name}" "$name"
    remove_file "${CONFIG_DIR}/agent/${name}" "$name"
done

# -- Skills -----------------------------------------------------------------

echo ""
echo "Skills:"
for name in servicenow-scripting servicenow-business-rules servicenow-client-scripts servicenow-gliderecord; do
    remove_dir "${CONFIG_DIR}/skills/${name}" "$name"
    remove_dir "${CONFIG_DIR}/skill/${name}" "$name"
done

# -- Commands ---------------------------------------------------------------

echo ""
echo "Commands:"
for name in sn-write sn-debug sn-health sn-logic-map sn-review sn-updateset; do
    remove_file "${CONFIG_DIR}/commands/${name}.md" "${name}.md"
    remove_file "${CONFIG_DIR}/command/${name}.md" "${name}.md"
done

# -- Summary ----------------------------------------------------------------

echo ""
echo "Done! ${REMOVED} items removed."
