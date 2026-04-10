#!/bin/bash
set -euo pipefail

VERSION="1.1.1"
SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTAINERFILE=""
REPO_URL="https://github.com/aheimsbakk/run-container.sh.git"
RAW_URL="https://raw.githubusercontent.com/aheimsbakk/run-container.sh/main/run-container.sh"

FORCE=false
NO_CACHE=false
FORCE_DOCKER=false
NAME_OVERRIDE=""
PODMAN_OPTS=()
CMD_OPTS=()

LICENSE_TEXT="MIT License

Copyright (c) 2026 Arnulf Heimsbakk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the \"Software\"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE."

# Determine container runtime: prefer podman, fall back to docker
resolve_runtime() {
	if ${FORCE_DOCKER}; then
		if ! command -v docker &>/dev/null; then
			echo "Error: --docker requested but docker is not installed" >&2
			exit 1
		fi
		echo "docker"
	elif command -v podman &>/dev/null; then
		echo "podman"
	elif command -v docker &>/dev/null; then
		echo "docker"
	else
		echo "Error: neither podman nor docker is installed" >&2
		exit 1
	fi
}

show_license() {
	echo "${LICENSE_TEXT}"
}

self_update() {
	local tmp_file
	tmp_file="$(mktemp)"

	echo "Checking for updates from ${RAW_URL}..."

	# Download the latest version of the script
	if command -v curl &>/dev/null; then
		if ! curl --fail --silent --show-error --location --max-time 30 -o "${tmp_file}" "${RAW_URL}"; then
			echo "Error: failed to download update from ${RAW_URL}" >&2
			rm -f "${tmp_file}"
			exit 1
		fi
	elif command -v wget &>/dev/null; then
		if ! wget --quiet --timeout=30 -O "${tmp_file}" "${RAW_URL}"; then
			echo "Error: failed to download update from ${RAW_URL}" >&2
			rm -f "${tmp_file}"
			exit 1
		fi
	else
		echo "Error: neither curl nor wget is available; cannot self-update" >&2
		rm -f "${tmp_file}"
		exit 1
	fi

	# Validate the downloaded file is a bash script and is non-empty
	if [[ ! -s "${tmp_file}" ]]; then
		echo "Error: downloaded file is empty" >&2
		rm -f "${tmp_file}"
		exit 1
	fi

	local first_line
	first_line="$(head -n1 "${tmp_file}")"
	if [[ "${first_line}" != "#!/bin/bash"* ]]; then
		echo "Error: downloaded file does not appear to be a valid bash script" >&2
		rm -f "${tmp_file}"
		exit 1
	fi

	# Replace the current script
	if chmod +x "${tmp_file}" && mv "${tmp_file}" "${SCRIPT_PATH}"; then
		echo "Successfully updated ${SCRIPT_NAME}. Please re-run the script to use the new version."
		exit 0
	else
		echo "Error: failed to replace ${SCRIPT_PATH} with the update" >&2
		rm -f "${tmp_file}"
		exit 1
	fi
}

usage() {
	cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [PODMAN_RUN_OPTIONS] [-- COMMAND_OPTIONS]

Builds a container image from Containerfile (or Dockerfile as fallback) using
podman (or docker as fallback). If the image already exists, runs the container
instead. Use -f/--force to rebuild an existing image.

Script Options:
  -f, --force       Force rebuild of the container image even if it exists
      --no-cache    Build without using cache (implies --force)
      --docker      Force use of docker even if podman is available
  -n, --name NAME   Override the container image name (default: directory name)
      --update      Self-update the script from the repository and exit
      --license     Show license information and exit
  -h, --help        Show this help message and exit
  -V, --version     Show version information and exit

Source repository: ${REPO_URL}

Argument Separation:
  PODMAN_RUN_OPTIONS   Any options before '--' are passed to the container runtime
  COMMAND_OPTIONS      Any options after '--' are passed to the container command

  Example:
    ${SCRIPT_NAME} -n sphinx --rm -ti -v ./:/mnt -- sphinx-build -b html source public

Container name is derived from the directory containing the build file.

Version: ${VERSION}
EOF
}

# Parse script options; unknown args are collected as podman run options
while [[ $# -gt 0 ]]; do
	case "$1" in
	-f | --force)
		FORCE=true
		shift
		;;
	--no-cache)
		NO_CACHE=true
		FORCE=true # no-cache only makes sense when building
		shift
		;;
	--docker)
		FORCE_DOCKER=true
		shift
		;;
	-n | --name)
		NAME_OVERRIDE="$2"
		shift 2
		;;
	--license)
		show_license
		exit 0
		;;
	--update)
		self_update
		;;
	-h | --help)
		usage
		exit 0
		;;
	-V | --version)
		echo "${SCRIPT_NAME} ${VERSION}"
		exit 0
		;;
	--)
		shift
		CMD_OPTS=("$@")
		break
		;;
	*)
		PODMAN_OPTS+=("$1")
		shift
		;;
	esac
done

# Resolve container runtime (after argument parsing so --docker is known)
RUNTIME="$(resolve_runtime)"

# Locate Containerfile, fall back to Dockerfile
if [[ -f "${SCRIPT_DIR}/Containerfile" ]]; then
	CONTAINERFILE="${SCRIPT_DIR}/Containerfile"
elif [[ -f "${SCRIPT_DIR}/Dockerfile" ]]; then
	CONTAINERFILE="${SCRIPT_DIR}/Dockerfile"
else
	echo "Error: no Containerfile or Dockerfile found in ${SCRIPT_DIR}" >&2
	exit 1
fi

# Container name = override if given, else name of directory containing the build file
CONTAINER_NAME="${NAME_OVERRIDE:-$(basename "${SCRIPT_DIR}")}"

# Check if the image already exists ('image inspect' works with both podman and docker)
IMAGE_EXISTS=false
if ${RUNTIME} image inspect "${CONTAINER_NAME}" &>/dev/null; then
	IMAGE_EXISTS=true
fi

# Build if the image is missing or --force / --no-cache was requested
if ! ${IMAGE_EXISTS} || ${FORCE}; then
	BUILD_ARGS=()
	if ${NO_CACHE}; then
		BUILD_ARGS+=("--no-cache")
	fi

	echo "Building container image '${CONTAINER_NAME}' using ${RUNTIME}..."
	${RUNTIME} build "${BUILD_ARGS[@]}" \
		-t "${CONTAINER_NAME}" \
		-f "${CONTAINERFILE}" \
		"${SCRIPT_DIR}"
	echo "Build complete."
fi

# Run the container
echo "Running container '${CONTAINER_NAME}' using ${RUNTIME}..."
${RUNTIME} run --rm \
	"${PODMAN_OPTS[@]+"${PODMAN_OPTS[@]}"}" \
	"${CONTAINER_NAME}" \
	"${CMD_OPTS[@]+"${CMD_OPTS[@]}"}"
