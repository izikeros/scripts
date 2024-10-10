#!/usr/bin/env bash

sed -E 's/^[a-zA-Z0-9_]+ [0-9]+ (day|month|year)s? ago \| (root \| )?(parent \| )?(prev \| )?(next \[–])?(\[–\])?/---/' | 
sed '/^[[:space:]]*$/d' | 
sed '/^---$/d'