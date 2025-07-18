#!/usr/bin/env bash
#
# ==============================================================================
#  resize_logos.sh  ·  多格式品牌 Logo 批处理流水线
# ==============================================================================
#  功能：
#    • 将当前目录中的 LOGO 源文件（SVG / PNG / JPG / WEBP）统一输出为：
#        - PNG  TrueColor + Alpha（透明、无损）
#        - WebP Lossless（现代浏览器更小体积）
#        - SVG 原文件（如是矢量源则复制；位图源则跳过）
#    • 固定画布尺寸（默认 350×100），等比缩放后居中裁剪，保留透明度。
#    • 可选输出 2× / 3× Retina 版本。
#    • 对生成的 PNG 进行 oxipng 无损压缩（若已安装）。
#
#  推荐用途：网站页眉 Logo / 深浅主题多格式发布 / CDN 静态资源流水线。
#
#  依赖：
#    - ImageMagick 7+  (magick)  # 官方统一 CLI。https://imagemagick.org
#    - oxipng (可选)             # 无损 PNG 压缩
#
#  使用：
#    chmod +x resize_logos.sh
#    ./resize_logos.sh
#
#  可配置变量（按需在下方修改或运行时 env 覆盖，如：TARGET_W=700 ./resize_logos.sh）：
#    TARGET_W=350          # 目标宽
#    TARGET_H=100          # 目标高
#    RETINA=false          # 同时输出 2× / 3× （true/false）
#    SVG_DPI=400           # 栅格化矢量时的初始密度（调大更锐）
#    WEBP_LOSSLESS=true    # WebP 无损（true）或有损（false，根据 quality）
#    WEBP_QUALITY=90       # 有损时使用；无损时忽略
#    OXIPNG_LEVEL=4        # 0–6，越大压缩越强
#
#  返回码：
#    0 正常完成
#    1 无可处理源文件
#    2 缺少 ImageMagick
#
#  Author : Yvan
#  Updated: 2025-07-15
# ==============================================================================

set -euo pipefail
shopt -s nullglob

# -------------------- 用户可配置区（支持外部覆盖） --------------------
: "${TARGET_W:=350}"
: "${TARGET_H:=100}"
: "${RETINA:=false}"
: "${SVG_DPI:=400}"
: "${WEBP_LOSSLESS:=true}"
: "${WEBP_QUALITY:=90}"
: "${OXIPNG_LEVEL:=4}"
OUT_DIR="out"
# ----------------------------------------------------------------------

# --- 依赖检查：ImageMagick ---
if ! command -v magick >/dev/null 2>&1; then
  echo "❌ 未检测到 ImageMagick (magick)。请安装后重试。" >&2
  exit 2
fi

# 输出版本信息（方便调试）
magick -version | sed 's/^/ℹ️  IM: /'

mkdir -p "$OUT_DIR"

