#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# uninstall.sh - Remove symlinks created by install.sh
#
# Safety: Only removes symlinks that point back into this repo.
#         Regular files and foreign symlinks are never touched.
# ---------------------------------------------------------------------------

# -- Colors -----------------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RESET='\033[0m'

# -- Resolve paths ----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${HOME}/.config/opencode"

# -- State ------------------------------------------------------------------

REMOVED=0
SKIPPED=0

# -- Guard: nothing to do if config dir missing -----------------------------

if [ ! -d "$CONFIG_DIR" ]; then
    echo "Nothing to do - OpenCode config directory does not exist."
    exit 0
fi

# -- Removal helper ---------------------------------------------------------

remove_symlink() {
    local target="$1"
    local label="$2"

    # Does not exist - skip silently
    if [ ! -e "$target" ] && [ ! -L "$target" ]; then
        return 0
    fi

    # Not a symlink - never touch regular files or directories
    if [ ! -L "$target" ]; then
        printf "${YELLOW}%s${RESET} Skipped %s (not a symlink)\n" "→" "$label"
        SKIPPED=$((SKIPPED + 1))
        return 0
    fi

    # Symlink exists - check if it points into our repo
    local link_target
    link_target="$(readlink "$target")"

    case "$link_target" in
        "${SCRIPT_DIR}"*)
            rm "$target"
            printf "${GREEN}%s${RESET} Removed %s\n" "✓" "$label"
            REMOVED=$((REMOVED + 1))
            ;;
        *)
            printf "${YELLOW}%s${RESET} Skipped %s (not managed by this repo)\n" "→" "$label"
            SKIPPED=$((SKIPPED + 1))
            ;;
    esac
}

# -- Agents -----------------------------------------------------------------

echo "Agents:"
for name in servicenow.md servicenow-dev.md; do
    remove_symlink "${CONFIG_DIR}/agents/${name}" "$name"
    remove_symlink "${CONFIG_DIR}/agent/${name}" "$name"
done

# -- Skills -----------------------------------------------------------------

echo ""
echo "Skills:"
for name in servicenow-scripting servicenow-business-rules servicenow-client-scripts servicenow-gliderecord; do
    remove_symlink "${CONFIG_DIR}/skills/${name}" "$name"
    remove_symlink "${CONFIG_DIR}/skill/${name}" "$name"
done

# -- Commands ---------------------------------------------------------------

echo ""
echo "Commands:"
for name in sn-write sn-debug sn-health sn-logic-map sn-review sn-updateset; do
    remove_symlink "${CONFIG_DIR}/commands/${name}.md" "${name}.md"
    remove_symlink "${CONFIG_DIR}/command/${name}.md" "${name}.md"
done

# -- Summary ----------------------------------------------------------------

echo ""
echo "Done! ${REMOVED} items removed, ${SKIPPED} skipped."
