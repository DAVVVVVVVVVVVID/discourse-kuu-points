#!/bin/bash
# 生成测试用的头像框和饰品图片（ImageMagick，开发容器里有）。正式图片由 David 做好后在后台上传。
# 规格：300×300 透明 PNG，中间直径 200 的圆是头像，装饰画在外圈或角上（见 README）
set -e
cd "$(dirname "$0")/../lib/discourse_kuu_points/demo_items"

dots() {
  local color=$1 radius=$2 size=$3
  for a in 0 45 90 135 180 225 270 315; do
    awk -v a="$a" -v r="$radius" -v s="$size" -v c="$color" 'BEGIN {
      x = 150 + r * cos(a * 3.14159265 / 180); y = 150 + r * sin(a * 3.14159265 / 180)
      printf "-fill %s -draw circle_%.1f,%.1f_%.1f,%.1f\n", c, x, y, x + s, y
    }'
  done
}

draw() {
  local out=$1
  shift
  local args=()
  for arg in "$@"; do args+=("${arg//_/ }"); done
  magick -size 300x300 xc:none "${args[@]}" "$out"
}

# 樱花粉圆环 + 米白小点
draw sakura-frame.png -fill none -stroke "#ED8690" -strokewidth 24 -draw "circle_150,150_262,150" \
  -stroke none $(dots "#FCF9F2" 112 5)

# 藏青粗环 + 浅雾蓝细环
draw navy-frame.png -fill none -stroke "#0A2D56" -strokewidth 18 -draw "circle_150,150_259,150" \
  -stroke "#C0D1E4" -strokewidth 6 -draw "circle_150,150_271,150"

# 饰品：右上角一朵樱花（五片花瓣 + 黄色花心）
petals=()
for a in -90 -18 54 126 198; do
  petals+=($(awk -v a="$a" 'BEGIN {
    x = 245 + 18 * cos(a * 3.14159265 / 180); y = 55 + 18 * sin(a * 3.14159265 / 180)
    printf "-draw circle_%.1f,%.1f_%.1f,%.1f\n", x, y, x + 15, y
  }'))
done
draw sakura-accessory.png -stroke "#FFFFFF" -strokewidth 2 -fill "#ED8690" "${petals[@]}" \
  -stroke none -fill "#F6C445" -draw "circle_245,55_253,55"
