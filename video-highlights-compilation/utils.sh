#!/bin/bash
# ----------------------------------------------------------------

# Проверка INPUT_DIR и INPUT_EXT
function assert_inputs() {
    if [[ -z "${INPUT_DIR+set}" || -z "${INPUT_DIR}" ]]; then
        custom_exit "[ERROR] INPUT_DIR must be set!"
    fi
    if [[ ! -d "$INPUT_DIR" ]]; then
        custom_exit "[ERROR] Input directory '%s' doesn't exist!" "${INPUT_DIR}"
    fi
    if [[ -z "${INPUT_EXT+set}" || -z "${INPUT_EXT}" ]]; then
        custom_exit "[ERROR] INPUT_EXT must be set!"
    fi
}

# Инициализация массива INPUT_FILES
# Не перезаписывает INPUT_FILES, если это уже инициализированный массив.
function init_input_files() {
    if [[ ! -z "${INPUT_FILES+set}" && "$(declare -p INPUT_FILES)" =~ "declare -a" ]]; then
        return 0
    fi
    assert_inputs
    INPUT_FILES=()
    for file in "$(realpath "${INPUT_DIR}" | cygpath -u -f -)"/*."${INPUT_EXT}"; do
        INPUT_FILES+=("$file")
    done
    echo "#INPUT_FILES: ${#INPUT_FILES[@]}"
}

# Получение директории для вывода
#  по имени текущего скрипта.
function get_output_dir() {
    sh_bn=$(basename -- "$0")
    sh_fn="${sh_bn%.*}"
    if [[ "$sh_bn" = "$sh_fn" ]]; then
        echo -n "${sh_fn}-output"
    else
        echo -n "${sh_fn}"
    fi
}

# Проверка наличия значений у глобальных переменных.
# Аргументы: имена переменных.
# Останавливает выполнение скрипта, если
#  хотя бы одна переменная не была определена
#  или оказалась пустой строкой.
# При остановке отображает состояния переменных.
function assert_vars() {
    msg=""
    err="0"
    while [[ "$#" -gt "0" ]]; do
        if [[ -z "${!1+set}" || -z "${!1}" ]]; then
            msg="${msg}\n - $1"
            err="1"
        else
            msg="${msg}\n + $1"
        fi
        shift
    done
    if [[ "$err" -ne "0" ]]; then
        custom_exit "[ERROR] Not all global parameters were provided:${msg}"
    fi
}

# Вывод прогресса
function print_progress() {
    prefix="$1" current=$2; total=$3; step_p=$4
    [[ -z $current || -z $total || -z $step_p ]] && return -1
    [[ $current -lt 0 ]] && return -1
    [[ $current -gt $total ]] && return -1
    [[ $step_p -le 0 || $step_p -gt 100 ]] && return -1
    # step=$((total*step_p/100)); [[ $step -eq 0 ]] && step=1
    step=$(((10*total*step_p/100 + 5) / 10)); [[ $step -eq 0 ]] && step=1
    if [[ $((current%step)) -eq 0 || $current -eq $total ]]; then
        width=40
        width_fill=$((width*current/total))
        width_none=$((width-width_fill))
        [[ $width_fill -gt 0 ]] && str_fill="$(printf -- '█%0.s' $(seq 1 $width_fill))" || str_fill=""
        [[ $width_none -gt 0 ]] && str_none="$(printf -- ' %0.s' $(seq 1 $width_none))" || str_none=""
        # percentage=$((100*current/total))
        # percentage=$(((10*100*current/total + 5)/10))
        # percentage=$(((100*current + total - 1)/total))
        a=100; percentage=$(((((a*100*current/total + (a*step_p/2))/(a*step_p))*(a*step_p))/a))
        [[ $percentage -eq 100 && $current -lt $total ]] && percentage=99
        [[ ${#percentage} -lt 3 ]] && offset_1="$(printf -- ' %0.s' $(seq 1 "$((3-${#percentage}))"))" || offset_1=""
        [[ ${#current} -lt ${#total} ]] && offset_2="$(printf -- ' %0.s' $(seq 1 "$((${#total}-${#current}))"))" || offset_2=""
        echo "${prefix}${offset_1}${percentage}%|${str_fill}${str_none}| ${offset_2}${current}/${total}"
    fi
}

# ----------------------------------------------------------------

# Функции для работы с метаданными видео

CACHE_FN="cache.txt"
CACHE_SEP=$'\t'

# Получение высоты видео с кэшированием результата.
# Записывает результат в переменную HEIGHT.
# При ошибке записывает пустую строку.
function read_height() {
    if [[ "$#" -gt "0" ]]; then
        if [[ "$USE_CACHE" -ne "1" || -z "${CACHE["$1"]}" ]]; then
            if [[ -f "$1" ]]; then
                HEIGHT="$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=s=x:p=0 "$1")"
                if [[ "$USE_CACHE" -eq "1" && -n "$HEIGHT" ]]; then
                    CACHE["$1"]="$HEIGHT"
                    FLUSH_CACHE="1"
                fi
            else
                HEIGHT=""
            fi
        else
            HEIGHT="${CACHE["$1"]}"
        fi
    else
        HEIGHT=""
    fi
}

function init_cache() {
    if [[ "$USE_CACHE" -ne "1" ]]; then
        declare -gA CACHE
        if [[ -f "$CACHE_FN" ]]; then
            IFSI="$IFS"
            IFS="$CACHE_SEP"
            while read -r file height; do
                if [[ -n "$file" && -n "$height" ]]; then
                    CACHE["$file"]="$height"
                fi
            done < "$CACHE_FN"
            IFS="$IFSI"
        fi
        USE_CACHE="1"
        FLUSH_CACHE="0"
    fi
}

function flush_cache() {
    [[ "$USE_CACHE" -ne "1" ]] && return -1
    [[ "$FLUSH_CACHE" -ne "1" ]] && return -1
    exec 3> "$CACHE_FN"
    for file in "${!CACHE[@]}"; do
        height="${CACHE["$file"]}"
        if [[ ! -z "${height}" ]]; then
            printf "%s%s%s\n" "${file}" "${CACHE_SEP}" "${height}" >&3
        fi
    done
    exec 3>&-
    FLUSH_CACHE="0"
}

# ----------------------------------------------------------------

# Функции отбора видео на вход
# Конструируют массив SELECTED_FILES

function select_all() {
    init_input_files
    SELECTED_FILES=()
    for file in "${INPUT_FILES[@]}"; do
        SELECTED_FILES+=("$file")
    done
    echo "#SELECTED_FILES: ${#SELECTED_FILES[@]}"
}

function select_top() {
    if [[ ! "$1" =~ ^[0-9]+$ || "$1" -le 0 ]]; then
        custom_exit "[ERROR] select_top: invalid argument"
    fi
    init_input_files
    SELECTED_FILES=()
    i=0
    for file in "${INPUT_FILES[@]}"; do
        SELECTED_FILES+=("$file")
        ((i++))
        [[ $i -ge $1 ]] && break
    done
    echo "#SELECTED_FILES: ${#SELECTED_FILES[@]}"
}

function select_lt1080() {
    init_input_files
    init_cache
    SELECTED_FILES=()
    i_cur=0
    i_all="${#INPUT_FILES[@]}"
    print_progress "Selecting videos... " "$i_cur" "$i_all" 10
    for file in "${INPUT_FILES[@]}"; do
        read_height "$file"
        [[ -n "$HEIGHT" && "$HEIGHT" -lt "1080" ]] && SELECTED_FILES+=("$file")
        ((i_cur++))
        print_progress "Selecting videos... " "$i_cur" "$i_all" 10
    done
    echo "#SELECTED_FILES: ${#SELECTED_FILES[@]}"
    flush_cache
}

function select_ge1080() {
    init_input_files
    init_cache
    SELECTED_FILES=()
    i_cur=0
    i_all="${#INPUT_FILES[@]}"
    print_progress "Selecting videos... " "$i_cur" "$i_all" 10
    for file in "${INPUT_FILES[@]}"; do
        read_height "$file"
        [[ -n "$HEIGHT" && "$HEIGHT" -ge "1080" ]] && SELECTED_FILES+=("$file")
        ((i_cur++))
        print_progress "Selecting videos... " "$i_cur" "$i_all" 10
    done
    echo "#SELECTED_FILES: ${#SELECTED_FILES[@]}"
    flush_cache
}

# ----------------------------------------------------------------

# Функция предподготовки видео для добавления в общую компиляцию:
# - Реенкодит видео под единые разрешения, частоту аудио и т.д.
# - Добавляет подпись с линией прогресса видео под ней

# Аргументы (параметры, индивидуальные для каждого видео):
# - (1) Путь видео на вход
# - (2) Путь видео на выход

# Глобальные переменные (параметры, общие для всех видео):
# - VIDEO_HEIGHT
# - ALPHA_TEXT
# - ALPHA_BOX
# - BOX_MARGIN_RIGHT
# - BOX_MARGIN_TOP
# - BOXBORDERW
# - PROGRESS_LINE_H
# - FONTFILE
# - FONTSIZE
# - FORMAT_LABEL

# Возвращает код возврата основного вызова ffmpeg.
# В случае ошибки/прерывания основного вызова оставляет
#  путь до недоделанного видео в HANGING_VIDEO.

function preprocess_video() {
    # Считывание аргументов
    fp_in="$1"
    fp_out="$2"
    
    # Проверка наличия глобальных параметров
    assert_vars             \
        VIDEO_HEIGHT        \
        ALPHA_TEXT          \
        ALPHA_BOX           \
        BOX_MARGIN_RIGHT    \
        BOX_MARGIN_TOP      \
        BOXBORDERW          \
        PROGRESS_LINE_H     \
        FONTFILE            \
        FONTSIZE            \
        FORMAT_LABEL

    # Получение текста надписи
    label_text=$(basename -- "$fp_in"); label_text="${label_text%.*}"
    if [[ "$FORMAT_LABEL" -ne "0" ]]; then
        d="[0-9]"; REGEX="^($d$d$d$d\-$d$d\-$d$d)$"
        [[ "$label_text" =~ $REGEX ]] && label_text="${BASH_REMATCH[1]} #1"
        d="[0-9]"; REGEX="^($d$d$d$d\-$d$d\-$d$d) \(([0]*)([1-9]$d*)\)$"
        [[ "$label_text" =~ $REGEX ]] && label_text="${BASH_REMATCH[1]} #${BASH_REMATCH[3]}"
    fi

    # Просчёт размеров текста
    twh=$(ffmpeg -loglevel debug -i "${fp_in}" -vf "drawtext=fontfile=${FONTFILE}:text='${label_text}':fontcolor=white:fontsize=${FONTSIZE}" -vframes 1 -f null - 2>&1 | grep -E -m 1 ".*Parsed_drawtext_.*text_w.*text_h.*" | sed -nE 's/.*text_w\:([0-9]+)\s+text_h\:([0-9]+).*/\1;\2/p')
    tw=$(echo "$twh" | cut -d ";" -f 1)
    th=$(echo "$twh" | cut -d ";" -f 2)

    # Вычисление размеров подложки текста
    bw=$(($tw+2*$BOXBORDERW))
    bh=$(($th+2*$BOXBORDERW))

    # Извлечение продолжительности видео
    vt=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "${fp_in}")

    # Обработка видео
    HANGING_VIDEO="${fp_out}"
    ffmpeg -v error -y -i "${fp_in}" -c:v h264_nvenc -filter_complex "
        color=c=black:s=${bw}x${bh}[pad_black];
        color=c=white:s=${bw}x${bh}[pad_white];
        [pad_black][pad_white]overlay=-w+(w/${vt})*t:H-${PROGRESS_LINE_H},format=rgba,colorchannelmixer=aa=${ALPHA_BOX}[box];
        [0:v]scale=-1:${VIDEO_HEIGHT}[v];
        [v][box]overlay=(W-${bw}-${BOX_MARGIN_RIGHT}):${BOX_MARGIN_TOP}:shortest=1,drawtext=fontfile=${FONTFILE}:text='${label_text}':fontcolor=white:alpha=${ALPHA_TEXT}:fontsize=${FONTSIZE}:x=(w-${bw}-${BOX_MARGIN_RIGHT}+${BOXBORDERW}):y=(${BOX_MARGIN_TOP}+${BOXBORDERW})
    " -qp 20 -ar 48000 "${fp_out}"
    exit_status=$?
    [[ $exit_status -eq 0 ]] && HANGING_VIDEO=""
    return $exit_status
}

