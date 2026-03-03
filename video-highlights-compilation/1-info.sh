echo -n "" > 1-info-output.txt
for file in v-input/*.mp4; do
    # classic
    # ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Video: [^,]+, [^,]+, (\d+x\d+).*/ && print "\"", $1, "\" ", $2, "\r\n"' >> 1-info-output.txt
    
    # +extra: Duration
    # ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Duration: ([^,]+),.*Video: [^,]+, [^,]+, (\d+x\d+).*/ && print "\"", $1, "\" ", $3, " ", $2, "\r\n"' >> 1-info-output.txt
    
    # +extra: Audio Hz
    ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Video: [^,]+, [^,]+, (\d+x\d+).* (\d+) Hz.*/ && print "\"", $1, "\", ", $2, ", ", $3, " Hz", "\r\n"' >> 1-info-output.txt
done
