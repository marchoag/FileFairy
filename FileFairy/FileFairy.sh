#!/bin/bash

# Enhanced Color codes
GREEN='\033[0;32m'
BOLD_GREEN='\033[1;32m'
BLUE='\033[0;34m'
BOLD_BLUE='\033[1;34m'
ORANGE='\033[0;33m'
BRIGHT_RED='\033[1;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to create bordered text
create_border() {
    local text="$1"
    local width=$(( ${#text} + 4 ))
    local border=$(printf '=%.0s' $(seq 1 $width))
    echo -e "\n${BOLD_BLUE}$border${NC}"
    echo -e "${BOLD_BLUE}= $text =${NC}"
    echo -e "${BOLD_BLUE}$border${NC}\n"
}

# Display opening border
create_border "FileFairy*"

# Introduction
echo -e "${BOLD}Welcome to FileFairy!${NC}

This script renames folders generated when using the Apple Photos \"Export\" function 
to help you rename folders for easy chronological sorting.

It operates on folder names currently formatted as:
\"[Event Name], [Month] [Day], [Year]\" or \"[Month] [Day], [Year]\"

The script will output the results to a uniform format of:
\"[YYYY]-[MM]-[DD] - [Event Name]\"

${BOLD_GREEN}You'll have the option to preview changes, confirm before renaming, and undo any 
changes if you don't like the results.${NC}

${BOLD}Here's what FileFairy will do:${NC}
1. Scan the current (or specified) directory for folders
2. Show you a preview of the changes (first 10 folders)
3. Ask for your confirmation before making any changes
4. Rename the folders to the new format
5. Give you a final chance to keep or undo the changes

${BOLD}Let's get started!${NC}
"

# Confirmation to start
while true; do
    echo -e "${BOLD_BLUE}Would you like to continue? (y/n):${NC} "
    read answer
    echo ""
    case $answer in
        [Yy]* ) break;;
        [Nn]* ) 
            create_border "Good bye! May you live happily ever after!"
            exit
            ;;
        * ) echo "Please answer y or n.";;
    esac
done

DEFAULT_YEAR=2012

convert_date() {
    local date_str="$1"
    local year="$DEFAULT_YEAR"
    
    if [[ $date_str == *", "* ]]; then
        year="${date_str##*, }"
        date_str="${date_str%, $year}"
    fi
    
    if [[ $date_str =~ ^([A-Z][a-z]+)\ ([0-9]{1,2})$ ]]; then
        month="${BASH_REMATCH[1]}"
        day=$(printf "%02d" "${BASH_REMATCH[2]}")  # Pad day with leading zero
        date -j -f "%B %d %Y" "$month $day $year" "+%Y-%m-%d"
    else
        echo "Error: Unable to parse date: $date_str" >&2
        return 1
    fi
}

process_folders() {
    local dir="$1"
    cd "$dir" || { echo -e "\n${BRIGHT_RED}Failed to change to directory $dir${NC}\n"; exit 1; }

    # Array to store original and new names
    declare -a original_names
    declare -a new_names

    echo -e "${BOLD}Here's a preview showing the changes to the first 10 folders in ${BOLD_GREEN}$dir${NC}${BOLD}:\n"${NC}
    echo -e "------------------------"
    count=0
    for folder in *; do
        if [ -d "$folder" ]; then
            # Extract date part
            if [[ $folder =~ ([A-Z][a-z]+\ [0-9]{1,2}(,\ [0-9]{4})?)$ ]]; then
                date_part="${BASH_REMATCH[1]}"
                event_name="${folder%$date_part}"
                event_name="${event_name%, }"  # Remove trailing comma and space if present
            elif [[ $folder =~ ^([A-Z][a-z]+\ [0-9]{1,2}(,\ [0-9]{4})?)$ ]]; then
                date_part="$folder"
                event_name=""
            else
                echo -e "${BRIGHT_RED}Will skip: $folder (unrecognized format)${NC}"
                continue
            fi

            # Convert the date
            formatted_date=$(convert_date "$date_part")
            if [ $? -ne 0 ]; then
                echo -e "${BRIGHT_RED}Will skip: $folder (date conversion failed)${NC}"
                continue
            fi

            # Create the new folder name
            if [ -z "$event_name" ]; then
                new_name="${formatted_date}"
            else
                new_name="${formatted_date} - ${event_name}"
            fi

            # Store original and new names
            original_names+=("$folder")
            new_names+=("$new_name")
            
            # Display preview (limited to first 10)
            if [ $count -lt 10 ]; then
                echo -e "${GREEN}Will rename:${NC} $folder ${BOLD}->${NC} ${GREEN}$new_name${NC}"
            elif [ $count -eq 10 ]; then
                echo "..."
            fi
            ((count++))
        fi
    done

    echo -e "${BOLD}------------------------${NC}"
    echo -e "\n${BOLD_GREEN}Total folders to rename: $count${NC}\n"

    # Prompt for confirmation
    echo -e "${BOLD_BLUE}Do these changes look good? (y/n):${NC} "
    read confirm
    echo  # Add a line break after the input
    if [[ $confirm != [Yy]* ]]; then
        echo -e "${BRIGHT_RED}Operation cancelled.${NC}\n"
        return 1
    fi

    echo -e "${BOLD}Renaming folders:${NC}"
    echo -e "${BOLD}------------------------${NC}"

    # Perform the renaming
    for i in "${!original_names[@]}"; do
        if mv "${original_names[i]}" "${new_names[i]}"; then
            echo -e "${GREEN}Renamed:${NC} ${original_names[i]} ${BOLD}->${NC} ${GREEN}${new_names[i]}${NC}"
        else
            echo -e "${BRIGHT_RED}Error: Failed to rename ${original_names[i]}${NC}" >&2
        fi
    done

    echo -e "${BOLD}------------------------${NC}\n"

    # Prompt for keeping changes
    echo -e "${BOLD_BLUE}Do you want to keep these changes? (y/n):${NC} "
    read keep
    echo  # Add a line break after the input
    if [[ $keep != [Yy]* ]]; then
        echo -e "${BOLD}Undoing changes:${NC}"
        echo -e "${BOLD}------------------------${NC}"
        for i in "${!new_names[@]}"; do
            if mv "${new_names[i]}" "${original_names[i]}"; then
                echo -e "${GREEN}Undone:${NC} ${new_names[i]} ${BOLD}->${NC} ${original_names[i]}"
            else
                echo -e "${BRIGHT_RED}Error: Failed to undo ${new_names[i]}${NC}" >&2
            fi
        done
        echo -e "${BOLD}------------------------${NC}"
        echo -e "\n${GREEN}All changes have been undone.${NC}\n"
    else
        echo -e "\n${GREEN}Changes have been kept. Operation complete.${NC}\n"
    fi
}

# Main execution
if [ $# -eq 0 ]; then
    TARGET_DIR="$(pwd)"
else
    TARGET_DIR="$1"
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo -e "\n${BRIGHT_RED}Error: $TARGET_DIR is not a valid directory.${NC}\n"
    exit 1
fi

echo -e "${BOLD}Running FileFairy on directory: ${BOLD_GREEN}$TARGET_DIR$${NC} ...\n.\n.\n.${NC}\n"
process_folders "$TARGET_DIR"

# Display closing border
create_border "Good bye! May you live happily ever after!"