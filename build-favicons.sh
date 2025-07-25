#!/usr/bin/env bash
#
# ==============================================================================
#  build-favicons.sh  ·  现代化 Favicon 生成流水线
# ==============================================================================
#  功能：
#    • 从源文件（SVG / PNG / JPG / WEBP）生成完整的 favicon 套件：
#        - favicon.svg（原文件复制，如为矢量源）
#        - favicon.ico（多尺寸：48, 32, 16px）
#        - apple-touch-icon.png（Apple 设备专用）
#        - 标准 PNG 图标：16x16, 32x32
#        - Android 图标：192x192, 512x512
#        - WebP 现代格式（更小体积）
#        - PWA 清单图标（可选）
#    • 高质量 Lanczos 缩放，保留透明度
#    • 可选 oxipng 无损压缩优化
#    • 支持环境变量自定义配置
#
#  推荐用途：网站 favicon 生成 / PWA 图标 / 多平台兼容性
#
#  依赖：
#    - ImageMagick 7+  (magick)  # 官方统一 CLI。https://imagemagick.org
#    - oxipng (可选)             # 无损 PNG 压缩
#
#  使用：
#    chmod +x build-favicons.sh
#    ./build-favicons.sh [源文件]          # 默认使用 logo.svg
#    ./build-favicons.sh custom-logo.png
#
#  可配置变量（按需在运行时 env 覆盖）：
#    SRC_FILE="logo.svg"       # 源文件路径
#    OUT_DIR="./static"        # 输出目录
#    APPLE_SIZE=180            # Apple touch icon 尺寸
#    PWA_ICONS=false           # 生成 PWA 清单图标
#    WEBP_OUTPUT=true          # 生成 WebP 格式
#    SVG_DPI=400               # 栅格化矢量时的初始密度
#    WEBP_LOSSLESS=true        # WebP 无损模式
#    WEBP_QUALITY=90           # 有损时使用
#    OXIPNG_LEVEL=4            # 0–6，越大压缩越强
#
#  返回码：
#    0 正常完成
#    1 源文件不存在
#    2 缺少 ImageMagick
#
#  Author : Yvan
#  Updated: 2025-07-25
# ==============================================================================

set -euo pipefail
shopt -s nullglob

# -------------------- 用户可配置区（支持外部覆盖） --------------------
: "${SRC_FILE:=${1:-logo.svg}}"
: "${OUT_DIR:=./static}"
: "${APPLE_SIZE:=180}"
: "${PWA_ICONS:=false}"
: "${WEBP_OUTPUT:=true}"
: "${SVG_DPI:=400}"
: "${WEBP_LOSSLESS:=true}"
: "${WEBP_QUALITY:=90}"
: "${OXIPNG_LEVEL:=4}"
# ----------------------------------------------------------------------

# --- 依赖检查：ImageMagick ---
if ! command -v magick >/dev/null 2>&1; then
  echo "❌ 未检测到 ImageMagick (magick)。请安装后重试。" >&2
  echo "   安装方法：brew install imagemagick 或访问 https://imagemagick.org" >&2
  exit 2
fi

# --- 源文件检查 ---
if [[ ! -f "$SRC_FILE" ]]; then
  echo "❌ 源文件 $SRC_FILE 不存在" >&2
  exit 1
fi

# 输出版本信息（方便调试）
magick -version | head -1 | sed 's/^/ℹ️  /'

mkdir -p "$OUT_DIR"

echo "▶️  源文件：$SRC_FILE"
echo "▶️  输出目录：$OUT_DIR"
echo "▶️  Apple 图标尺寸：${APPLE_SIZE}x${APPLE_SIZE}px"

# 获取源文件信息
base_name="${SRC_FILE%.*}"
ext="${SRC_FILE##*.}"
lower_ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

# ---- 构建公共滤镜参数（高质量缩放 + 透明度处理）----
common_filter=(
  -filter Lanczos -define filter:blur=0.8   # 高质量缩放滤镜
  -background none -alpha set               # 保留透明度
  -define png:color-type=6 -quality 100     # TrueColor+Alpha；PNG 无损
  -strip                                     # 去元数据
)

# ---- WebP 编码参数 ----
if [[ "$WEBP_LOSSLESS" == true ]]; then
  webp_filter=(-define webp:lossless=true -define webp:method=6 -quality 100)
