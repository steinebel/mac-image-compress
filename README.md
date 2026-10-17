# mac-image-compress

Два bash-скрипта для macOS: сжимают фото и скриншоты прямо на месте и вызываются из файлового менеджера по горячей клавише. Я пользуюсь [ForkLift](https://binarynights.com/), но подойдёт всё, что умеет передать скрипту список выбранных файлов.

| Скрипт | Что делает |
|---|---|
| `compress_jpeg.sh` | JPG → пережимает до качества 75. PNG → конвертирует в JPG и сжимает. HEIC/HEIF → конвертирует в JPG (качество 70), а оригинал отправляет в Корзину. |
| `compress_png.sh` | PNG → сжимает через `pngquant` и сохраняет прозрачность. |

Метаданные (EXIF, GPS, модель телефона) вырезаются, так что файл можно спокойно отправлять людям.

## Установка

```bash
brew install jpegoptim pngquant exiftool
chmod +x compress_jpeg.sh compress_png.sh
```

`sips` и `trash` уже есть в macOS (`trash` — начиная с macOS 15).

Если запускать вручную:

```bash
./compress_jpeg.sh ~/Desktop/*.HEIC
```

### ForkLift

Настройки → Инструменты → `+`:

- Команда: `/путь/к/compress_jpeg.sh $SOURCE_SELECTION_PATHS`
- Горячую клавишу назначьте по вкусу, у меня `⌘⇧J`.

Если в пути к скрипту есть пробелы, удобнее положить в домашнюю папку символическую ссылку и указать в ForkLift её:

```bash
ln -s "/путь с пробелами/compress_jpeg.sh" ~/compress_jpeg.sh
```

## Два подвоха, на которых я споткнулся

**1. Повёрнутые HEIC.** iPhone не поворачивает сами пиксели, а только записывает тег `Orientation` («покажи повёрнутым на 90°»). `sips` переносит этот тег в JPEG, а `jpegoptim --strip-all` его срезает, и фото ложится на бок. Поэтому скрипт читает тег через `exiftool` и поворачивает пиксели заранее.

**2. Бледные цвета.** iPhone снимает в цветовом пространстве Display P3, а оно шире обычного sRGB. Если срезать ICC-профиль и оставить пиксели как есть, программы прочитают их как sRGB, и картинка потускнеет. Поэтому перед сжатием скрипт честно переводит пиксели в sRGB:

```bash
sips -m "/System/Library/ColorSync/Profiles/sRGB Profile.icc" photo.jpg
```

Сначала я сделал это только для HEIC и забыл про обычные JPG с iPhone, так что проблема вернулась. Сейчас перевод в sRGB стоит во всех ветках.

Как проверить файл:

```bash
sips -g profile photo.jpg   # Display P3 → после сжатия без перевода в sRGB станет бледным
```

## Зависимости

- [jpegoptim](https://github.com/tjko/jpegoptim)
- [pngquant](https://pngquant.org/)
- [ExifTool](https://exiftool.org/)
- `sips` (входит в macOS)
