#!/bin/bash
export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH
SRGB_PROFILE="/System/Library/ColorSync/Profiles/sRGB Profile.icc"

# iPhone снимает в Display P3 (шире sRGB). --strip-all снимет и ICC-профиль,
# а пиксели останутся в P3 -> без профиля их прочитают как sRGB и цвет "потускнеет".
# Поэтому перед сжатием честно переводим пиксели в sRGB, если профиль не sRGB.
# Касается ВСЕХ форматов (JPG/PNG/HEIC), не только HEIC.
to_srgb() {
  local P
  P=$(sips -g profile "$1" 2>/dev/null | awk -F': ' '/profile:/{print $2}')
  case "$P" in
    sRGB*|""|"<nil>") ;;
    *) sips -m "$SRGB_PROFILE" "$1" > /dev/null 2>&1 ;;
  esac
}

for f in "$@"
do
  DIR=$(dirname "$f")
  FILE=$(basename "$f")
  EXT="${FILE##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

  if [ "$EXT_LOWER" = "jpg" ] || [ "$EXT_LOWER" = "jpeg" ]; then
    to_srgb "$f"
    jpegoptim --max=75 --strip-all --quiet "$f"
  elif [ "$EXT_LOWER" = "png" ]; then
    NAME="${FILE%.*}"
    sips -s format jpeg "$f" --out "$DIR/${NAME}.jpg" > /dev/null 2>&1
    to_srgb "$DIR/${NAME}.jpg"
    jpegoptim --max=75 --strip-all --quiet "$DIR/${NAME}.jpg"
  elif [ "$EXT_LOWER" = "heic" ] || [ "$EXT_LOWER" = "heif" ]; then
    NAME="${FILE%.*}"
    OUT="$DIR/${NAME}.jpg"
    sips -s format jpeg "$f" --out "$OUT" > /dev/null 2>&1
    if [ -f "$OUT" ]; then
      # HEIC хранит поворот только тегом Orientation, sips его копирует, но не
      # применяет к пикселям. jpegoptim --strip-all срежет тег -> фото "перевернётся".
      # Поэтому поворот физически запекаем в пиксели заранее, по реальному EXIF-тегу.
      ORIENT=$(exiftool -Orientation -n -T -q -q "$f" 2>/dev/null)
      case "$ORIENT" in
        3) sips --rotate 180 "$OUT" > /dev/null 2>&1 ;;
        6) sips --rotate 90 "$OUT" > /dev/null 2>&1 ;;
        8) sips --rotate 270 "$OUT" > /dev/null 2>&1 ;;
      esac
      to_srgb "$OUT"
      jpegoptim --max=70 --strip-all --quiet "$OUT"
      trash "$f"
    fi
  fi
done
