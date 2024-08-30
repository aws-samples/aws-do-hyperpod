#!/bin/bash

# This script removes a paragraph that matches a specified pattern from a file.

help() {
    echo ""
    echo "Usage: $0 <pattern> <file>"
    echo "       removes paragraph that matches pattern from file"
    echo ""
}

if [ "$2" == "" ]; then
    help
else

    # Paragraph to remove (identified by a unique string)
    pattern=$1

    # File to modify
    file=$2

    # Create a temporary file
    tempfile=$(mktemp)

    # Use awk to remove the paragraph
    awk -v p="$pattern" '
        BEGIN { in_para = 0 }
        $0 ~ p { in_para = 1; next }
        in_para == 1 && /^\s*$/ { in_para = 0; next }
        in_para == 0 { print }
    ' "$file" > "$tempfile"

    # Replace the original file with the modified one
    mv "$tempfile" "$file"

fi

