#!/bin/bash
# ----------------------------------------------------------------

INPUT_DIR='g:\Media\Games-highlights\Rainbow Six Siege'
INPUT_EXT="mp4"
OUTPUT_NAME="r6s_comp_720"

VIDEO_HEIGHT="720"
ALPHA_TEXT="0.7"
ALPHA_BOX="0.5"
BOX_MARGIN_RIGHT="49"
BOX_MARGIN_TOP="68"
BOXBORDERW="5"
PROGRESS_LINE_H="2"
FONTFILE="./VCR_OSD_MONO.ttf"
FONTSIZE="18"
FORMAT_LABEL="1"

# ----------------------------------------------------------------

. ./utils.sh        # 0. Importing utils
select_lt1080       # 1. Selecting input videos
preprocess_videos   # 2. Preprocessing each video
concat_videos       # 3. Concatenating all videos
bye "Press any key to finish..."

# ----------------------------------------------------------------
