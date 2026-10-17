#!/bin/bash
export PATH=/usr/local/bin:/opt/homebrew/bin:$PATH
SRGB_PROFILE="/System/Library/ColorSync/Profiles/sRGB Profile.icc"

# Скриншоты/экспорты с Mac и iPhone бывают в Display P3. pngquant --strip срезает
# ICC-профиль, а его собственная конверсия неполная -> цвет слегка "тускнеет".
# Поэтому перед сжатием переводим пиксели в sRGB, если профиль не sRGB.
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
  EXT="${f##*.}"
  EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
  if [ "$EXT_LOWER" = "png" ]; then
    to_srgb "$f"
    pngquant --force --quality=75-92 --posterize 0 --speed 1 --strip --output "$f" "$f" 2>/dev/null
  fi
done
