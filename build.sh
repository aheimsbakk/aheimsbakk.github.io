#!/usr/bin/env bash
# build.sh — Download Hugo and build/serve this site targeting the gh-pages branch.
set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HUGO_BIN="${SCRIPT_DIR}/hugo"
HUGO_INFO="${SCRIPT_DIR}/.hugo_info"

# ── Defaults ───────────────────────────────────────────────────────────────
VERSION="latest"
EXTENDED=false
UPDATE=false
CLEAN=false
PUSH=false
SERVE=false
REMOVE_WORKTREE=false
EXTRA_ARGS=()

# ── Helpers ────────────────────────────────────────────────────────────────
die()  { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [-- HUGO_ARGS...]

Options:
  -H, --hugo-version VERSION  Hugo version to download (default: latest)
  -e, --extended              Use the Hugo extended edition
  -u, --update                Re-download Hugo even if a binary already exists
  -c, --clean                 Pass --cleanDestinationDir to Hugo on build
      --remove-worktree       Remove public/ worktree after build (default: keep)
      --push                  Push current branch and gh-pages to origin
      --serve                 Run hugo server instead of building (includes --buildDrafts)
  -v, --version               Print build.sh version and exit
  -h, --help                  Show this help and exit

Everything after -- is forwarded verbatim to the Hugo command.
EOF
}

# ── Platform detection ─────────────────────────────────────────────────────
detect_platform() {
  local os arch
  case "$(uname -s)" in
    Linux)  os="linux"  ;;
    Darwin) os="darwin" ;;
    *)      die "Unsupported OS: $(uname -s)" ;;
  esac
  case "$(uname -m)" in
    x86_64)        arch="amd64" ;;
    aarch64|arm64) arch="arm64" ;;
    *)             die "Unsupported architecture: $(uname -m)" ;;
  esac
  echo "${os}-${arch}"
}

# ── Hugo download ──────────────────────────────────────────────────────────
resolve_version() {
  if [[ "$VERSION" == "latest" ]]; then
    info "Resolving latest Hugo version..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/gohugoio/hugo/releases/latest" \
      | grep '"tag_name"' | head -1 | sed 's/.*"v\([^"]*\)".*/\1/')
    [[ -n "$VERSION" ]] || die "Failed to resolve latest Hugo version from GitHub API"
    info "Latest version: v${VERSION}"
  fi
}

download_hugo() {
  local platform edition
  platform=$(detect_platform)
  edition=$([[ "$EXTENDED" == true ]] && echo "_extended" || echo "")
  resolve_version

  local filename="hugo${edition}_${VERSION}_${platform}.tar.gz"
  local url="https://github.com/gohugoio/hugo/releases/download/v${VERSION}/${filename}"
  local tmpdir
  tmpdir=$(mktemp -d)

  info "Downloading Hugo v${VERSION}${edition} (${platform})..."
  curl -fsSL --progress-bar "$url" -o "${tmpdir}/${filename}" \
    || { rm -rf "$tmpdir"; die "Download failed — check version/network: ${url}"; }

  tar -xzf "${tmpdir}/${filename}" -C "${tmpdir}" hugo \
    || { rm -rf "$tmpdir"; die "Failed to extract Hugo archive"; }

  mv "${tmpdir}/hugo" "$HUGO_BIN"
  chmod +x "$HUGO_BIN"
  rm -rf "$tmpdir"
  printf "version=%s\nextended=%s\n" "$VERSION" "$EXTENDED" > "$HUGO_INFO"
  info "Hugo v${VERSION}${edition} installed at ${HUGO_BIN}"
}

ensure_hugo() {
  local needs_download=false
  if [[ ! -x "$HUGO_BIN" ]]; then
    needs_download=true
  elif [[ "$UPDATE" == true ]]; then
    needs_download=true
  elif [[ -f "$HUGO_INFO" ]]; then
    local sv se
    sv=$(grep "^version=" "$HUGO_INFO" | cut -d= -f2)
    se=$(grep "^extended=" "$HUGO_INFO" | cut -d= -f2)
    [[ "$VERSION" != "latest" && "$sv" != "$VERSION" ]] && needs_download=true
    [[ "$se" != "$EXTENDED" ]] && needs_download=true
  fi

  if [[ "$needs_download" == true ]]; then
    download_hugo
  else
    info "Using existing $("$HUGO_BIN" version 2>&1 | head -1)"
  fi
}

# ── Submodules ─────────────────────────────────────────────────────────────
init_submodules() {
  [[ ! -f ".gitmodules" ]] && return
  local uninitialized
  uninitialized=$(git submodule status | grep -c "^-" || true)
  if [[ "$uninitialized" -gt 0 ]]; then
    info "Initializing ${uninitialized} git submodule(s)..."
    git submodule update --init --recursive
  fi
}

