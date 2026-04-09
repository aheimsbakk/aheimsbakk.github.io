#!/usr/bin/env bash
# build-container.sh — Build and run a container from Containerfile or Dockerfile.
# Defaults to podman. Options before -- are passed to the container runtime.
# Options after -- are passed as arguments to the container entrypoint.
set -euo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Defaults ───────────────────────────────────────────────────────────────
RUNTIME=""
IMAGE_NAME=""
FORCE=false
NOCACHE=false
VERBOSE=false
CONTAINERFILE=""
CONTAINER_OPTS=()
APP_OPTS=()

# ── Helpers ────────────────────────────────────────────────────────────────
die() {
	printf "ERROR: %s\n" "$*" >&2
	exit 1
}
info() { printf "==> %s\n" "$*"; }
vinfo() { [[ "$VERBOSE" == true ]] && info "$*" || true; }

usage() {
	cat <<EOF
Usage: $(basename "$0") [SCRIPT_OPTIONS] [-- CONTAINER_OPTIONS] [-- APP_OPTIONS]

Build and run a container from Containerfile or Dockerfile.
Defaults to podman if available, otherwise docker.

Script options:
      --runtime RUNTIME   Container runtime: podman (default) or docker
      --name NAME         Image name (default: current directory name)
      --file FILE         Path to Containerfile/Dockerfile (default: auto-detect)
      --force             Rebuild the image even if it already exists
      --no-cache          Build with --no-cache flag
  --verbose           Enable verbose output
      --version           Print script version and exit
  -h, --help              Show this help and exit

Container options:
  Any options before -- that are not script flags are forwarded to
  'podman run' or 'docker run'.

Application options:
  Any options after -- are forwarded as arguments to the container
  entrypoint.

Examples:
  $(basename "$0")                              # Build and run with defaults
  $(basename "$0") --force                      # Force rebuild
  $(basename "$0") --no-cache                   # Build without cache
  $(basename "$0") -- -p 8080:8080              # Pass port mapping to runtime
  $(basename "$0") -p 8080:8080 -- serve        # Port mapping + app args
  $(basename "$0") --runtime docker             # Use docker instead of podman
  $(basename "$0") --file Dockerfile -e FOO=bar -- app-flag
EOF
}

# ── Runtime detection ──────────────────────────────────────────────────────
detect_runtime() {
	if [[ -n "$RUNTIME" ]]; then
		command -v "$RUNTIME" &>/dev/null ||
			die "Runtime '$RUNTIME' not found in PATH"
		return
	fi

	if command -v podman &>/dev/null; then
		RUNTIME=podman
	elif command -v docker &>/dev/null; then
		RUNTIME=docker
	else
		die "Neither podman nor docker found in PATH"
	fi
	vinfo "Detected runtime: $RUNTIME"
}

# ── Containerfile detection ───────────────────────────────────────────────
find_containerfile() {
	if [[ -n "$CONTAINERFILE" ]]; then
		[[ -f "$CONTAINERFILE" ]] ||
			die "Container file not found: $CONTAINERFILE"
		return
	fi

	if [[ -f "${SCRIPT_DIR}/Containerfile" ]]; then
		CONTAINERFILE="${SCRIPT_DIR}/Containerfile"
	elif [[ -f "${SCRIPT_DIR}/Dockerfile" ]]; then
		CONTAINERFILE="${SCRIPT_DIR}/Dockerfile"
	else
		die "No Containerfile or Dockerfile found in ${SCRIPT_DIR}"
	fi
	vinfo "Using container file: $CONTAINERFILE"
}

# ── Image name resolution ─────────────────────────────────────────────────
normalize_name() {
	local raw="$1"
	# Lowercase, replace any char not in [a-z0-9-] with -, collapse runs, strip edges
	local name
	name="${raw,,}"                                          # to lowercase
	name="${name//[^a-z0-9-]/-}"                             # non-alphanum/dash → -
	name="$(sed 's/-\{2,\}/-/g; s/^-//; s/-$//' <<<"$name")" # collapse, trim
	printf '%s' "$name"
}

resolve_image_name() {
	local raw
	if [[ -n "$IMAGE_NAME" ]]; then
		raw="$IMAGE_NAME"
	else
		raw="$(basename "$(pwd)")"
	fi
	normalize_name "$raw"
}

# ── Build ─────────────────────────────────────────────────────────────────
do_build() {
	local image_name
	image_name="$(resolve_image_name)"

	# Skip build if image already exists and --force is not set
	if [[ "$FORCE" == false ]]; then
		if "$RUNTIME" image inspect "$image_name" &>/dev/null; then
			info "Image '$image_name' already exists (use --force to rebuild)"
			return
		fi
	fi

	local containerfile_dir
	containerfile_dir="$(cd "$(dirname "$CONTAINERFILE")" && pwd)"

	local build_args=("-t" "$image_name" "-f" "$CONTAINERFILE")
	[[ "$NOCACHE" == true ]] && build_args+=("--no-cache")
	build_args+=("$containerfile_dir")

	info "Building image '$image_name'..."
	vinfo "$RUNTIME build ${build_args[*]}"
	"$RUNTIME" build "${build_args[@]}"
}

# ── Run ────────────────────────────────────────────────────────────────────
do_run() {
	local image_name
	image_name="$(resolve_image_name)"

	local run_args=("${CONTAINER_OPTS[@]+"${CONTAINER_OPTS[@]}"}")
	run_args+=("$image_name")
	[[ ${#APP_OPTS[@]} -gt 0 ]] && run_args+=("${APP_OPTS[@]}")

	info "Running container from '$image_name'..."
	vinfo "$RUNTIME run ${run_args[*]}"
	"$RUNTIME" run "${run_args[@]}"
}

# ── Argument parsing ──────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
	case "$1" in
	--runtime)
		RUNTIME="${2:?--runtime requires a value}"
		shift 2
		;;
	--name)
		IMAGE_NAME="${2:?--name requires a value}"
		shift 2
		;;
	--file)
		CONTAINERFILE="${2:?--file requires a value}"
		shift 2
		;;
	--force)
		FORCE=true
		shift
		;;
	--no-cache)
		NOCACHE=true
		shift
		;;
	--verbose)
		VERBOSE=true
		shift
		;;
	--version)
		printf "build-container.sh %s\n" "$SCRIPT_VERSION"
		exit 0
		;;
	-h | --help)
		usage
		exit 0
		;;
	--)
		shift
		APP_OPTS=("$@")
		break
		;;
	*)
		CONTAINER_OPTS+=("$1")
		shift
		;;
	esac
done

# ── Main ───────────────────────────────────────────────────────────────────
detect_runtime
find_containerfile
do_build
do_run
