#!/bin/bash

# Loop through all directories in the trainings folder
for training_dir in *; do
    # Check if the Introduction folder exists
    if [ -d "${training_dir}/00. Introduction" ]; then
        # Find the first file that matches the pattern "*.mp4"
        welcome_file=$(find "${training_dir}/00. Introduction" -type f -name "*.mp4" | head -n 1)
        
        if [ -n "$welcome_file" ]; then
            # Extract frames at 10,20,30 seconds
            ffmpeg -loglevel error -y -i "$welcome_file" -ss 00:00:10 -vframes 1 "${training_dir}/poster.jpg"
            ffmpeg -loglevel error -y -i "$welcome_file" -ss 00:00:20 -vframes 1 "${training_dir}/poster1.jpg"
            ffmpeg -loglevel error -y -i "$welcome_file" -ss 00:00:30 -vframes 1 "${training_dir}/poster2.jpg"
            
            #echo "Extracted frames for $training_dir"
            #echo "saved to ${training_dir}/poster.jpg"
        else
            echo "*.mp4 not found in $training_dir"
        fi
    else
        echo "Introduction folder not found in $training_dir"
    fi
done