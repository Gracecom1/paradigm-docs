#!/usr/bin/env bash
# sync-docs.sh — 全プロジェクトの docs/*.md を収集し Fumadocs に反映
# 使い方: ./scripts/sync-docs.sh [--deploy]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
DOCS_DIR="$PROJECT_DIR/content/docs"

# 収集対象リポジトリ: 名前 URL ドキュメントディレクトリ
REPOS=(
  "outbound-form-agent|https://github.com/Gracecom1/outbound-form-agent.git|docs"
  # 新規プロジェクト追加時はここに追記
)

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

CHANGED=0

for repo_spec in "${REPOS[@]}"; do
  IFS='|' read -r name url docdir <<< "$repo_spec"
  echo ">>> $name"

  git clone --depth 1 "$url" "$TMPDIR/$name" 2>/dev/null || { echo "  SKIP: clone failed"; continue; }

  if [ -d "$TMPDIR/$name/$docdir" ]; then
    TARGET="$DOCS_DIR/$name"
    mkdir -p "$TARGET"

    for md in "$TMPDIR/$name/$docdir"/*.md; do
      [ -f "$md" ] || continue
      base=$(basename "$md" .md)

      # README.md → index.mdx
      if [ "$base" = "README" ]; then
        dest="$TARGET/index.mdx"
      else
        dest="$TARGET/$base.mdx"
      fi

      # MD → MDX: コードブロックの言語タグを修正（env → bash 等）
      cat "$md" | sed 's/```env/```bash/g' > "$dest"
      echo "  ✓ $base.md → $dest"
    done
    CHANGED=1
  else
    echo "  SKIP: no $docdir/ directory"
  fi
done

if [ "$CHANGED" -eq 0 ]; then
  echo "No changes detected."
  exit 0
fi

# ナビゲーション meta.json を再生成
python3 - "$DOCS_DIR" "$TMPDIR" << 'PYEOF'
import json, os, sys

docs_dir = sys.argv[1]
meta = {"pages": ["index"]}
items = {}

for entry in sorted(os.listdir(docs_dir)):
    sub = os.path.join(docs_dir, entry)
    if os.path.isdir(sub) and not entry.startswith('.') and not entry.startswith('_'):
        pages = []
        for f in sorted(os.listdir(sub)):
            if f.endswith('.mdx'):
                pages.append(f[:-4])
        if pages:
            # タイトルは index.mdx の frontmatter から取得できれば尚良
            title = entry.replace('-', ' ').title()
            items[entry] = {"title": title, "pages": pages}

# 固定エントリを追加
if "twenty-crm" not in items:
    items["twenty-crm"] = {"title": "Twenty CRM", "pages": ["twenty-crm"]}
if "cli-tools" not in items:
    items["cli-tools"] = {"title": "CLI ツール群", "pages": ["cli-tools"]}

meta["items"] = items
with open(os.path.join(docs_dir, "meta.json"), "w") as f:
    json.dump(meta, f, ensure_ascii=False, indent=2)
print("meta.json regenerated")
PYEOF

echo "Sync complete."

if [ "${1:-}" = "--deploy" ]; then
  echo ">>> Rebuilding Docker image..."
  cd "$PROJECT_DIR"
  docker build -t paradigm-docs:latest .
  docker stop paradigm-docs 2>/dev/null || true
  docker rm paradigm-docs 2>/dev/null || true
  docker run -d --name paradigm-docs --network coolify --restart always paradigm-docs:latest
  echo "Deploy complete."
fi
