#!/usr/bin/env bash
set -euo pipefail

SRC="${1:-logo.svg}"
OUT_DIR="./static"
PNG_SIZE=180

[[ -f "$SRC" ]] || { echo "❌ 源文件 $SRC 不存在"; exit 1; }
mkdir -p "$OUT_DIR"

echo "▶︎ 复制母版 → favicon.svg"
cp "$SRC" "$OUT_DIR/favicon.svg"

echo "▶︎ 生成 favicon.ico (48,32,16)"
magick "$SRC" -resize 48x48 -define icon:auto-resize=48,32,16 \
       "$OUT_DIR/favicon.ico"

echo "▶︎ 生成 apple-touch-icon.png (${PNG_SIZE}×${PNG_SIZE})"
magick "$SRC" -resize ${PNG_SIZE}x${PNG_SIZE} \
       -background none -gravity center -extent ${PNG_SIZE}x${PNG_SIZE} \
       "$OUT_DIR/apple-touch-icon.png"

echo "✅ favicon.svg / favicon.ico / apple-touch-icon.png 生成完毕 👉 $OUT_DIR"