else
  webp_filter=(-quality "$WEBP_QUALITY" -define webp:method=6)
fi

# ---- 1. 复制原始 SVG（如果源文件是 SVG）----
if [[ "$lower_ext" == "svg" ]]; then
  echo "▶️  复制母版 → favicon.svg"
  cp "$SRC_FILE" "$OUT_DIR/favicon.svg"
fi

# ---- 2. 生成 favicon.ico（多尺寸）----
echo "▶️  生成 favicon.ico (48,32,16)"
if [[ "$lower_ext" == "svg" ]]; then
  magick -density "$SVG_DPI" "$SRC_FILE" -resize 48x48 \
    -define icon:auto-resize=48,32,16 \
    "$OUT_DIR/favicon.ico"
else
  magick "$SRC_FILE" -resize 48x48 \
    "${common_filter[@]}" \
    -define icon:auto-resize=48,32,16 \
    "$OUT_DIR/favicon.ico"
fi

# ---- 3. 生成 Apple Touch Icon ----
echo "▶️  生成 apple-touch-icon.png (${APPLE_SIZE}×${APPLE_SIZE})"
if [[ "$lower_ext" == "svg" ]]; then
  magick -density "$SVG_DPI" "$SRC_FILE" \
    "${common_filter[@]}" \
    -resize "${APPLE_SIZE}x${APPLE_SIZE}" \
    -gravity center -extent "${APPLE_SIZE}x${APPLE_SIZE}" \
    "$OUT_DIR/apple-touch-icon.png"
else
  magick "$SRC_FILE" \
    "${common_filter[@]}" \
    -resize "${APPLE_SIZE}x${APPLE_SIZE}" \
    -gravity center -extent "${APPLE_SIZE}x${APPLE_SIZE}" \
    "$OUT_DIR/apple-touch-icon.png"
fi

# ---- 4. 生成标准 PNG 图标 ----
echo "▶️  生成标准 PNG 图标"
for size in 16 32; do
  output_file="$OUT_DIR/favicon-${size}x${size}.png"
  if [[ "$lower_ext" == "svg" ]]; then
    magick -density "$SVG_DPI" "$SRC_FILE" \
      "${common_filter[@]}" \
      -resize "${size}x${size}" \
      -gravity center -extent "${size}x${size}" \
      "$output_file"
  else
    magick "$SRC_FILE" \
      "${common_filter[@]}" \
      -resize "${size}x${size}" \
      -gravity center -extent "${size}x${size}" \
      "$output_file"
  fi
  echo "   ✓ favicon-${size}x${size}.png"
done

# ---- 5. 生成 Android Chrome 图标 ----
echo "▶️  生成 Android Chrome 图标"
for size in 192 512; do
  output_file="$OUT_DIR/android-chrome-${size}x${size}.png"
  if [[ "$lower_ext" == "svg" ]]; then
    magick -density "$SVG_DPI" "$SRC_FILE" \
      "${common_filter[@]}" \
      -resize "${size}x${size}" \
      -gravity center -extent "${size}x${size}" \
      "$output_file"
  else
    magick "$SRC_FILE" \
      "${common_filter[@]}" \
      -resize "${size}x${size}" \
      -gravity center -extent "${size}x${size}" \
      "$output_file"
  fi
  echo "   ✓ android-chrome-${size}x${size}.png"
done

