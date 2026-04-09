# Blueprint — build.sh & build-container.sh

`build.sh` is a self-contained build, serve, and deploy script for the Hugo site. It manages its own Hugo binary download and targets the `gh-pages` branch for deployment via git worktree.

`build-container.sh` builds and runs the site inside a container (Podman or Docker). It auto-detects `Containerfile` or `Dockerfile`, builds the image, and runs it — forwarding runtime and application options through `--` separators.

---

## Options

| Flag | Short | Default | Description |
|---|---|---|---|
| `--hugo-version VERSION` | `-H` | `latest` | Hugo version to download |
| `--extended` | `-e` | off | Use the extended Hugo edition (SCSS support) |
| `--update` | `-u` | off | Re-download Hugo even if binary exists |
| `--clean` | `-c` | off | Remove all non-hidden files/dirs from `public/` before build (`.git` and `.nojekyll` are preserved) |
| `--remove-worktree` | | off | Unmount `public/` worktree after build |
| `--push` | | off | Push current branch + `gh-pages` to origin |
| `--serve` | | off | Run `hugo server` instead of building |
| `--version` | `-v` | | Print script version and exit |
| `--help` | `-h` | | Print full help and exit |

Everything after `--` is forwarded verbatim to Hugo.  
`--serve` and `--push` are mutually exclusive.

---

## Hugo Binary Management

- Binary stored as `./hugo` in the project root (gitignored).
- Edition and version metadata stored in `./.hugo_info` (gitignored).
- Version is resolved from the GitHub Releases API when `latest` is requested.
- Re-download is triggered automatically on version or edition mismatch, or when `-u` is passed.
- Supported platforms: `linux/amd64`, `linux/arm64`, `darwin/amd64`, `darwin/arm64`.

---

## Build Flow

1. Ensure Hugo binary exists (download if needed).
2. Auto-init any uninitialised git submodules.
3. Mount `public/` as a git worktree on `gh-pages` (see Worktree section).
4. Create `public/.nojekyll` if absent.
5. Run `hugo [extra args]` (if `--clean` was used, non-hidden files/dirs were already removed from `public/` before this step).
6. If `--push`: `git add -A && git commit -m "deploy: build from <branch>@<sha>"` inside `public/`, then push both branches to origin.
7. Tear down worktree if `--remove-worktree` is set (default: keep mounted).

---

## Serve Flow

1. Ensure Hugo binary exists (download if needed).
2. Auto-init any uninitialised git submodules.
3. Run `hugo server --buildDrafts [extra args]`.

Drafts are always enabled in serve mode. Pass additional Hugo flags after `--`.

---

## Worktree Management

`public/` is mounted as a git worktree pointing at `gh-pages` rather than being a plain directory. This allows Hugo to write directly into the branch without switching the main working tree.

- **First run:** script creates the `gh-pages` branch as an orphan if it does not exist.
  - Primary (`git worktree add --orphan`, git ≥ 2.25): unborn branch with no commits — `public/` starts empty; the first deploy creates the first commit.
  - Fallback: uses git plumbing (`git hash-object -t tree /dev/null` → `git commit-tree`) to create an initial commit from the canonical empty-tree object, guaranteed to contain no files from the source branch.
- **Subsequent runs:** existing worktree is reused; a stale plain directory (no `.git` file) is removed and replaced.
- **Default:** worktree stays mounted after build for incremental rebuilds.
- **`--remove-worktree`:** runs `git worktree remove public --force` after committing.

---

## Typical Usage

```bash
# Local development (drafts visible)
./build.sh --serve

# Serve with extra Hugo flags
./build.sh --serve -- --port 1314 --navigateToChanged

# Build (worktree stays mounted)
./build.sh

# Build, clean stale output, remove worktree
./build.sh -c --remove-worktree

# Build and publish
./build.sh --push

# Pin a specific extended version
./build.sh -H 0.141.0 -e --push
```

---

# build-container.sh

Builds and runs the site inside a container using Podman (default) or Docker. Auto-detects `Containerfile` (preferred) or `Dockerfile`.

---

## Options

| Flag | Default | Description |
|---|---|---|
| `--runtime RUNTIME` | podman | Container runtime to use (`podman` or `docker`) |
| `--name NAME` | current directory name | Image name override |
| `--file FILE` | auto-detect | Path to Containerfile/Dockerfile |
| `--force` | off | Rebuild the image even if it already exists |
| `--no-cache` | off | Build with `--no-cache` flag |
| `--verbose` | off | Enable verbose output |
| `--version` | | Print script version and exit |
| `-h, --help` | | Print usage and exit |

Options before `--` that are not script flags are forwarded to the container runtime's `run` command (placed before the image name). Options after `--` are forwarded as arguments to the container entrypoint (placed after the image name).

---

## Build & Run Flow

1. Detect container runtime (podman preferred, docker as fallback) unless `--runtime` is specified.
2. Locate the Containerfile/Dockerfile: `--file` if given, otherwise auto-detect (`Containerfile` preferred over `Dockerfile`) in the script's directory.
3. Resolve image name: `--name` if given, otherwise the **current working directory name**.
4. Build the image (skipped if it already exists, unless `--force` is set). Passes `--no-cache` to the runtime if requested.
5. Run the container, forwarding any pre-`--` options to the runtime and post-`--` arguments to the entrypoint.

---

## Typical Usage

```bash
# Build and run with defaults
./build-container.sh

# Force rebuild
./build-container.sh --force

# Build without cache
./build-container.sh --no-cache

# Pass port mapping to the runtime
./build-container.sh -- -p 8080:8080

# Port mapping + application arguments
./build-container.sh -p 8080:8080 -- serve

# Use docker instead of podman
./build-container.sh --runtime docker

# Verbose output
./build-container.sh --verbose

# Specify a custom Containerfile
./build-container.sh --file ./Dockerfile

# Override the image name
./build-container.sh --name myapp
```
