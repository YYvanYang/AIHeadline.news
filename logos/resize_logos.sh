#!/usr/bin/env bash
#
# ──────────────────────────────────────────────────────────────────────────────
#  resize_logos.sh
#  ──────────────────────────────────────────────────────────────────────────────
#  批量将当前目录下的 **PNG** Logo　等比缩放并居中裁剪至固定画布，
#  同时保留透明背景（Alpha 通道），然后输出到 ./out/ 目录。
#
#  ➤ 处理流程（每张图片）：
#     1. -resize ${W}x${H}^        等比放大 / 缩小，确保覆盖目标画布。
#     2. -background none          将填充背景设为透明。
#     3. -alpha set                若源图无 Alpha 通道则创建。
#     4. -gravity center           以中心为基准裁剪／填充。
#     5. -extent ${W}x${H}         裁剪 / 填充至精确尺寸。
#     6. -strip                    去掉 EXIF、ICC 等元数据。
#
#  ➤ 使用方法：
#     chmod +x resize_logos.sh      # 赋可执行权限
#     ./resize_logos.sh             # 在包含 *.png 的目录运行
#
#  ➤ 可自定义：
#     TARGET_W / TARGET_H           修改目标尺寸，例如 700×200
#     想同时输出多种尺寸，可在 for 循环复制一段 magick 命令并改尺寸。
#
#  ➤ 依赖：
#     - Bash 4.x 及以上（支持 'shopt -s nullglob'）
#     - ImageMagick 7，命令行为 `magick`
#
#  ➤ 退出码：
#     0  成功
#     1  当前目录没有符合条件的 PNG 文件
#
#  Author : Yvan
#  Version: 2025‑07‑15
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail
shopt -s nullglob                # 若无匹配文件，*.png 展开为空列表而非字面字符串

TARGET_W=350
TARGET_H=100

mkdir -p out

png_files=(*.png)
[[ ${#png_files[@]} -eq 0 ]] && { echo "❌ 未找到 PNG 文件，脚本退出"; exit 1; }

for f in "${png_files[@]}"; do
  name="${f%.*}"                 # 去掉扩展名

  magick "$f" \
    -resize "${TARGET_W}x${TARGET_H}^" \
    -background none -alpha set \
    -gravity center \
    -extent "${TARGET_W}x${TARGET_H}" \
    -strip \
    "out/${name}-${TARGET_W}x${TARGET_H}.png"

  echo "✅  $f  →  out/${name}-${TARGET_W}x${TARGET_H}.png"
done

echo "🚀  全部完成，共生成 $(ls out | wc -l) 个文件。输出目录：$(realpath out)"
