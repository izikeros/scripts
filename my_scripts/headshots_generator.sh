#!/bin/bash

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "ImageMagick is not installed. Please install it before running this script."
    exit 1
fi

# Input image
input_image="$1"

# Output directory
output_dir="headshots_output"
mkdir -p "$output_dir"

# Resize input image to 45x35mm @ 300dpi (portrait)
convert "$input_image" -resize 45x35 -units PixelsPerInch -density 300 -gravity center -extent 45x35 "$output_dir/resized_image.jpg"


# Create a blank canvas for the page
convert -size 1181x1772 xc:white "$output_dir/page_canvas.jpg"

# Calculate positions for headshots
padding=10
image_width=45
image_height=35
row_spacing=$(( (1772 - (2 * image_height) - (3 * padding)) / 2 ))
col_spacing=$(( (1181 - (4 * image_width) - (3 * padding)) / 3 ))

# Loop through each row and column to place headshots
for row in {0..1}; do
    for col in {0..3}; do
        x=$(( col * (image_width + col_spacing) + padding ))
        y=$(( row * (image_height + row_spacing) + padding ))
        convert "$output_dir/resized_image.jpg" -gravity center -crop 45x35+0+0 +repage -repage +${x}+${y} "$output_dir/page_canvas.jpg" -composite "$output_dir/page_canvas.jpg"
    done
done

# Add pad markings
pad_marking_color="red"
pad_marking_width=2

for ((i=0; i<=3; i++)); do
    # Horizontal lines
    convert "$output_dir/page_canvas.jpg" -fill $pad_marking_color -draw "line $((padding - pad_marking_width)),$((image_height * (i + 1) + row_spacing * i)) $((1181 - padding + pad_marking_width)),$((image_height * (i + 1) + row_spacing * i))" "$output_dir/page_canvas.jpg"

    # Vertical lines
    convert "$output_dir/page_canvas.jpg" -fill $pad_marking_color -draw "line $((image_width * (i + 1) + col_spacing * i)),$((padding - pad_marking_width)) $((image_width * (i + 1) + col_spacing * i)),$((1772 - padding + pad_marking_width))" "$output_dir/page_canvas.jpg"
done

# Save the final page of headshots
convert "$output_dir/page_canvas.jpg" "$output_dir/headshots_page.jpg"

echo "Headshots page generated successfully: $output_dir/headshots_page.jpg"
