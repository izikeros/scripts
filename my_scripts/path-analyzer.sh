#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Error handling
set -o errexit
set -o pipefail

# Check for FZF availability
check_fzf() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: fzf is not installed. Some features will be disabled.${NC}"
        echo "Install fzf for enhanced functionality."
        return 1
    fi
    return 0
}

# Basic function to display PATH entries one per line
display_path() {
    echo -e "${BLUE}Your PATH entries:${NC}"
    echo "$PATH" | tr ':' '\n' | nl
}

# Enhanced function with color and validation
display_path_enhanced() {
    echo -e "${BLUE}Analyzing your PATH entries:${NC}"
    echo
    
    IFS=':' read -ra PATH_ARRAY <<< "$PATH"
    
    for index in "${!PATH_ARRAY[@]}"; do
        dir="${PATH_ARRAY[$index]}"
        
        if [ -d "$dir" ]; then
            echo -e "${GREEN}✓${NC} [$((index+1))] $dir"
            check_permissions "$dir"
            count_executables "$dir"
        else
            echo -e "${RED}✗${NC} [$((index+1))] $dir (Directory doesn't exist)"
        fi
        echo
    done
}

# Permission analysis
check_permissions() {
    local dir="$1"
    echo -n "   Permissions: "
    if [ -r "$dir" ]; then
        echo -n "r"
    else
        echo -n "-"
    fi
    if [ -w "$dir" ]; then
        echo -n "w"
    else
        echo -n "-"
    fi
    if [ -x "$dir" ]; then
        echo "x"
    else
        echo "-"
    fi
    
    # Check for world-writable directories
    if [ -w "$dir" ] && [ "$(stat -f %Lp "$dir" 2>/dev/null)" -ge 777 ]; then
        echo -e "${RED}   Warning: Directory is world-writable!${NC}"
    fi
}

# Count executables in directory
count_executables() {
    local dir="$1"
    local exec_count=$(find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | wc -l | tr -d ' ')
    echo "   Contains $exec_count executable files"
}

# Search functionality with FZF integration
search_path() {
    local search_term="$1"
    local temp_file=$(mktemp)
    
    echo -e "${BLUE}Searching for executables in PATH...${NC}"
    
    for dir in ${PATH//:/ }; do
        if [ -d "$dir" ]; then
            find "$dir" -maxdepth 1 -type f -executable 2>/dev/null >> "$temp_file"
        fi
    done
    
    if [ -s "$temp_file" ]; then
        if check_fzf; then
            cat "$temp_file" | fzf --header="Select an executable to view details" --preview 'file {}; echo; echo "Permissions:"; ls -l {}; echo; echo "File type:"; file {}' || true
        else
            if [ -n "$search_term" ]; then
                grep -i "$search_term" "$temp_file" || echo "No matches found"
            else
                cat "$temp_file"
            fi
        fi
    else
        echo "No executable files found"
    fi
    
    rm -f "$temp_file"
}

# Find duplicate PATH entries
find_duplicates() {
    echo -e "${BLUE}Checking for duplicate PATH entries:${NC}"
    duplicates=$(echo "$PATH" | tr ':' '\n' | sort | uniq -d)
    
    if [ -n "$duplicates" ]; then
        echo -e "${RED}Found duplicate entries:${NC}"
        echo "$duplicates"
    else
        echo -e "${GREEN}No duplicate entries found${NC}"
    fi
}

# Show PATH statistics
show_statistics() {
    local total_dirs=$(echo "$PATH" | tr ':' '\n' | wc -l | tr -d ' ')
    local existing_dirs=$(echo "$PATH" | tr ':' '\n' | while read dir; do [ -d "$dir" ] && echo "$dir"; done | wc -l | tr -d ' ')
    local total_executables=0
    local world_writable=0
    
    for dir in ${PATH//:/ }; do
        if [ -d "$dir" ]; then
            count=$(find "$dir" -maxdepth 1 -type f -executable 2>/dev/null | wc -l)
            total_executables=$((total_executables + count))
            
            if [ "$(stat -f %Lp "$dir" 2>/dev/null)" -ge 777 ]; then
                world_writable=$((world_writable + 1))
            fi
        fi
    done
    
    echo -e "${BLUE}PATH Statistics:${NC}"
    echo "Total directories: $total_dirs"
    echo "Existing directories: $existing_dirs"
    echo "Missing directories: $((total_dirs - existing_dirs))"
    echo "Total executable files: $total_executables"
    echo "World-writable directories: $world_writable"
}

# Export PATH analysis to file
export_analysis() {
    local output_file="$1"
    if [ -z "$output_file" ]; then
        output_file="path_analysis_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    {
        echo "PATH Analysis Report"
        echo "Generated on $(date)"
        echo "======================="
        echo
        
        echo "PATH Statistics:"
        show_statistics
        echo
        
        echo "Detailed PATH Analysis:"
        display_path_enhanced
        echo
        
        echo "Duplicate Check:"
        find_duplicates
        
    } > "$output_file"
    
    echo -e "${GREEN}Analysis exported to: $output_file${NC}"
}

# Interactive mode using FZF
interactive_mode() {
    if ! check_fzf; then
        echo "Interactive mode requires fzf. Please install it first."
        return 1
    fi
    
    local options="Display PATH
Enhanced PATH Analysis
Search Executables
Find Duplicates
Show Statistics
Export Analysis
Quit"
    
    while true; do
        local selected=$(echo "$options" | fzf --header="Select an option:" --height=40% --reverse)
        
        case "$selected" in
            "Display PATH")
                clear
                display_path
                read -p "Press Enter to continue..."
                ;;
            "Enhanced PATH Analysis")
                clear
                display_path_enhanced
                read -p "Press Enter to continue..."
                ;;
            "Search Executables")
                clear
                search_path
                read -p "Press Enter to continue..."
                ;;
            "Find Duplicates")
                clear
                find_duplicates
                read -p "Press Enter to continue..."
                ;;
            "Show Statistics")
                clear
                show_statistics
                read -p "Press Enter to continue..."
                ;;
            "Export Analysis")
                clear
                export_analysis
                read -p "Press Enter to continue..."
                ;;
            "Quit"|"")
                break
                ;;
        esac
    done
}

# Help message
show_help() {
    echo "Usage: $0 [OPTION]"
    echo "Options:"
    echo "  -s, --simple     Display simple PATH listing"
    echo "  -e, --enhanced   Display enhanced PATH analysis"
    echo "  -f, --find       Search for executables in PATH"
    echo "  -d, --duplicates Find duplicate PATH entries"
    echo "  -t, --stats      Show PATH statistics"
    echo "  -x, --export     Export analysis to file"
    echo "  -i, --interactive Launch interactive mode (requires fzf)"
    echo "  -h, --help       Display this help message"
}

# Main script execution
case "$1" in
    "-s"|"--simple")
        display_path
        ;;
    "-e"|"--enhanced")
        display_path_enhanced
        ;;
    "-f"|"--find")
        search_path "$2"
        ;;
    "-d"|"--duplicates")
        find_duplicates
        ;;
    "-t"|"--stats")
        show_statistics
        ;;
    "-x"|"--export")
        export_analysis "$2"
        ;;
    "-i"|"--interactive")
        interactive_mode
        ;;
    "-h"|"--help")
        show_help
        ;;
    *)
        interactive_mode
        ;;
esac