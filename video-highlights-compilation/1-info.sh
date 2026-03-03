echo -n "" > info.txt
for file in *.mp4; do
    # classic
    # ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Video: [^,]+, [^,]+, (\d+x\d+).*/ && print "\"", $1, "\" ", $2, "\r\n"' >> info.txt
    
    # +extra: Duration
    # ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Duration: ([^,]+),.*Video: [^,]+, [^,]+, (\d+x\d+).*/ && print "\"", $1, "\" ", $3, " ", $2, "\r\n"' >> info.txt
    
    # +extra: Audio Hz
    ffprobe -i "$file" 2>&1 | tr -d "\r\n" | perl -n -e '/.* from '\''([^'\'']+)'\''.*Video: [^,]+, [^,]+, (\d+x\d+).* (\d+) Hz.*/ && print "\"", $1, "\", ", $2, ", ", $3, " Hz", "\r\n"' >> info.txt
done