# 收集候选源文件（大小写兼容）
files=( *.[Pp][Nn][Gg] *.[Jj][Pp][Gg] *.[Jj][Pp][Ee][Gg] *.[Ww][Ee][Bb][Pp] *.[Ss][Vv][Gg] )
# 如果模式未匹配任何文件，数组会包含原始模式字符串；借助 nullglob 已避免这一点。
if [[ ${#files[@]} -eq 0 ]]; then
  echo "❌ 未找到可处理的源文件（支持: png/jpg/jpeg/webp/svg）。"
  exit 1
fi

echo "▶️  待处理文件数量：${#files[@]}"
echo "▶️  输出尺寸：${TARGET_W}×${TARGET_H}px"

# ---- 构建公共滤镜参数（缩放 + 裁剪 + TrueColor + Alpha）----
common_filter=(
  -filter Lanczos -define filter:blur=0.8   # 高质量缩放滤镜。IM 文档示例。 
  -resize "${TARGET_W}x${TARGET_H}^"        # 等比缩放至覆盖目标画布。 
  -background none -alpha set               # 保留透明度/添加 Alpha。 
  -gravity center -extent "${TARGET_W}x${TARGET_H}"  # 居中裁剪至固定画布。 
  -define png:color-type=6 -quality 100     # TrueColor+Alpha；PNG 无损。 
  -strip                                     # 去元数据。 
)

# ---- WebP 编码参数 ----
if [[ "$WEBP_LOSSLESS" == true ]]; then
  webp_filter=(-define webp:lossless=true -define webp:method=6 -quality 100)
else
  webp_filter=(-quality "$WEBP_QUALITY" -define webp:method=6)
fi

# ---- 处理循环 ----
for f in "${files[@]}"; do
  [[ -f "$f" ]] || continue
  base="${f%.*}"
  ext="${f##*.}"
  lower_ext="${ext,,}"

  case "$lower_ext" in
    svg)
      # 1) 拷贝原 SVG（原汁原味）
      cp -- "$f" "$OUT_DIR/${base}.svg"

      # 2) 栅格化 → PNG
      magick -density "$SVG_DPI" "$f" \
        "${common_filter[@]}" \
        "$OUT_DIR/${base}-${TARGET_W}x${TARGET_H}.png"

      # 3) 栅格化 → WebP
      magick -density "$SVG_DPI" "$f" \
        "${common_filter[@]}" \
        "${webp_filter[@]}" \
        "$OUT_DIR/${base}-${TARGET_W}x${TARGET_H}.webp"
      ;;
    png|jpg|jpeg|webp)
      # 源位图 → PNG
      magick "$f" \
        "${common_filter[@]}" \
        "$OUT_DIR/${base}-${TARGET_W}x${TARGET_H}.png"

      # 源位图 → WebP
      magick "$f" \
        "${common_filter[@]}" \
        "${webp_filter[@]}" \
        "$OUT_DIR/${base}-${TARGET_W}x${TARGET_H}.webp"
      ;;
    *)
      echo "⚠️  跳过未知扩展名：$f"
      continue
      ;;
  esac

  # ---- Retina 输出（可选）----
  if [[ "$RETINA" == true ]]; then
    for scale in 2 3; do
      W=$((TARGET_W*scale))
      H=$((TARGET_H*scale))
      rf_png="$OUT_DIR/${base}-${W}x${H}.png"
      rf_webp="$OUT_DIR/${base}-${W}x${H}.webp"

      magick "$f" \
        -filter Lanczos -define filter:blur=0.8 \
        -resize "${W}x${H}^" \
        -background none -alpha set \
        -gravity center -extent "${W}x${H}" \
        -define png:color-type=6 -quality 100 -strip \
        "$rf_png"

      magick "$f" \
        -filter Lanczos -define filter:blur=0.8 \
        -resize "${W}x${H}^" \
        -background none -alpha set \
        -gravity center -extent "${W}x${H}" \
        -define png:color-type=6 -quality 100 -strip \
        "${webp_filter[@]}" \
        "$rf_webp"
    done
  fi

  echo "✅  完成：$f"
done

# ---- oxipng 压缩（无损）----
if command -v oxipng >/dev/null 2>&1; then
  echo "🗜  正在 oxipng 无损压缩 PNG (级别 $OXIPNG_LEVEL)…"
  # 防止空匹配导致错误
  png_targets=( "$OUT_DIR"/*-"${TARGET_W}x${TARGET_H}".png )
  if [[ "$RETINA" == true ]]; then
    png_targets+=( "$OUT_DIR"/*-"$((TARGET_W*2))x$((TARGET_H*2))".png "$OUT_DIR"/*-"$((TARGET_W*3))x$((TARGET_H*3))".png )
  fi
  # 过滤掉不存在的模式
  real_png_targets=()
  for p in "${png_targets[@]}"; do
    [[ -f "$p" ]] && real_png_targets+=( "$p" )
  done
  if (( ${#real_png_targets[@]} > 0 )); then
    oxipng -o "$OXIPNG_LEVEL" --strip all "${real_png_targets[@]}" || echo "⚠️  oxipng 压缩时出现警告，但已继续。"
  fi
else
  echo "⚠️  未检测到 oxipng，跳过 PNG 压缩。建议安装：sudo apt install oxipng"
fi

echo "🎉  全部完成，输出目录：$(realpath "$OUT_DIR")"
exit 0
