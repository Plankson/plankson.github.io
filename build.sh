#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

REMOTE="${REMOTE:-origin}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-gh-pages}"
REMOTE_URL="${REMOTE_URL:-git@github.com:Plankson/plankson.github.io.git}"
RUBY_BUNDLE="${RUBY_BUNDLE:-/opt/homebrew/opt/ruby/bin/bundle}"

echo "Building site..."
"$RUBY_BUNDLE" exec jekyll build

echo "Reading current $DEPLOY_BRANCH head..."
old_deploy_head="$(git ls-remote "$REMOTE" "refs/heads/$DEPLOY_BRANCH" | awk '{print $1}')"

deploy_dir="$(mktemp -d /tmp/plankson-gh-pages.XXXXXX)"
cleanup() {
  rm -rf "$deploy_dir"
}
trap cleanup EXIT

echo "Preparing deploy worktree: $deploy_dir"
rsync -a _site/ "$deploy_dir/"
touch "$deploy_dir/.nojekyll"

git -C "$deploy_dir" init
git -C "$deploy_dir" checkout -b "$DEPLOY_BRANCH"
git -C "$deploy_dir" config user.name "Plankson"
git -C "$deploy_dir" config user.email "yunpeng.qing.cs@gmail.com"
git -C "$deploy_dir" add -A
git -C "$deploy_dir" commit -m "Deploy homepage"
git -C "$deploy_dir" remote add "$REMOTE" "$REMOTE_URL"

echo "Pushing $DEPLOY_BRANCH..."
if [[ -n "$old_deploy_head" ]]; then
  git -C "$deploy_dir" push "$REMOTE" "$DEPLOY_BRANCH" --force-with-lease="$DEPLOY_BRANCH:$old_deploy_head"
else
  git -C "$deploy_dir" push "$REMOTE" "$DEPLOY_BRANCH"
fi

new_deploy_head="$(git ls-remote "$REMOTE" "refs/heads/$DEPLOY_BRANCH" | awk '{print $1}')"
echo "Done."
echo "Deployed $DEPLOY_BRANCH: $new_deploy_head"
echo "Preview: https://plankson.github.io/?v=${new_deploy_head:0:7}"
