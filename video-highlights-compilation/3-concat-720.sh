
echo -n "" > 3-concat-720-temp.txt
for file in v-output-720/*.mp4; do
    echo "file '${file}'" >> 3-concat-720-temp.txt
done

ffmpeg -f concat -safe 0 -i "3-concat-720-temp.txt" -c copy "r6s_comp_720.mp4"
