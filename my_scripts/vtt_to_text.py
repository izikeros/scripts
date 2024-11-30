#!/usr/env python3

import re
import sys

def extract_text_from_vtt(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            vtt_content = file.read()
        
        # Remove header lines
        lines = vtt_content.split('\n')[4:]
        
        # Join lines into a single string
        text = ' '.join(lines)
        
        # Remove timestamps and positioning info
        text = re.sub(r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}.*?', '', text)
        
        # Remove HTML-like tags
        text = re.sub(r'<.*?>', '', text)
        
        # Remove multiple spaces and newlines
        text = re.sub(r'\s+', ' ', text).strip()
        
        return text
    except FileNotFoundError:
        return f"Error: File not found at {file_path}"
    except Exception as e:
        return f"An error occurred: {str(e)}"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script_name.py <path_to_vtt_file>")
    else:
        file_path = sys.argv[1]
        extracted_text = extract_text_from_vtt(file_path)
        print(extracted_text)