#!/bin/bash

# writer-init: A script to bootstrap a new Writer OS project directory

set -e

# Default core path, can be overridden by WRITER_CORE env var
WRITER_CORE="${WRITER_CORE:-$HOME/projects/priv/writer_os}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Bootstrapping Writer OS Project...${NC}"

# Check for fzf
if ! command -v fzf &> /dev/null; then
    echo -e "${RED}Error: fzf is required but not installed.${NC}"
    echo "Please install fzf (e.g., 'brew install fzf' or 'apt install fzf') and try again."
    exit 1
fi

# Ensure we're in an empty directory or one without a .writer folder
if [ -d ".writer" ] || [ -d ".factory" ]; then
    echo -e "${YELLOW}Warning: .writer or .factory already exists in this directory.${NC}"
    read -p "Do you want to overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborting."
        exit 1
    fi
    rm -rf .factory .writer
fi

# 1. Copy Core Directories
echo -e "\n${GREEN}[1/3] Copying core directories...${NC}"
if [ ! -d "$WRITER_CORE/.factory" ] || [ ! -d "$WRITER_CORE/.writer" ]; then
    echo -e "${RED}Error: Could not find .factory or .writer in $WRITER_CORE.${NC}"
    exit 1
fi

cp -r "$WRITER_CORE/.factory" .
cp -r "$WRITER_CORE/.writer" .
echo "Copied .factory and .writer"

# 2. Interactive Selection using fzf
echo -e "\n${GREEN}[2/3] Configuring project...${NC}"

select_preset() {
    local preset_type=$1
    local prompt_msg=$2
    local dest_file=$3
    local preset_dir="$WRITER_CORE/presets/$preset_type"
    
    if [ ! -d "$preset_dir" ]; then
        echo -e "${YELLOW}Preset directory $preset_dir not found. Skipping.${NC}"
        return
    fi
    
    # Add a "Skip / Blank Template" option
    local selection
    selection=$( (echo "[Skip / Blank Template]"; cd "$preset_dir" && printf '%s\n' *.md) | \
        PRESET_DIR="$preset_dir" fzf --prompt="$prompt_msg" --height=80% --layout=reverse --border \
        --preview='if [[ {} == "[Skip / Blank Template]" ]]; then echo "No preview"; else cat "$PRESET_DIR"/{}; fi' \
        --preview-window=right:60%:wrap )
    
    if [ -n "$selection" ]; then
        if [ "$selection" != "[Skip / Blank Template]" ]; then
            cp "$preset_dir/$selection" ".writer/context/$dest_file"
            echo -e "Selected $preset_type: ${BLUE}$selection${NC}"
        else
            echo -e "Selected $preset_type: ${YELLOW}Blank Template${NC}"
        fi
    else
        echo -e "Selected $preset_type: ${YELLOW}Skipped${NC}"
    fi
}

select_preset "audiences" "Select Audience: " "audience.md"
select_preset "voices" "Select Voice: " "voice.md"
select_preset "profiles" "Select Profile: " "project-profile.md"

# 3. Initialize Brief
echo -e "\n${GREEN}[3/3] Initializing brief...${NC}"
mkdir -p .writer/work/briefs
if [ -f .writer/templates/brief.template.md ]; then
    cp .writer/templates/brief.template.md .writer/work/briefs/draft.md
    echo "Created .writer/work/briefs/draft.md"
else
    echo -e "${YELLOW}Warning: brief.template.md not found. Skipping brief creation.${NC}"
fi

echo -e "\n${BLUE}======================================================================${NC}"
echo -e "${GREEN}Project Bootstrap Complete!${NC}"
echo -e "\nNext steps:"
echo -e "1. Open ${YELLOW}.writer/work/briefs/draft.md${NC} and fill in the specifics for this piece."
echo -e "2. Run Factory AI and invoke the droid (e.g. ask it to start with '/research')."
echo -e "${BLUE}======================================================================${NC}\n"
