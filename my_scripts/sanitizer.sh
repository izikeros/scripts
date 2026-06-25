#!/usr/bin/env bash
# sanitizer.sh - A script to sanitize filenames by replacing diacritics and special characters.
#
# Usage:
#   ./sanitizer.sh [-f FILE] [-t FILE_TYPE] [-d] [-r] [-l] [--undo [SESSION_ID]]
#
# Options:
#   -f, --file       Optional. The specific file to sanitize.
#   -t, --file-type  Optional. The type of files to sanitize. Defaults to all files (*).
#   -d, --dry-run    Optional. Display the original and sanitized filenames without renaming.
#   -r, --recursive  Optional. Process files recursively in subdirectories.
#   -l, --lower-case Optional. Convert filenames to lowercase.
#   -i, --remove-video-id Optional. Remove video IDs in square brackets from filenames.
#   -u, --undo [ID]  Optional. Revert changes. If ID provided, revert that session; otherwise latest.
#   --list           List sessions for current directory.
#   --list-all       List all sessions across all directories.
#   --show ID        Show details of a specific session.
#   --clean [--days N] Remove sessions older than N days (default: 30).
#   -h, --help       Display this help message.
#
# Description:
#   This script processes files of a specified type to sanitize their filenames.
#   It replaces Polish and other diacritics with their Latin equivalents and
#   substitutes special characters with underscores. If no file or file type is provided,
#   it defaults to processing all files.
#
#   Sessions are stored in ~/.sanitizer/sessions/ organized by working directory.
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
#   This will revert the most recent session for current directory.
#
#   ./sanitizer.sh --undo 20260116_143022_a1b2c3
#   This will revert the specified session.
#
#   ./sanitizer.sh --list
#   This will list all sessions for the current directory.

show_help() {
  grep '^#' "$0" | sed 's/^#//'
}

# Session management configuration
SANITIZER_HOME="${HOME}/.sanitizer"
SESSIONS_DIR="${SANITIZER_HOME}/sessions"

# Ensure session directories exist
mkdir -p "$SESSIONS_DIR"

# Current session variables (set during sanitization)
CURRENT_SESSION_ID=""
CURRENT_SESSION_DIR=""

FILE=""
FILE_TYPE="*"
DRY_RUN=false
RECURSIVE=false
LOWER_CASE=false
UNDO=false
UNDO_SESSION_ID=""
REMOVE_VIDEO_ID=false
LIST_SESSIONS=false
LIST_ALL_SESSIONS=false
SHOW_SESSION=""
CLEAN_SESSIONS=false
CLEAN_DAYS=30
FILES_PROCESSED=0

# Generate a hash for the working directory
get_dir_hash() {
  local dir="$1"
  echo -n "$dir" | md5 | cut -c1-12
}

# Generate a unique session ID
generate_session_id() {
  local timestamp
  timestamp=$(date +%Y%m%d_%H%M%S)
  local random_suffix
  random_suffix=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 6)
  echo "${timestamp}_${random_suffix}"
}

# Create a new session
create_session() {
  local working_dir
  working_dir=$(pwd)
  local dir_hash
  dir_hash=$(get_dir_hash "$working_dir")
  
  CURRENT_SESSION_ID=$(generate_session_id)
  CURRENT_SESSION_DIR="${SESSIONS_DIR}/${dir_hash}/${CURRENT_SESSION_ID}"
  
  mkdir -p "$CURRENT_SESSION_DIR"
  
  # Create metadata file
  local options_str=""
  [ "$RECURSIVE" = true ] && options_str="${options_str}-r "
  [ "$LOWER_CASE" = true ] && options_str="${options_str}-l "
  [ "$REMOVE_VIDEO_ID" = true ] && options_str="${options_str}-i "
  [ -n "$FILE" ] && options_str="${options_str}-f $FILE "
  [ "$FILE_TYPE" != "*" ] && options_str="${options_str}-t $FILE_TYPE "
  
  cat > "${CURRENT_SESSION_DIR}/metadata.json" << EOF
{
  "session_id": "${CURRENT_SESSION_ID}",
  "working_dir": "${working_dir}",
  "dir_hash": "${dir_hash}",
  "timestamp": "$(date -Iseconds)",
  "options": "${options_str}",
  "files_count": 0
}
EOF
  
  # Initialize backup and log files
  touch "${CURRENT_SESSION_DIR}/backup.log"
  touch "${CURRENT_SESSION_DIR}/changes.log"
  
  echo "Session created: $CURRENT_SESSION_ID"
}

