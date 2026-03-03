mkdir -p temp_720

# ^(\d\d\d\d\-\d\d\-\d\d) \(([0]*)([1-9]\d*)\)\.mp4$
# ffmpeg -y -i "\1 \(\2\3\).mp4" -c:v h264_nvenc -vf "scale=-1:720,drawtext=fontfile=./VCR_OSD_MONO.ttf:text='\1 #\3':fontcolor=white:fontsize=32:box=1:boxcolor=black@0.7:boxborderw=5:x=\(w-\(w*100/1920\)-text_w\):y=\(h*50/1080\):enable='between\(t,0,5\)'" -qp 20 -ar 48000 "temp_720/\1 \(\2\3\).mp4"
