#!/bin/bash

# Input file
input_file=$1

# Get the width and height of the input image
width=$(identify -format "%w" $input_file)
height=$(identify -format "%h" $input_file)

# Calculate the square_size and target size
square_size=$((width / 2))
target_width=$((2 * square_size))
target_height=$square_size

# check if blur radius is provided
if [ -z "$2" ]; then
  blur_radius=20
else
  blur_radius=$2
fi

# Divide image into 4 squares without suffix
convert $input_file -crop 2x2@ +repage +adjoin img.png

# Resize and blur each square
for file in img-0 img-1 img-2 img-3; do
  convert $file.png -resize 200%x100% -blur 0x$blur_radius $file"_blurred.png"
done

# Overlap cropped image on blurred images
for file in img-0 img-1 img-2 img-3; do
  composite -gravity center $file.png $file"_blurred.png" $file"_final.png"
done

# Save as jpg 640px
for file in img-0 img-1 img-2 img-3; do
  convert $file"_final.png" -resize 640x320 -quality 95 $file"_final_640px.jpg"
done

# Remove blurred (temporal stage)
find . -name "img*_blurred.png" ! -name "*_final*" -type f -delete
