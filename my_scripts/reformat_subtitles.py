#!/usr/bin/env python3

import sys

if len(sys.argv) != 2:
    print("Usage: {} input_filename".format(sys.argv[0]))
    sys.exit(1)

input_filename = sys.argv[1]

with open(input_filename, 'r') as input_file:
    input_text = input_file.read()

# Remove extra line breaks within sentences
output_text = input_text.replace('\n', ' ')

# Add line breaks after sentence end
output_text = output_text.replace('. ', '.\n')
output_text = output_text.replace('! ', '!\n')
output_text = output_text.replace('? ', '?\n')

# Write output to a new file
output_filename = input_filename + '_reformatted'
with open(output_filename, 'w') as output_file:
    output_file.write(output_text)

