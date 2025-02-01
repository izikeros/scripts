#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.9"
# dependencies = [
#     "requests",
# ]
# ///

import argparse
import json
import os

import requests


# Function to call the Whisper model API
def transcribe_audio(file_path, prompt, temperature, language, output_file):
    # Fetch API endpoint and key from environment variables
    api_endpoint = os.getenv("WHISPER_API_ENDPOINT")
    api_key = os.getenv("WHISPER_API_KEY")

    if not api_endpoint or not api_key:
        raise EnvironmentError(
            "API endpoint or API key is missing in the environment variables."
        )

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    # Prepare payload for the API call
    with open(file_path, "rb") as audio_file:
        files = {"file": audio_file}
        data = {"prompt": prompt, "temperature": temperature, "language": language}

        response = requests.post(
            api_endpoint, headers=headers, data=json.dumps(data), files=files
        )

        if response.status_code == 200:
            transcription = response.json()["text"]
            # Write output to the specified text file
            with open(output_file, "w") as f_out:
                f_out.write(transcription)
            print(f"Transcription saved to {output_file}")
        else:
            print(
                f"Failed to transcribe audio: {response.status_code} - {response.text}"
            )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Transcribe audio using Whisper API")

    # Input audio file
    parser.add_argument("file", help="Input audio file path")

    # Optional arguments
    parser.add_argument(
        "--prompt", help="Optional prompt to provide additional context", default=""
    )
    parser.add_argument(
        "--temperature",
        type=float,
        help="Set the decoding temperature (default: 0.7)",
        default=0.7,
    )
    parser.add_argument(
        "--language",
        help="Language of the transcription (e.g., 'en', 'fr')",
        default="en",
    )

    # Optional output file path
    parser.add_argument(
        "--output",
        help="Output file path. Default: same name as input with .txt extension",
    )

    args = parser.parse_args()

    # Set default output file name if not provided
    if args.output:
        output_file = args.output
    else:
        output_file = os.path.splitext(args.file)[0] + ".txt"

    # Call the transcribe function
    try:
        transcribe_audio(
            args.file, args.prompt, args.temperature, args.language, output_file
        )
    except Exception as e:
        print(f"Error: {e}")
