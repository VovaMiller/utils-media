#!/bin/bash
# ----------------------------------------------------------------

INPUT_DIR='g:\Media\Games-highlights\Rainbow Six Siege'
INPUT_EXT="mp4"
OUTPUT_NAME="r6s_comp_1080"

VIDEO_HEIGHT="1080"
ALPHA_TEXT="0.7"
ALPHA_BOX="0.5"
BOX_MARGIN_RIGHT="75"
BOX_MARGIN_TOP="102"
BOXBORDERW="7"
PROGRESS_LINE_H="3"
FONTFILE="./VCR_OSD_MONO.ttf"
FONTSIZE="27"
FORMAT_LABEL="1"

# ----------------------------------------------------------------

. ./utils.sh        # 0. Importing utils
select_ge1080       # 1. Selecting input videos
preprocess_videos   # 2. Preprocessing each video
concat_videos       # 3. Concatenating all videos
bye "Press any key to finish..."

# ----------------------------------------------------------------
