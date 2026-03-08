#!/usr/bin/env bash
# Test suite for build.sh — verifies worktree init and deploy cleanliness.
# Usage: bash scripts/test-build.sh
set -euo pipefail

PASS=0
FAIL=0

pass() { printf "  \033[32mPASS\033[0m %s\n" "$1"; ((PASS++)) || true; }
fail() { printf "  \033[31mFAIL\033[0m %s\n" "$1"; ((FAIL++)) || true; }

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build.sh"

# ── Fake Hugo ──────────────────────────────────────────────────────────────
# Writes minimal HTML output into ./public/ (mirroring real Hugo defaults).
# Content includes $RANDOM so successive deploys always produce a new diff.
make_fake_hugo() {
  cat > "$1" << 'HUGO'
#!/usr/bin/env bash
mkdir -p public/posts/hello public/css
printf '<html>Build %s</html>\n' "$RANDOM$RANDOM" > public/index.html
printf '<html>Post</html>\n'                       > public/posts/hello/index.html
printf 'body{}\n'                                  > public/css/style.css
HUGO
  chmod +x "$1"
}

# ── Repo factory ───────────────────────────────────────────────────────────
# Creates a bare "origin" + a working repo seeded with Hugo source files.
make_repo() {
  local name="$1"
  local bare="${TMPROOT}/${name}-origin"
  local work="${TMPROOT}/${name}"

  git init -q --bare "$bare"

  mkdir -p "$work"
  cd "$work"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  git remote add origin "$bare"

  # Minimal Hugo project (source files that must NOT appear in gh-pages)
  echo "title = 'Test'" > hugo.toml
  mkdir -p content/posts archetypes
  echo "# Hello"  > content/posts/hello.md
  echo "default" > archetypes/default.md

  git add .
  git commit -q -m "chore: initial source files"
  git branch -M main 2>/dev/null || true
  git push -q -u origin main

  cp "$SCRIPT" ./build.sh
  make_fake_hugo ./hugo
}

# ── Helpers ────────────────────────────────────────────────────────────────
branch_files() { git ls-tree -r --name-only "$1" 2>/dev/null || true; }

no_source_leak() {
  local leaked
  leaked=$(printf '%s\n' "$1" | grep -E "^(hugo\.toml|content/|archetypes/)" || true)
  [[ -z "$leaked" ]]
}

# ══════════════════════════════════════════════════════════════════════════
echo "── Test 1: fresh init — git worktree add --orphan (primary path) ────"
make_repo t1
cd "${TMPROOT}/t1"
bash build.sh --push

FILES=$(branch_files gh-pages)
no_source_leak "$FILES" \
  && pass "no source files on gh-pages" \
  || fail "source files leaked onto gh-pages"
printf '%s\n' "$FILES" | grep -q "^index\.html$" \
  && pass "Hugo output (index.html) present" \
  || fail "Hugo output missing"
printf '%s\n' "$FILES" | grep -q "^\.nojekyll$" \
  && pass ".nojekyll present" \
  || fail ".nojekyll missing"

# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Test 2: fresh init — git commit-tree fallback ────────────────────"
make_repo t2
cd "${TMPROOT}/t2"
# Force the primary --orphan path to fail so the commit-tree fallback runs
sed 's|git worktree add --orphan -b gh-pages public 2>/dev/null|false|' \
  build.sh > build_fallback.sh
chmod +x build_fallback.sh
bash build_fallback.sh --push

FILES=$(branch_files gh-pages)
no_source_leak "$FILES" \
  && pass "no source files on gh-pages (fallback path)" \
  || fail "source files leaked onto gh-pages (fallback path)"
printf '%s\n' "$FILES" | grep -q "^index\.html$" \
  && pass "Hugo output present (fallback path)" \
  || fail "Hugo output missing (fallback path)"

# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Test 3: origin/gh-pages pre-polluted with source files ───────────"
make_repo t3
cd "${TMPROOT}/t3"
# Push a commit whose tree is identical to main (all source files) to gh-pages,
# simulating the historical "initial commit" bug.
main_tree=$(git rev-parse HEAD^{tree})
polluted=$(git commit-tree "$main_tree" -m "polluted: source files in gh-pages")
git push -q origin "${polluted}:refs/heads/gh-pages"

bash build.sh --push

FILES=$(branch_files gh-pages)
no_source_leak "$FILES" \
  && pass "pre-deploy wipe removed all source files" \
  || fail "source files still present after deploy"
printf '%s\n' "$FILES" | grep -q "^index\.html$" \
  && pass "Hugo output present after cleaning" \
  || fail "Hugo output missing after cleaning"

# ══════════════════════════════════════════════════════════════════════════
echo ""
echo "── Test 4: second deploy stays clean ────────────────────────────────"
make_repo t4
cd "${TMPROOT}/t4"
bash build.sh --push

# Add a new source file and redeploy
echo "# Post 2" > content/posts/hello2.md
git add content/posts/hello2.md
git commit -q -m "feat: add second post"
git push -q origin main

bash build.sh --push

FILES=$(branch_files gh-pages)
no_source_leak "$FILES" \
  && pass "second deploy: no source files leaked" \
  || fail "second deploy: source files leaked"

NCOMMITS=$(git log --oneline gh-pages | wc -l | tr -d '[:space:]')
[[ "$NCOMMITS" -eq 2 ]] \
  && pass "gh-pages has exactly 2 deploy commits" \
  || fail "gh-pages commit count: expected 2, got ${NCOMMITS}"

# ══════════════════════════════════════════════════════════════════════════
echo ""
printf "Results: \033[32m%d passed\033[0m, " "$PASS"
[[ "$FAIL" -gt 0 ]] \
  && printf "\033[31m%d failed\033[0m\n" "$FAIL" \
  || printf "\033[32m%d failed\033[0m\n" "$FAIL"
echo ""
[[ "$FAIL" -eq 0 ]]
