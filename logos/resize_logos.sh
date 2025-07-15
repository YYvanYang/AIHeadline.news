#!/usr/bin/env bash
set -e                        # 任一命令出错立即退出
mkdir -p out                  # 若无 out 文件夹则创建
for f in *.png; do
  name="${f%.*}"              # 去掉扩展名，如 big-1
  magick "$f" \
    -resize 350x100^ \
    -gravity center \
    -extent 350x100 \
    -strip \
    "out/${name}-350x100.png" # 存到 out/ 并带新尺寸后缀
done
echo "✅ 处理完毕，结果在 $(pwd)/out/"
