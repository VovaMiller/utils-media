#!/bin/bash
# ----------------------------------------------------------------

INPUT_DIR=".."
INPUT_EXT="mp4"
OUTPUT_SEP=", "

# ----------------------------------------------------------------

function print_progress() {
    prefix="$1" current=$2; total=$3; step_p=$4
    [[ -z $current || -z $total || -z $step_p ]] && return -1
    [[ $current -lt 0 ]] && return -1
    [[ $current -gt $total ]] && return -1
    [[ $step_p -le 0 || $step_p -gt 100 ]] && return -1
    step=$((total*step_p/100)); [[ $step -eq 0 ]] && step=1
    if [[ $((current%step)) -eq 0 || $current -eq $total ]]; then
        width=40
        width_fill=$((width*current/total))
        width_none=$((width-width_fill))
        [[ $width_fill -gt 0 ]] && str_fill="$(printf -- '█%0.s' $(seq 1 $width_fill))" || str_fill=""
        [[ $width_none -gt 0 ]] && str_none="$(printf -- ' %0.s' $(seq 1 $width_none))" || str_none=""
        # percentage=$((100*current/total))
        # percentage=$(((10*100*current/total + 5)/10)); [[ $percentage -eq 100 && $current -lt $total ]] && percentage=99
        percentage=$(((100*current + total - 1)/total)); [[ $percentage -eq 100 && $current -lt $total ]] && percentage=99
        [[ ${#percentage} -lt 3 ]] && offset_1="$(printf -- ' %0.s' $(seq 1 "$((3-${#percentage}))"))" || offset_1=""
        [[ ${#current} -lt ${#total} ]] && offset_2="$(printf -- ' %0.s' $(seq 1 "$((${#total}-${#current}))"))" || offset_2=""
        echo "${prefix}${offset_1}${percentage}%|${str_fill}${str_none}| ${offset_2}${current}/${total}"
    fi
}

function bye() {
    # Asking to press any key - only for interactive shell
    [[ -n "$1" ]] && prompt="$1" || prompt="Press any key to exit..."
    [[ "$-" == *i* ]] && read -n 1 -s -r -p "$prompt"
}

# ----------------------------------------------------------------

if [[ ! -d "$INPUT_DIR" ]]; then
    echo "Directory '${INPUT_DIR}' doesn't exist!"
    bye "Press any key to exit..."
    exit 1
fi
INPUT_RP="$(realpath "${INPUT_DIR}" | cygpath -u -f -)"

SH_BN=$(basename -- "$0")
SH_FN="${SH_BN%.*}"
OUT_BN="${SH_FN}-$(date +"%Y-%m-%d-%H%M%S").txt"

INPUT_CNT=0
for file in "${INPUT_RP}"/*."${INPUT_EXT}"; do
    ((INPUT_CNT++))
done

exec 3> "$OUT_BN"
printf "%s\n" "${INPUT_RP}/*.${INPUT_EXT}" >&3
i=0
print_progress "Extracting info... " "$i" "$INPUT_CNT" 5
for file in "${INPUT_RP}"/*."${INPUT_EXT}"; do
    FFPROBE=$(ffprobe -i "$file" 2>&1)
    
    # 1. Filepath
    v1_filepath="'$(basename -- "$file")'"
    
    # 2. Resolution
    REGEX=$'Stream #0[^\n]+Video:[^\n]+[^0-9]([0-9]+x[0-9]+)[^0-9]'
    [[ "$FFPROBE" =~ $REGEX ]] && v2_resolution="${BASH_REMATCH[1]}" || v2_resolution="____x____"

    # 3. Duration
    REGEX=$'Duration: ([0-9:.]+),'
    [[ "$FFPROBE" =~ $REGEX ]] && v3_duration="${BASH_REMATCH[1]}" || v3_duration="__:__:__.__"
    
    # 4. Audio Hz
    REGEX=$'Stream #0[^\n]+Audio:[^\n]+[^0-9]([0-9]+ Hz)'
    [[ "$FFPROBE" =~ $REGEX ]] && v4_hz="${BASH_REMATCH[1]}" || v4_hz="_____ Hz"

    s="${OUTPUT_SEP}"
    printf "%s$s%s$s%s$s%s\n" "$v1_filepath" "$v2_resolution" "$v3_duration" "$v4_hz" >&3
    
    ((i++))
    print_progress "Extracting info... " "$i" "$INPUT_CNT" 5
done
exec 3>&-

bye "Press any key to finish..."

# ----------------------------------------------------------------
