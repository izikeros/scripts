#!/bin/bash

counter=0
extensions=("jpg" "jpeg" "png" "gif" "tiff" "heic" "heif")

for ext in "${extensions[@]}"; do
    shopt -s nullglob
    files=(*."$ext")
    shopt -u nullglob

    if [[ ${#files[@]} -eq 0 ]]; then
        continue
    fi

    for file in "${files[@]}"; do
        newname=$(printf "img_%03d.%s" "$counter" "$ext")
        mv "$file" "$newname"
        ((counter++))
    done
done

