#!/usr/bin/env bash
# sanitizer.sh - A script to sanitize filenames by replacing diacritics and special characters.
#
# Usage:
#   ./sanitizer.sh [-f FILE] [-t FILE_TYPE] [-d] [-r] [-l] [--undo]
#
# Options:
#   -f, --file       Optional. The specific file to sanitize.
#   -t, --file-type  Optional. The type of files to sanitize. Defaults to all files (*).
#   -d, --dry-run    Optional. Display the original and sanitized filenames without renaming.
#   -r, --recursive  Optional. Process files recursively in subdirectories.
#   -l, --lower-case Optional. Convert filenames to lowercase.
#   -i,  --remove-video-id Optional. Remove video IDs in square brackets from filenames.
#   -u, --undo           Optional. Revert the changes made by the script.
#   -h, --help       Display this help message.
#
# Description:
#   This script processes files of a specified type to sanitize their filenames.
#   It replaces Polish and other diacritics with their Latin equivalents and
#   substitutes special characters with underscores. If no file or file type is provided,
#   it defaults to processing all files.
#
# Example:
#   ./sanitizer.sh -f myfile.txt
#   This will sanitize the filename of myfile.txt.
#
#   ./sanitizer.sh -t txt
#   This will sanitize the filenames of all .txt files in the current directory.
#
#   ./sanitizer.sh -d
#   This will display the original and sanitized filenames without renaming.
#
#   ./sanitizer.sh -r
#   This will process files recursively in subdirectories.
#
#   ./sanitizer.sh -l
#   This will convert filenames to lowercase.
#
#   ./sanitizer.sh --undo
#   This will revert the changes made by the script.

# disabled:
#   -s, --sentence-case Optional. Convert filenames to sentence case (first letter uppercase, rest lowercase).

show_help() {
  grep '^#' "$0" | sed 's/^#//'
}

FILE=""
FILE_TYPE="*"
DRY_RUN=false
RECURSIVE=false
LOWER_CASE=false
UNDO=false
BACKUP_FILE="filename_backup.log"
LOG_FILE="sanitizer.log"
REMOVE_VIDEO_ID=false
SENTENCE_CASE=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
  -f | --file)
    FILE="$2"
    shift 2
    ;;
  -t | --file-type)
    FILE_TYPE="$2"
    shift 2
    ;;
  -d | --dry-run)
    DRY_RUN=true
    shift
    ;;
  -r | --recursive)
    RECURSIVE=true
    shift
    ;;
  -l | --lower-case)
    LOWER_CASE=true
    shift
    ;;
#  -s | --sentence-case)
#    SENTENCE_CASE=true
#    shift
#    ;;
  -u | --undo)
    UNDO=true
    shift
    ;;
  -i | --remove-video-id)
    REMOVE_VIDEO_ID=true
    shift
    ;;
  -h | --help)
    show_help
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    show_help
    exit 1
    ;;
  esac
done

log_change() {
  local original="$1"
  local new="$2"
  echo "$original -> $new" >> "$LOG_FILE"
}

backup_filename() {
  local original="$1"
  local new="$2"
  echo "$original,$new" >> "$BACKUP_FILE"
}

undo_changes() {
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "No backup file found. Cannot undo changes."
    exit 1
  fi

  while IFS=, read -r original new; do
    if [ -f "$new" ]; then
      mv "$new" "$original"
      echo "Reverted: $new -> $original"
    fi
  done < "$BACKUP_FILE"

  rm -f "$BACKUP_FILE"
  rm -f "$LOG_FILE"
  exit 0
}

