
echo -n "" > 3-concat-1080-temp.txt
for file in v-output-1080/*.mp4; do
    echo "file '${file}'" >> 3-concat-1080-temp.txt
done

ffmpeg -f concat -safe 0 -i "3-concat-1080-temp.txt" -c copy "r6s_comp_1080.mp4"
