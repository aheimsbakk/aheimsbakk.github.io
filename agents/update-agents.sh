#!/usr/bin/env bash
# update-agents.sh - Download/update agentic template files from GitHub
#
# Downloads AGENTS.md, opencode.json, and all files under agents/ from
# https://github.com/aheimsbakk/agentic-template into the current directory
# or a specified target directory.

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────

readonly REPO="aheimsbakk/agentic-template"
readonly GITHUB_RAW="https://raw.githubusercontent.com/${REPO}"
readonly GITHUB_API="https://api.github.com/repos/${REPO}"
readonly VERSION="1.1.0"
readonly SCRIPT_NAME="$(basename "$0")"

# ─── Helpers ──────────────────────────────────────────────────────────────────

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [BRANCH/TAG]

Download and update agentic template files from GitHub into the current
directory or a specified target directory.

Files downloaded:
  AGENTS.md
  opencode.json
  agents/  (all files, recursively)

Arguments:
  BRANCH/TAG    Branch or tag to download from (default: main)

Options:
  -d DIR        Target directory (default: current directory)
  -h, --help    Show this help message and exit
  -v, --version Show version and exit

Examples:
  ${SCRIPT_NAME}                     # Download from main into current dir
  ${SCRIPT_NAME} develop             # Download from the 'develop' branch
  ${SCRIPT_NAME} v1.2.0             # Download from the 'v1.2.0' tag
  ${SCRIPT_NAME} -d ~/myproject      # Download into ~/myproject
  ${SCRIPT_NAME} -d ~/myproject main # Download from main into ~/myproject
EOF
}

version() {
    echo "${SCRIPT_NAME} ${VERSION}"
}

die() {
    echo "error: $*" >&2
    exit 1
}

# Check that required tools are available
check_deps() {
    local missing=()
    for cmd in curl python3; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        die "missing required tools: ${missing[*]}"
    fi
}

# ─── Core logic ───────────────────────────────────────────────────────────────

# Fetch file list for agents/ from the GitHub API tree for the given ref
get_agent_files() {
    local ref="$1"
    local url="${GITHUB_API}/git/trees/${ref}?recursive=1"
    local response

    response=$(curl -fsSL "$url" 2>/dev/null) || \
        die "failed to fetch file list from GitHub (branch/tag '${ref}' may not exist)"

    # Extract blob paths that start with agents/
    python3 -c "
import sys, json
data = json.loads('''${response}''')
for item in data.get('tree', []):
    if item['type'] == 'blob' and item['path'].startswith('agents/'):
        print(item['path'])
"
}

# Download a single file from the raw GitHub URL, replacing only if different
download_file() {
    local ref="$1"
    local remote_path="$2"
    local target_dir="$3"
    local dest="${target_dir}/${remote_path}"
    local dest_parent
    dest_parent="$(dirname "$dest")"
    local url="${GITHUB_RAW}/${ref}/${remote_path}"
    local tmp

    tmp=$(mktemp) || die "failed to create temp file"
    # shellcheck disable=SC2064
    trap "rm -f '${tmp}'" RETURN

    if ! curl -fsSL -o "$tmp" "$url" 2>/dev/null; then
        echo "  FAIL   ${remote_path}"
        rm -f "$tmp"
        return 1
    fi

    if [[ ! -d "$dest_parent" ]]; then
        mkdir -p "$dest_parent"
    fi

    if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
        echo "  OK     ${remote_path}"
    else
        cp "$tmp" "$dest"
        echo "  UPDATED ${remote_path}"
    fi
}

# ─── Argument parsing ─────────────────────────────────────────────────────────

TARGET_DIR="."
REF="main"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            version
            exit 0
            ;;
        -d)
            [[ $# -gt 1 ]] || die "option -d requires an argument"
            TARGET_DIR="$2"
            shift 2
            ;;
        -d*)
            TARGET_DIR="${1#-d}"
            shift
            ;;
        -*)
            die "unknown option: $1 (try --help)"
            ;;
        *)
            REF="$1"
            shift
            ;;
    esac
done

# ─── Main ─────────────────────────────────────────────────────────────────────

check_deps

# Resolve target directory to an absolute path
TARGET_DIR="$(realpath -m "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
    die "target directory does not exist: ${TARGET_DIR}"
fi

echo "Repository : ${REPO}"
echo "Branch/tag : ${REF}"
echo "Target dir : ${TARGET_DIR}"
echo ""

# Static top-level files
STATIC_FILES=(
    "AGENTS.md"
    "opencode.json"
)

# Dynamic: discover all files under agents/
mapfile -t AGENT_FILES < <(get_agent_files "$REF")

ALL_FILES=("${STATIC_FILES[@]}" "${AGENT_FILES[@]}")

fail_count=0
for file in "${ALL_FILES[@]}"; do
    download_file "$REF" "$file" "$TARGET_DIR" || (( fail_count++ )) || true
done

# Remove local files that no longer exist in the remote
# Build a lookup set of all remote paths
declare -A remote_set
for file in "${ALL_FILES[@]}"; do
    remote_set["$file"]=1
done

# Walk managed locations: top-level static files + the agents/ subtree
while IFS= read -r -d '' local_file; do
    rel="${local_file#"${TARGET_DIR}/"}"
    if [[ -z "${remote_set[$rel]+_}" ]]; then
        rm -f "$local_file"
        echo "  DELETED ${rel}"
        # Remove empty parent directories inside agents/
        rmdir --ignore-fail-on-non-empty -p "$(dirname "$local_file")" 2>/dev/null || true
    fi
done < <(
    # Enumerate local candidates: static files + everything under agents/
    for f in "${STATIC_FILES[@]}"; do
        [[ -f "${TARGET_DIR}/${f}" ]] && printf '%s\0' "${TARGET_DIR}/${f}"
    done
    [[ -d "${TARGET_DIR}/agents" ]] && \
        find "${TARGET_DIR}/agents" -type f -print0
)

echo ""
if [[ $fail_count -gt 0 ]]; then
    echo "Done with ${fail_count} error(s)."
    exit 1
else
    echo "Done."
fi