# Update session metadata with file count
update_session_metadata() {
  local count="$1"
  local metadata_file="${CURRENT_SESSION_DIR}/metadata.json"
  
  if [ -f "$metadata_file" ]; then
    # Update files_count in metadata
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/\"files_count\": [0-9]*/\"files_count\": $count/" "$metadata_file"
    else
      sed -i "s/\"files_count\": [0-9]*/\"files_count\": $count/" "$metadata_file"
    fi
  fi
}

# Find session by ID (searches all directories)
find_session() {
  local session_id="$1"
  local session_path=""
  
  while IFS= read -r -d '' dir; do
    if [ -d "$dir/$session_id" ]; then
      session_path="$dir/$session_id"
      break
    fi
  done < <(find "$SESSIONS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
  
  echo "$session_path"
}

# Get latest session for current directory
get_latest_session() {
  local working_dir
  working_dir=$(pwd)
  local dir_hash
  dir_hash=$(get_dir_hash "$working_dir")
  local dir_sessions="${SESSIONS_DIR}/${dir_hash}"
  
  if [ -d "$dir_sessions" ]; then
    # Get the most recent session (sorted by name which includes timestamp)
    ls -1 "$dir_sessions" 2>/dev/null | sort -r | head -1
  fi
}

# List sessions for current directory
list_sessions() {
  local working_dir
  working_dir=$(pwd)
  local dir_hash
  dir_hash=$(get_dir_hash "$working_dir")
  local dir_sessions="${SESSIONS_DIR}/${dir_hash}"
  
  echo "Sessions for: $working_dir"
  echo ""
  
  if [ ! -d "$dir_sessions" ] || [ -z "$(ls -A "$dir_sessions" 2>/dev/null)" ]; then
    echo "  No sessions found."
    return
  fi
  
  printf "  %-24s %-20s %-7s %s\n" "ID" "DATE" "FILES" "OPTIONS"
  printf "  %-24s %-20s %-7s %s\n" "------------------------" "--------------------" "-------" "-------"
  
  for session_dir in "$dir_sessions"/*; do
    if [ -d "$session_dir" ]; then
      local session_id
      session_id=$(basename "$session_dir")
      local metadata_file="${session_dir}/metadata.json"
      
      if [ -f "$metadata_file" ]; then
        local timestamp files_count options
        timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4 | cut -dT -f1,2 | tr 'T' ' ' | cut -c1-19)
        files_count=$(grep '"files_count"' "$metadata_file" | grep -o '[0-9]*')
        options=$(grep '"options"' "$metadata_file" | cut -d'"' -f4)
        
        printf "  %-24s %-20s %-7s %s\n" "$session_id" "$timestamp" "$files_count" "$options"
      fi
    fi
  done
}

# List all sessions across all directories
list_all_sessions() {
  echo "All sanitizer sessions:"
  echo ""
  
  if [ ! -d "$SESSIONS_DIR" ] || [ -z "$(ls -A "$SESSIONS_DIR" 2>/dev/null)" ]; then
    echo "  No sessions found."
    return
  fi
  
  for dir_hash_dir in "$SESSIONS_DIR"/*; do
    if [ -d "$dir_hash_dir" ]; then
      for session_dir in "$dir_hash_dir"/*; do
        if [ -d "$session_dir" ]; then
          local session_id
          session_id=$(basename "$session_dir")
          local metadata_file="${session_dir}/metadata.json"
          
          if [ -f "$metadata_file" ]; then
            local working_dir timestamp files_count options
            working_dir=$(grep '"working_dir"' "$metadata_file" | cut -d'"' -f4)
            timestamp=$(grep '"timestamp"' "$metadata_file" | cut -d'"' -f4 | cut -dT -f1,2 | tr 'T' ' ' | cut -c1-19)
            files_count=$(grep '"files_count"' "$metadata_file" | grep -o '[0-9]*')
            options=$(grep '"options"' "$metadata_file" | cut -d'"' -f4)
            
            echo "  Session: $session_id"
            echo "    Dir:     $working_dir"
            echo "    Date:    $timestamp"
            echo "    Files:   $files_count"
            echo "    Options: $options"
            echo ""
          fi
        fi
      done
    fi
  done
}

# Show details of a specific session
show_session() {
  local session_id="$1"
  local session_path
  session_path=$(find_session "$session_id")
  
  if [ -z "$session_path" ] || [ ! -d "$session_path" ]; then
    echo "Session not found: $session_id"
    exit 1
  fi
  
  local metadata_file="${session_path}/metadata.json"
  local backup_file="${session_path}/backup.log"
  
  echo "Session: $session_id"
  echo ""
  
  if [ -f "$metadata_file" ]; then
    echo "Metadata:"
    cat "$metadata_file" | sed 's/^/  /'
    echo ""
  fi
  
  if [ -f "$backup_file" ] && [ -s "$backup_file" ]; then
    echo "Changes:"
    while IFS=, read -r original new; do
      echo "  $original -> $new"
    done < "$backup_file"
  else
    echo "No changes recorded."
  fi
}

# Clean up old sessions
cleanup_sessions() {
  local days="$1"
  local cutoff_date
  cutoff_date=$(date -v-${days}d +%Y%m%d 2>/dev/null || date -d "$days days ago" +%Y%m%d)
  local removed=0
  
  echo "Removing sessions older than $days days (before $cutoff_date)..."
  
  for dir_hash_dir in "$SESSIONS_DIR"/*; do
    if [ -d "$dir_hash_dir" ]; then
      for session_dir in "$dir_hash_dir"/*; do
        if [ -d "$session_dir" ]; then
          local session_id
          session_id=$(basename "$session_dir")
          # Extract date from session ID (format: YYYYMMDD_HHMMSS_random)
          local session_date
          session_date=$(echo "$session_id" | cut -d'_' -f1)
          
          if [ "$session_date" -lt "$cutoff_date" ] 2>/dev/null; then
            rm -rf "$session_dir"
            echo "  Removed: $session_id"
            ((removed++))
          fi
        fi
      done
      
      # Remove empty directory hashes
      if [ -z "$(ls -A "$dir_hash_dir" 2>/dev/null)" ]; then
        rmdir "$dir_hash_dir"
      fi
    fi
  done
  
  echo "Removed $removed session(s)."
}

log_change() {
  local original="$1"
  local new="$2"
  if [ -n "$CURRENT_SESSION_DIR" ]; then
    echo "$original -> $new" >> "${CURRENT_SESSION_DIR}/changes.log"
  fi
}

backup_filename() {
  local original="$1"
  local new="$2"
  if [ -n "$CURRENT_SESSION_DIR" ]; then
    echo "$original,$new" >> "${CURRENT_SESSION_DIR}/backup.log"
  fi
}

undo_changes() {
  local session_id="$1"
  local session_path=""
  local backup_file=""
  
  # If no session ID provided, try to find the latest for current directory
  if [ -z "$session_id" ]; then
    # First check for legacy local backup file
    if [ -f "filename_backup.log" ]; then
      echo "Found legacy backup file in current directory."
      backup_file="filename_backup.log"
    else
      session_id=$(get_latest_session)
      if [ -z "$session_id" ]; then
        echo "No sessions found for current directory."
        exit 1
      fi
      echo "Using latest session: $session_id"
    fi
  fi
  
  # If we have a session ID, find the session path
  if [ -n "$session_id" ] && [ -z "$backup_file" ]; then
    session_path=$(find_session "$session_id")
    
    if [ -z "$session_path" ] || [ ! -d "$session_path" ]; then
      # Try current directory hash
      local working_dir
      working_dir=$(pwd)
      local dir_hash
      dir_hash=$(get_dir_hash "$working_dir")
      session_path="${SESSIONS_DIR}/${dir_hash}/${session_id}"
    fi
    
    if [ ! -d "$session_path" ]; then
      echo "Session not found: $session_id"
      exit 1
    fi
    
    backup_file="${session_path}/backup.log"
  fi
  
  if [ ! -f "$backup_file" ]; then
    echo "No backup file found. Cannot undo changes."
    exit 1
  fi
  
  echo "Reverting session${session_id:+: $session_id}..."
  
  local reverted=0
  while IFS=, read -r original new; do
    if [ -f "$new" ]; then
      mv "$new" "$original"
      echo "  Reverted: $new -> $original"
      ((reverted++))
    else
      echo "  Skipped (not found): $new"
    fi
  done < "$backup_file"
  
  echo "Session reverted successfully ($reverted files restored)."
  
  # Clean up session directory if it was a session-based undo
  if [ -n "$session_path" ] && [ -d "$session_path" ]; then
    rm -rf "$session_path"
    echo "Session removed."
  elif [ -f "filename_backup.log" ]; then
    rm -f "filename_backup.log"
    rm -f "sanitizer.log"
  fi
  
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
    if [ "$f" != "$nf" ]; then
      mv "$f" "$nf"
      log_change "$f" "$nf"
      backup_filename "$f" "$nf"
      ((FILES_PROCESSED++))
    fi
  fi
}

sanitize() {
  local f="$1"
  sanitize_file_perl "$f"
}

# Parse arguments
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
  -u | --undo)
    UNDO=true
    # Check if next argument is a session ID (not another flag)
    if [[ -n "$2" && ! "$2" =~ ^- ]]; then
      UNDO_SESSION_ID="$2"
      shift
    fi
    shift
    ;;
  -i | --remove-video-id)
    REMOVE_VIDEO_ID=true
    shift
    ;;
  --list)
    LIST_SESSIONS=true
    shift
    ;;
  --list-all)
    LIST_ALL_SESSIONS=true
    shift
    ;;
  --show)
    SHOW_SESSION="$2"
    shift 2
    ;;
  --clean)
    CLEAN_SESSIONS=true
    # Check for --days option
    if [[ "$2" == "--days" && -n "$3" ]]; then
      CLEAN_DAYS="$3"
      shift 2
    fi
    shift
    ;;
  --days)
    CLEAN_DAYS="$2"
    shift 2
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

# Handle session management commands
if [ "$LIST_SESSIONS" = true ]; then
  list_sessions
  exit 0
fi

if [ "$LIST_ALL_SESSIONS" = true ]; then
  list_all_sessions
  exit 0
fi

if [ -n "$SHOW_SESSION" ]; then
  show_session "$SHOW_SESSION"
  exit 0
fi

if [ "$CLEAN_SESSIONS" = true ]; then
  cleanup_sessions "$CLEAN_DAYS"
  exit 0
fi

if [ "$UNDO" = true ]; then
  undo_changes "$UNDO_SESSION_ID"
fi

# Create session for this sanitization run (unless dry run)
if [ "$DRY_RUN" = false ]; then
  create_session
fi

if [ -n "$FILE" ]; then
  sanitize "$FILE"
else
  if [ "$RECURSIVE" = true ]; then
    find . -type f -iname "*.$FILE_TYPE" | while read -r f; do
      if [ "$f" = "." ] || [ "$f" = "./." ]; then
        continue
      fi
      echo "$f"
      sanitize "$f"
    done
  else
    find . -maxdepth 1 -type f -iname "*.$FILE_TYPE" | while read -r f; do
      if [ "$f" = "." ] || [ "$f" = "./." ]; then
        continue
      fi
      echo "$f"
      sanitize "$f"
    done
  fi
fi

# Update session metadata with final file count
if [ "$DRY_RUN" = false ] && [ -n "$CURRENT_SESSION_DIR" ]; then
  # Count actual changes from backup file
  if [ -f "${CURRENT_SESSION_DIR}/backup.log" ]; then
    FILES_PROCESSED=$(wc -l < "${CURRENT_SESSION_DIR}/backup.log" | tr -d ' ')
  fi
  update_session_metadata "$FILES_PROCESSED"
  
  if [ "$FILES_PROCESSED" -eq 0 ]; then
    echo "No files were changed."
    rm -rf "$CURRENT_SESSION_DIR"
  else
    echo ""
    echo "Session complete: $CURRENT_SESSION_ID ($FILES_PROCESSED files)"
    echo "To undo: sanitizer.sh --undo $CURRENT_SESSION_ID"
  fi
fi
