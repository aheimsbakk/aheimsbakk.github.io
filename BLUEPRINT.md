# Blueprint — build.sh

`build.sh` is a self-contained build, serve, and deploy script for the Hugo site. It manages its own Hugo binary download and targets the `gh-pages` branch for deployment via git worktree.

---

## Options

| Flag | Short | Default | Description |
|---|---|---|---|
| `--hugo-version VERSION` | `-H` | `latest` | Hugo version to download |
| `--extended` | `-e` | off | Use the extended Hugo edition (SCSS support) |
| `--update` | `-u` | off | Re-download Hugo even if binary exists |
| `--clean` | `-c` | off | Pass `--cleanDestinationDir` to Hugo |
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
5. Run `hugo [--cleanDestinationDir] [extra args]`.
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

- **First run:** script creates the `gh-pages` branch as an orphan if it does not exist, with a fallback for git < 2.25.
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
