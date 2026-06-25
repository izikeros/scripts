#!/bin/bash
# the script splits an MP3 file into segments of specified duration using ffmpeg
# each segment length is defined in minutes, and the output files are named with a specified prefix followed by a segment number.
# example usage: ./mp3splitter.sh input.mp3 30 segment
# this will split input.mp3 into 30-minute segments named segment_000.mp3, segment_001.mp3, etc.

# Check if input file is provided
if [ $# -lt 1 ]; then
    echo "Usage: $0 input.mp3 [duration_minutes] [output_prefix]"
    echo "  duration_minutes: segment length in minutes (default: 30)"
    echo "  output_prefix: prefix for output files (default: segment)"
    exit 1
fi

INPUT_FILE="$1"
DURATION_MINUTES="${2:-30}"
OUTPUT_PREFIX="${3:-segment}"

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Convert minutes to seconds
DURATION_SECONDS=$((DURATION_MINUTES * 60))

# Cut the MP3 into segments of specified duration
ffmpeg -i "$INPUT_FILE" -f segment -segment_time $DURATION_SECONDS -c copy "${OUTPUT_PREFIX}_%03d.mp3"

echo "Finished splitting '$INPUT_FILE' into ${DURATION_MINUTES}-minute segments."
