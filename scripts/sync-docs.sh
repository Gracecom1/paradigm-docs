#!/usr/bin/env bash
# sync-docs.sh — 外部プロジェクトの docs/*.md を収集（既存 MDX は上書きしない）
set -euo pipefail

REPOS=(
  "outbound-form-agent|https://github.com/Gracecom1/outbound-form-agent.git|docs"
)

TMPDIR=$(mktemp -d)
trap 'rm -rf $TMPDIR' EXIT

# Clone latest paradigm-docs
rm -rf /tmp/paradigm-docs
git clone --depth 1 https://github.com/Gracecom1/paradigm-docs.git /tmp/paradigm-docs

CHANGED=0
DOCS_DIR=/tmp/paradigm-docs/content/docs

for spec in "${REPOS[@]}"; do
  IFS='|' read -r name url docdir <<< "$spec"
  echo ">>> $name"

  git clone --depth 1 "$url" "$TMPDIR/$name" 2>/dev/null || { echo "  SKIP: clone failed"; continue; }

  if [ ! -d "$TMPDIR/$name/$docdir" ]; then
    echo "  SKIP: no $docdir/ directory"
    continue
  fi

  TARGET="$DOCS_DIR/$name"
  mkdir -p "$TARGET"

  for md in "$TMPDIR/$name/$docdir"/*.md; do
    [ -f "$md" ] || continue
    base=$(basename "$md" .md)
    [ "$base" = "README" ] && dest="$TARGET/index.mdx" || dest="$TARGET/$base.mdx"

    # 既存 MDX があれば上書きしない
    if [ -f "$dest" ]; then
      echo "  SKIP: $dest already exists"
      continue
    fi

    # frontmatter を自動生成
    title=$(head -1 "$md" | sed 's/^# //')
    [ -z "$title" ] && title="$base"
    {
      echo "---"
      echo "title: $title"
      echo "description: $name のドキュメント"
      echo "---"
      echo ""
      cat "$md" | sed 's/^# .*//'
    } > "$dest"
    echo "  + $base.mdx"
    CHANGED=1
  done
done

[ "$CHANGED" -eq 0 ] && { echo "No new docs."; exit 0; }

# ビルド & デプロイ
cd /tmp/paradigm-docs
docker build -t paradigm-docs:latest . 2>&1 | tail -3
docker stop paradigm-docs 2>/dev/null || true
docker rm paradigm-docs 2>/dev/null || true
docker run -d --name paradigm-docs --network coolify --restart always paradigm-docs:latest
echo "✅ Deployed — https://docs.paradigmjp.com"
