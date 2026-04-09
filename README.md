# build.sh & build-container.sh

Two scripts that handle everything needed to develop and deploy this Hugo site — no global installs required.

**`build.sh`** downloads the right Hugo binary for your machine, wires up the `gh-pages` deployment branch, and gets out of your way.

**`build-container.sh`** builds and runs the site inside a Podman (default) or Docker container, auto-detecting `Containerfile` or `Dockerfile`.

---

## Quick start

```bash
# Local development with Hugo
./build.sh --serve

# Or run inside a container
./build-container.sh
```

---

## Common workflows

| What you want to do | Command |
|---|---|
| Local dev (drafts visible) | `./build.sh --serve` |
| Build the site | `./build.sh` |
| Build & deploy to GitHub Pages | `./build.sh --push` |
| Build clean (wipe stale output first) | `./build.sh --clean` |
| Use Hugo extended (SCSS support) | `./build.sh --extended` |
| Pin a specific Hugo version | `./build.sh -H 0.141.0` |
| Force re-download Hugo | `./build.sh --update` |

Anything after `--` is passed straight through to Hugo:

```bash
./build.sh --serve -- --port 1314 --navigateToChanged
./build.sh -H 0.141.0 --extended --push
```

---

## All options

| Flag | Short | Default | Description |
|---|---|---|---|
| `--hugo-version VERSION` | `-H` | `latest` | Hugo version to download |
| `--extended` | `-e` | off | Use the extended edition (SCSS/Sass support) |
| `--update` | `-u` | off | Force re-download the Hugo binary |
| `--clean` | `-c` | off | Wipe `public/` before building (keeps `.git`, `.nojekyll`) |
| `--remove-worktree` | | off | Unmount `public/` git worktree after build |
| `--push` | | off | Commit built output and push `gh-pages` + current branch to origin |
| `--serve` | | off | Run `hugo server --buildDrafts` instead of building |
| `--version` | `-v` | | Print script version and exit |
| `--help` | `-h` | | Print usage and exit |

> `--serve` and `--push` are mutually exclusive.

---

## How it works (the short version)

1. **Hugo binary** — downloaded to `./hugo` on first run, skipped on subsequent runs unless the version, edition, or `-u` flag changes. Stored locally; never touches your system.
2. **Submodules** — any uninitialised git submodules are initialised automatically before each build or serve.
3. **`public/` worktree** — instead of a plain folder, `public/` is a git worktree pointing at the `gh-pages` branch. Hugo writes directly into the branch. If the branch doesn't exist yet, the script creates an empty orphan branch on first run.
4. **Deploy** — `--push` commits the built output to `gh-pages` with a message like `deploy: build from main@a1b2c3d`, then pushes both branches to `origin`.

---

## build-container.sh

Builds and runs the site inside a container. Defaults to Podman, falls back to Docker.

| Flag | Default | Description |
|---|---|---|
| `--runtime RUNTIME` | podman | Container runtime (`podman` or `docker`) |
| `--name NAME` | directory name | Image name override (default: directory containing Containerfile) |
| `--file FILE` | auto-detect | Path to Containerfile/Dockerfile |
| `--force` | off | Rebuild the image even if it already exists |
| `--no-cache` | off | Build with `--no-cache` |
| `--verbose` | off | Enable verbose output |
| `--version` | | Print script version and exit |
| `-h, --help` | | Print usage and exit |

Options before `--` that are not script flags are forwarded to the container runtime's `run` command. Options after `--` are forwarded to the container entrypoint.

```bash
./build-container.sh                              # Build and run with defaults
./build-container.sh --force                      # Force rebuild
./build-container.sh --no-cache                   # Build without cache
./build-container.sh -- -p 8080:8080              # Pass port mapping to runtime
./build-container.sh -- -p 8080:8080 -- serve     # Port mapping + app args
./build-container.sh --runtime docker             # Use docker instead of podman
```

---

## Requirements

- **Bash** 4+ and standard Unix tools (`curl`, `tar`, `git`).
- Git **2.25+** recommended (older versions fall back gracefully for orphan worktrees).
- Network access on first run to fetch the Hugo release from GitHub.
- **Podman** or **Docker** for container builds (optional).

---

That's it. Run `./build.sh --help` any time to see the full usage summary in your terminal.
