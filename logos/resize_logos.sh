#!/usr/bin/env bash
# resize_logos.sh  ——  批量把 *.png 缩放裁剪成 350×100，保留透明度
set -euo pipefail
shopt -s nullglob            # 若无匹配文件，*.png 展开为空，而非字面字符串

mkdir -p out

for f in *.png; do
  name="${f%.*}"             # 去掉扩展名

  magick "$f" \
    -resize 350x100^ \
    -background none -alpha set \
    -gravity center \
    -extent 350x100 \
    -strip \
    "out/${name}-350x100.png"

  echo "✅  $f  →  out/${name}-350x100.png"
done

echo "🚀  全部完成（共 $(ls out | wc -l) 个文件）"