sanitize_file_perl() {
  local f="$1"
  local nf
  nf=$(echo "$f" | perl -CSD -MMIME::Base64 -pe '
   use utf8;
  use open ":std", ":encoding(UTF-8)";

  # Polish specific
  s/ł/l/g;
  s/Ł/L/g;
  s/ś/s/g;
  s/Ś/S/g;
  s/ć/c/g;
  s/Ć/C/g;
  s/ź/z/g;
  s/Ź/Z/g;
  s/ż/z/g;
  s/Ż/Z/g;
  s/ó/o/g;
  s/Ó/O/g;
  s/ą/a/g;
  s/Ą/A/g;
  s/ę/e/g;
  s/Ę/E/g;
  s/ń/n/g;
  s/Ń/N/g;

  # German
  s/ä/a/g;
  s/Ä/A/g;
  s/ö/o/g;
  s/Ö/O/g;
  s/ü/u/g;
  s/Ü/U/g;
  s/ß/ss/g;

  # Spanish & Portuguese
  s/[áàã]/a/g;
  s/[ÁÀÃ]/A/g;
  s/[éèẽ]/e/g;
  s/[ÉÈẼ]/E/g;
  s/[íìĩ]/i/g;
  s/[ÍÌĨ]/I/g;
  s/[óòõ]/o/g;
  s/[ÓÒÕ]/O/g;
  s/[úùũ]/u/g;
  s/[ÚÙŨ]/U/g;
  s/[ýỳỹ]/y/g;
  s/[ÝỲỸ]/Y/g;
  s/ñ/n/g;
  s/Ñ/N/g;
  s/ç/c/g;
  s/Ç/C/g;

  # Romanian
  s/ă/a/g;
  s/Ă/A/g;
  s/â/a/g;
  s/Â/A/g;
  s/î/i/g;
  s/Î/I/g;
  s/ș/s/g;
  s/Ș/S/g;
  s/ț/t/g;
  s/Ț/T/g;

  # Fallback for any remaining diacritics
  s/[\x{0300}-\x{036F}]//g;
  ')
  # Remove video ID in square brackets if enabled
  if [ "$REMOVE_VIDEO_ID" = true ]; then
    nf=$(echo "$nf" | perl -pe 's/\s*\[[A-Za-z0-9_-]{11}\](?=\.[^.]+$)//g')
  fi

  # Apply case transformations after other sanitizations
  if [ "$LOWER_CASE" = true ]; then
    nf=$(echo "$nf" | tr '[:upper:]' '[:lower:]')
#  elif [ "$SENTENCE_CASE" = true ]; then
#    # Convert to lowercase first, then capitalize first letter of the filename
#    nf=$(echo "$nf" | tr '[:upper:]' '[:lower:]' | sed -e 's/\(^\|[^a-zA-Z]\)\([a-z]\)/\1\u\2/g')
  fi

  # Substitute special characters with underscores, make sure that there is no extra underscore added in the end of the string
  nf=$(echo "$nf" | sed -e 's/[^A-Za-z0-9/._-]/_/g' | sed -e 's/_$//g')

  # Remove multiple underscores (replace with single underscore), use perl for this
  nf=$(echo "$nf" | perl -pe 's/_+/_/g')

  # replace '-_' with '-'
  nf=$(echo "$nf" | sed -e 's/-_/-/g')

  # replace '_-' with '-'
  nf=$(echo "$nf" | sed -e 's/_-/-/g')

  # replace '._' with '.'
  nf=$(echo "$nf" | sed -e 's/\._/\./g')

  # replace '_.' with '.'
  nf=$(echo "$nf" | sed -e 's/_\./\./g')

  # replace '..' with '.'
  nf=$(echo "$nf" | sed -e 's/\.\./\./g')



  if [ "$DRY_RUN" = true ]; then
    echo " Original: $f"
    echo "Sanitized: $nf"
  else
    mv "$f" "$nf"
    log_change "$f" "$nf"
    backup_filename "$f" "$nf"
  fi
}

sanitize() {
  local f="$1"
  sanitize_file_perl "$f"
}

if [ "$UNDO" = true ]; then
  undo_changes
fi

if [ -n "$FILE" ]; then
  sanitize "$FILE"
else
  if [ "$RECURSIVE" = true ]; then
    find . -type f -iname "*.$FILE_TYPE" | while read -r f; do
      # avoid having error message:
      # mv: . and ./. are identical
      if [ "$f" = "." ] || [ "$f" = "./." ]; then
        continue
      fi
      echo "$f"
      sanitize "$f"
    done
  else
    find . -maxdepth 1 -type f -iname "*.$FILE_TYPE" | while read -r f; do
      # avoid having error message:
      # mv: . and ./. are identical
      if [ "$f" = "." ] || [ "$f" = "./." ]; then
        continue
      fi
      echo "$f"
      sanitize "$f"
    done
  fi
fi