# ---- 6. 生成 WebP 格式（可选）----
if [[ "$WEBP_OUTPUT" == true ]]; then
  echo "▶️  生成 WebP 格式图标"
  for size in 16 32 192 512; do
    output_file="$OUT_DIR/favicon-${size}x${size}.webp"
    if [[ "$lower_ext" == "svg" ]]; then
      magick -density "$SVG_DPI" "$SRC_FILE" \
        "${common_filter[@]}" \
        "${webp_filter[@]}" \
        -resize "${size}x${size}" \
        -gravity center -extent "${size}x${size}" \
        "$output_file"
    else
      magick "$SRC_FILE" \
        "${common_filter[@]}" \
        "${webp_filter[@]}" \
        -resize "${size}x${size}" \
        -gravity center -extent "${size}x${size}" \
        "$output_file"
    fi
    echo "   ✓ favicon-${size}x${size}.webp"
  done
  
  # Apple Touch Icon WebP
  output_file="$OUT_DIR/apple-touch-icon.webp"
  if [[ "$lower_ext" == "svg" ]]; then
    magick -density "$SVG_DPI" "$SRC_FILE" \
      "${common_filter[@]}" \
      "${webp_filter[@]}" \
      -resize "${APPLE_SIZE}x${APPLE_SIZE}" \
      -gravity center -extent "${APPLE_SIZE}x${APPLE_SIZE}" \
      "$output_file"
  else
    magick "$SRC_FILE" \
      "${common_filter[@]}" \
      "${webp_filter[@]}" \
      -resize "${APPLE_SIZE}x${APPLE_SIZE}" \
      -gravity center -extent "${APPLE_SIZE}x${APPLE_SIZE}" \
      "$output_file"
  fi
  echo "   ✓ apple-touch-icon.webp"
fi

# ---- 7. 生成 PWA 清单图标（可选）----
if [[ "$PWA_ICONS" == true ]]; then
  echo "▶️  生成 PWA 清单图标"
  for size in 72 96 128 144 152 384; do
    output_file="$OUT_DIR/icon-${size}x${size}.png"
    if [[ "$lower_ext" == "svg" ]]; then
      magick -density "$SVG_DPI" "$SRC_FILE" \
        "${common_filter[@]}" \
        -resize "${size}x${size}" \
        -gravity center -extent "${size}x${size}" \
        "$output_file"
    else
      magick "$SRC_FILE" \
        "${common_filter[@]}" \
        -resize "${size}x${size}" \
        -gravity center -extent "${size}x${size}" \
        "$output_file"
    fi
    echo "   ✓ icon-${size}x${size}.png"
  done
fi

# ---- 8. oxipng 压缩（无损）----
if command -v oxipng >/dev/null 2>&1; then
  echo "🗜  正在 oxipng 无损压缩 PNG (级别 $OXIPNG_LEVEL)…"
  
  # 收集所有 PNG 文件
  png_files=( "$OUT_DIR"/*.png )
  if (( ${#png_files[@]} > 0 )); then
    # 过滤存在的文件
    real_png_files=()
    for p in "${png_files[@]}"; do
      [[ -f "$p" ]] && real_png_files+=( "$p" )
    done
    
    if (( ${#real_png_files[@]} > 0 )); then
      oxipng -o "$OXIPNG_LEVEL" --strip all "${real_png_files[@]}" || echo "⚠️  oxipng 压缩时出现警告，但已继续。"
      echo "   ✓ 压缩了 ${#real_png_files[@]} 个 PNG 文件"
    fi
  fi
else
  echo "⚠️  未检测到 oxipng，跳过 PNG 压缩。"
  echo "   安装建议：brew install oxipng 或 cargo install oxipng"
fi

# ---- 9. 生成使用说明 ----
cat > "$OUT_DIR/favicon-usage.txt" << EOF
Favicon 文件使用说明
==================

HTML 头部引用示例：
<!-- 基础 favicon -->
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">

<!-- 标准尺寸 -->
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16x16.png">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32x32.png">

<!-- Android Chrome -->
<link rel="icon" type="image/png" sizes="192x192" href="/android-chrome-192x192.png">
<link rel="icon" type="image/png" sizes="512x512" href="/android-chrome-512x512.png">

<!-- WebP 现代格式（可选） -->
<link rel="icon" type="image/webp" sizes="16x16" href="/favicon-16x16.webp">
<link rel="icon" type="image/webp" sizes="32x32" href="/favicon-32x32.webp">

Web App Manifest 示例：
{
  "icons": [
    {
      "src": "/android-chrome-192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/android-chrome-512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}

生成时间: $(date)
源文件: $SRC_FILE
EOF

echo "🎉  Favicon 套件生成完成！"
echo "📁  输出目录：$(realpath "$OUT_DIR")"
echo "📄  使用说明：$OUT_DIR/favicon-usage.txt"

# 统计生成的文件
file_count=$(find "$OUT_DIR" -name "favicon*" -o -name "apple-touch-icon*" -o -name "android-chrome*" -o -name "icon-*" | wc -l | tr -d ' ')
echo "📊  共生成 $file_count 个图标文件"

exit 0