# build.sh

A single script that handles everything needed to develop and deploy this Hugo site — no global installs required. It downloads the right Hugo binary for your machine, wires up the `gh-pages` deployment branch, and gets out of your way.

---

## Quick start

```bash
# First time? Just run it — Hugo downloads itself.
./build.sh --serve
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

## Requirements

- **Bash** 4+ and standard Unix tools (`curl`, `tar`, `git`).
- Git **2.25+** recommended (older versions fall back gracefully for orphan worktrees).
- Network access on first run to fetch the Hugo release from GitHub.

---

That's it. Run `./build.sh --help` any time to see the full usage summary in your terminal.