# ----------------------------------------------------------------

function preprocess_videos() {
    if [[ -z "${SELECTED_FILES+set}" || ! "$(declare -p SELECTED_FILES)" =~ "declare -a" ]]; then
        custom_exit "[ERROR][preprocess_videos] SELECTED_FILES was not initialized properly!"
    fi
    output_dir="$(get_output_dir)"
    mkdir -p "${output_dir}"
    i=0; n="${#SELECTED_FILES[@]}"
    print_progress "Preprocessing videos... " "$i" "$n" 5
    for input_fp in "${SELECTED_FILES[@]}"; do
        filename=$(basename -- "$input_fp"); filename="${filename%.*}"
        output_fp="${output_dir}/${filename}.mp4"
        if [[ ! -s "$output_fp" ]]; then
            preprocess_video "$input_fp" "$output_fp"
            exit_status=$?
            [[ $exit_status -eq 130 ]] && trap_termination  # for interactive shell
            [[ $exit_status -eq 255 ]] && trap_termination  # for interactive shell
            [[ $exit_status -ne 0 ]] && custom_exit "Terminating due to the error above..."
        fi
        ((i++))
        print_progress "Preprocessing videos... " "$i" "$n" 5
    done
}

# ----------------------------------------------------------------

function concat_videos() {
    if [[ -z "${SELECTED_FILES+set}" || ! "$(declare -p SELECTED_FILES)" =~ "declare -a" ]]; then
        custom_exit "[ERROR][concat_videos] SELECTED_FILES was not initialized properly!"
    fi
    echo "Concatenating..."
    script_fn=$(basename -- "$0"); script_fn="${script_fn%.*}"
    temp_fp="${script_fn}-concat.txt"
    
    # Collecting and validating
    output_fps=()
    for input_fp in "${SELECTED_FILES[@]}"; do
        filename=$(basename -- "$input_fp"); filename="${filename%.*}"
        output_fp="$(get_output_dir)/${filename}.mp4"
        if [[ ! -s "$output_fp" ]]; then
            custom_exit "! %s\n%s" "${output_fp}" "Required file was not found! Concatenation stopped."
        fi
        output_fps+=("$output_fp")
    done
    
    # Creating auxiliary concatenation file
    exec 3> "$temp_fp"
    for fp in "${output_fps[@]}"; do
        printf "file '%s'\n" "$fp" >&3
    done
    exec 3>&-

    # Concatenation itself
    [[ -n "$OUTPUT_NAME" ]] && output_fn="$OUTPUT_NAME" || output_fn="${script_fn}-result"
    ffmpeg -v error -stats -f concat -safe 0 -i "$temp_fp" -c copy "${output_fn}.mp4"
    exit_status=$?
    
    # Finalizing
    rm -f -- "$temp_fp"
    [[ $exit_status -eq 130 ]] && trap_termination  # for interactive shell
    [[ $exit_status -eq 255 ]] && trap_termination  # for interactive shell
    [[ $exit_status -ne 0 ]] && custom_exit "Error occurred! Concatenation failed!"
    printf "\n'%s' -- %s\n" "${output_fn}.mp4" "DONE!"
}

# ----------------------------------------------------------------

trap trap_termination 1 2 3 6

function trap_termination() {
    custom_exit "Terminating..."
}

function custom_exit() {
    pfmt="$1"; shift
    [[ -n "$pfmt" ]] && printf "\n${pfmt}\n" "$@"
    [[ -n "$HANGING_VIDEO" && -f "$HANGING_VIDEO" ]] && rm -f -- "$HANGING_VIDEO"
    flush_cache
    bye
    exit 1
}

function bye() {
    # Asking to press any key - only for interactive shell
    [[ -n "$1" ]] && prompt="$1" || prompt="Press any key to exit..."
    [[ "$-" == *i* ]] && read -n 1 -s -r -p "$prompt"
}

# ----------------------------------------------------------------
