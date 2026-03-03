
################################################################

# Скрипт предподготовки видео для добавления в общую компиляцию.
# - Реенкодит видео под единые разрешения, частоту аудио и т.д.
# - Добавляет подпись с линией прогресса видео под ней

# Аргумент #1 - путь видео на вход
# Аргумент #2 - путь видео на выход
# Аргумент #3 - подпись внутри видео

################################################################

# Глобальные переменные (общие для всех видео) - 1080p
video_height="1080"
alpha_text="0.7"
alpha_box="0.5"
box_margin_right="75"
box_margin_top="72"
boxborderw="5"
progress_line_h="2"
fontfile="./VCR_OSD_MONO.ttf"
fontsize="24"

# Локальные переменные (индивидуальные для каждого видео)
fn_in="$1"
fn_out="$2"
label_text="$3"

# Просчёт размеров текста
twh=$(ffmpeg -loglevel debug -i "${fn_in}" -vf "drawtext=fontfile=${fontfile}:text='${label_text}':fontcolor=white:fontsize=${fontsize}" -vframes 1 -f null - 2>&1 | grep -E -m 1 ".*Parsed_drawtext_.*text_w.*text_h.*" | sed -nE 's/.*text_w\:([0-9]+)\s+text_h\:([0-9]+).*/\1;\2/p')
tw=$(echo "$twh" | cut -d ";" -f 1)
th=$(echo "$twh" | cut -d ";" -f 2)

# Вычисление размеров подложки текста
bw=$(($tw+2*$boxborderw))
bh=$(($th+2*$boxborderw))

# Извлечение продолжительности видео
vt=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${fn_in}")

# Обработка видео
ffmpeg -y -i "${fn_in}" -c:v h264_nvenc -filter_complex "
    color=c=black:s=${bw}x${bh}[pad_black];
    color=c=white:s=${bw}x${bh}[pad_white];
    [pad_black][pad_white]overlay=-w+(w/${vt})*t:H-${progress_line_h},format=rgba,colorchannelmixer=aa=${alpha_box}[box];
    [0:v]scale=-1:${video_height}[v];
    [v][box]overlay=(W-${bw}-${box_margin_right}):${box_margin_top}:shortest=1,drawtext=fontfile=${fontfile}:text='${label_text}':fontcolor=white:alpha=${alpha_text}:fontsize=${fontsize}:x=(w-${bw}-${box_margin_right}+${boxborderw}):y=(${box_margin_top}+${boxborderw})
" -qp 20 -ar 48000 "${fn_out}"

################################################################