# ── Worktree management ────────────────────────────────────────────────────
setup_worktree() {
  local abs_public="${SCRIPT_DIR}/public"

  if git worktree list | grep -qF "$abs_public"; then
    info "public/ worktree already active"
    return
  fi

  # Remove a stale plain directory (no .git file means it is not a worktree)
  [[ -d "public" && ! -f "public/.git" ]] && rm -rf "public"

  if git rev-parse --verify gh-pages &>/dev/null; then
    git worktree add public gh-pages
  elif git rev-parse --verify "origin/gh-pages" &>/dev/null; then
    git worktree add -B gh-pages public origin/gh-pages
  else
    info "Creating orphan gh-pages branch..."
    # Primary: git worktree add --orphan (git >= 2.25).
    # The unborn branch has no tree at all; skip the initial commit —
    # the first deploy commit will be the first real commit on gh-pages.
    if git worktree add --orphan -b gh-pages public 2>/dev/null; then
      : # nothing to do; public/ is empty on the unborn branch
    else
      # Fallback: build an initial commit from the canonical empty-tree object.
      # This is guaranteed to contain no files regardless of the current branch state.
      local empty_tree init_commit
      empty_tree=$(git hash-object -t tree /dev/null)
      init_commit=$(git commit-tree "$empty_tree" -m "chore: initialize gh-pages branch")
      git branch gh-pages "$init_commit"
      git worktree add public gh-pages
    fi
  fi
  info "public/ mounted as gh-pages worktree"
}

teardown_worktree() {
  if [[ "$REMOVE_WORKTREE" == true ]]; then
    git worktree remove public --force 2>/dev/null || true
    info "public/ worktree removed"
  else
    info "public/ worktree kept (use --remove-worktree to clean up)"
  fi
}

# ── Build ──────────────────────────────────────────────────────────────────
do_build() {
  setup_worktree

  [[ -f "public/.nojekyll" ]] || { touch "public/.nojekyll"; info "Created .nojekyll"; }

  local hugo_args=()
  [[ "$CLEAN" == true ]] && hugo_args+=(--cleanDestinationDir)
  [[ ${#EXTRA_ARGS[@]} -gt 0 ]] && hugo_args+=("${EXTRA_ARGS[@]}")

  info "Building Hugo site..."
  "$HUGO_BIN" "${hugo_args[@]+"${hugo_args[@]}"}"
}

# ── Serve ──────────────────────────────────────────────────────────────────
do_serve() {
  info "Starting Hugo server (drafts enabled)..."
  "$HUGO_BIN" server --buildDrafts "${EXTRA_ARGS[@]+"${EXTRA_ARGS[@]}"}"
}

# ── Push ───────────────────────────────────────────────────────────────────
do_push() {
  local cur sha
  cur=$(git symbolic-ref --short HEAD)
  sha=$(git rev-parse --short HEAD)

  git -C public add -A
  if git -C public diff --cached --quiet; then
    info "No changes to commit on gh-pages"
  else
    git -C public commit -m "deploy: build from ${cur}@${sha}"
    info "gh-pages committed"
  fi

  info "Pushing ${cur} and gh-pages to origin..."
  git push origin "$cur"
  git push origin gh-pages
}

# ── Argument parsing ───────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    -H|--hugo-version) VERSION="${2:?--hugo-version requires a value}"; shift 2 ;;
    -e|--extended)     EXTENDED=true;        shift ;;
    -u|--update)       UPDATE=true;          shift ;;
    -c|--clean)        CLEAN=true;           shift ;;
    --remove-worktree) REMOVE_WORKTREE=true; shift ;;
    --push)            PUSH=true;            shift ;;
    --serve)           SERVE=true;           shift ;;
    -v|--version)      echo "build.sh ${SCRIPT_VERSION}"; exit 0 ;;
    -h|--help)         usage; exit 0         ;;
    --)                shift; EXTRA_ARGS=("$@"); break ;;
    *)                 die "Unknown option: $1 — use -h for help" ;;
  esac
done

[[ "$SERVE" == true && "$PUSH" == true ]] && die "--serve and --push are mutually exclusive"

# ── Main ───────────────────────────────────────────────────────────────────
cd "$SCRIPT_DIR"
ensure_hugo
init_submodules

if [[ "$SERVE" == true ]]; then
  do_serve
else
  do_build
  [[ "$PUSH" == true ]] && do_push
  teardown_worktree
fi
