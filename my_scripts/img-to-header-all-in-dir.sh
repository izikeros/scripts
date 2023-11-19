#!/bin/bash

# Get all image files in the current directory
for input_file in $(ls | grep -E ".*\.(jpg|png|jpeg|gif|bmp)")
do
  echo "processing $input_file"
  # Get the width and height of the input image
  width=$(identify -format "%w" "$input_file")
  height=$(identify -format "%h" "$input_file")

  # Calculate the square_size and target size
  square_size=$((width / 2))
  target_width=$((2 * square_size))
  target_height=$square_size

  # check if blur radius is provided
  if [ -z "$1" ]; then
    blur_radius=20
  else
    blur_radius=$1
  fi

  convert "$input_file" -resize 200%x100% -blur 0x$blur_radius "$input_file"_blurred.png

  # Overlap cropped image on blurred image
  composite -gravity center "$input_file" "$input_file"_blurred.png $input_file"_final.png"

  # Save as jpg 640px
  convert "$input_file"_final.png -resize 640x320 -quality 95 $input_file"_final_640px.jpg"

  # Remove blurred (temporal stage)
  find . -name "*_blurred.png" ! -name "*_final*" -type f -delete
done

