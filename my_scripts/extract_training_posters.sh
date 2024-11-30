#!/bin/bash

# Function to extract frames from a video
extract_frames() {
    local video="$1"
    local output_dir="$(dirname "$video")"
    
    ffmpeg -i "$video" -vf "select='eq(n,240)+eq(n,480)+eq(n,720)'" -vsync 0 "$output_dir/poster%d.jpg"
}

# Find all Welcome.mp4 files in the trainings directory
find trainings -name "Welcome.mp4" | while read -r video; do
    echo "Processing: $video"
    extract_frames "$video"
done