mkdir -p temp_720

# ^(\d\d\d\d\-\d\d\-\d\d) \(([0]*)([1-9]\d*)\)\.mp4$
# ffmpeg -y -i "\1 \(\2\3\).mp4" -c:v h264_nvenc -vf "scale=-1:720,drawtext=fontfile=./VCR_OSD_MONO.ttf:text='\1 #\3':fontcolor=white:alpha=0.7:fontsize=20:box=1:boxcolor=black@0.5:boxborderw=5:x=\(w*50/1920\):y=\(h*50/1080\)" -qp 20 -ar 48000 "temp_720/\1 \(\2\3\).mp4"
