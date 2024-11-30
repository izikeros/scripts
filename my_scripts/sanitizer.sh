#!/usr/bin/env bash
# sanitizer.sh - A script to sanitize filenames by replacing diacritics and special characters.
#
# Usage:
#   ./sanitizer.sh [-f FILE] [-t FILE_TYPE] [-d] [-p]
#
# Options:
#   -f, --file       Optional. The specific file to sanitize.
#   -t, --file-type  Optional. The type of files to sanitize. Defaults to all files (*).
#   -d, --dry-run    Optional. Display the original and sanitized filenames without renaming.
#   -p, --perl       Optional. Use Perl for sanitization.
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
#   ./sanitizer.sh -p
#   This will use Perl for sanitization.

show_help() {
  grep '^#' "$0" | sed 's/^#//'
}

FILE=""
FILE_TYPE="*"
DRY_RUN=false
USE_PERL=false

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
  -p | --perl)
    USE_PERL=true
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

sanitize_file() {
  local f="$1"
  local nf
  nf=$(echo "$f" | iconv -f utf-8 -t ascii//TRANSLIT | iconv -f windows-1250 -t ascii//TRANSLIT | sed -e 's/[^A-Za-z0-9/._-]/_/g')
  if [ "$DRY_RUN" = true ]; then
    echo "Original: $f"
    echo "Sanitized: $nf"
  else
    mv "$f" "$nf"
  fi
}

sanitize_file_perl() {
  # perl -CSD -MMIME::Base64 -pe '
  # use utf8;
  # use open ":std", ":encoding(UTF-8)";

  # # Polish specific
  # s/ł/l/g;
  # s/Ł/L/g;
  # s/ś/s/g;
  # s/Ś/S/g;
  # s/ć/c/g;
  # s/Ć/C/g;
  # s/ź/z/g;
  # s/Ź/Z/g;
  # s/ż/z/g;
  # s/Ż/Z/g;
  # s/ó/o/g;
  # s/Ó/O/g;
  # s/ą/a/g;
  # s/Ą/A/g;
  # s/ę/e/g;
  # s/Ę/E/g;
  # s/ń/n/g;
  # s/Ń/N/g;

  # # German
  # s/ä/a/g;
  # s/Ä/A/g;
  # s/ö/o/g;
  # s/Ö/O/g;
  # s/ü/u/g;
  # s/Ü/U/g;
  # s/ß/ss/g;

  # # Spanish & Portuguese
  # s/[áàã]/a/g;
  # s/[ÁÀÃ]/A/g;
  # s/[éèẽ]/e/g;
  # s/[ÉÈẼ]/E/g;
  # s/[íìĩ]/i/g;
  # s/[ÍÌĨ]/I/g;
  # s/[óòõ]/o/g;
  # s/[ÓÒÕ]/O/g;
  # s/[úùũ]/u/g;
  # s/[ÚÙŨ]/U/g;
  # s/[ýỳỹ]/y/g;
  # s/[ÝỲỸ]/Y/g;
  # s/ñ/n/g;
  # s/Ñ/N/g;
  # s/ç/c/g;
  # s/Ç/C/g;

  # # Romanian
  # s/ă/a/g;
  # s/Ă/A/g;
  # s/â/a/g;
  # s/Â/A/g;
  # s/î/i/g;
  # s/Î/I/g;
  # s/ș/s/g;
  # s/Ș/S/g;
  # s/ț/t/g;
  # s/Ț/T/g;

  # # Fallback for any remaining diacritics
  # s/[\x{0300}-\x{036F}]//g;
  # '
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
    echo "Original: $f"
    echo "Sanitized: $nf"
  else
    mv "$f" "$nf"
  fi
}

sanitize() {
  local f="$1"
  if [ "$USE_PERL" = true ]; then
    sanitize_file_perl "$f"
  else
    sanitize_file "$f"
  fi
}

if [ -n "$FILE" ]; then
  sanitize "$FILE"
else
  find . -iname "*.$FILE_TYPE" | while read -r f; do
    # avoid having error message:
    # mv: . and ./. are identical
    if [ "$f" = "." ] || [ "$f" = "./." ]; then
      continue
    fi
    echo "$f"
    sanitize "$f"
  done
fi
