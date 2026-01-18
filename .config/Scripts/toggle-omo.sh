#!/bin/bash

# Define the file path
CONFIG_FILE="$HOME/.config/opencode/opencode.jsonc"

# Check if file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found."
    exit 1
fi

# Check if the line is already commented out (Removed the \ before /)
if grep -q "// \"oh-my-opencode\"" "$CONFIG_FILE"; then
    # If commented, remove the // (Uncomment)
    sed -i 's/\/\/ \"oh-my-opencode\"/\"oh-my-opencode\"/' "$CONFIG_FILE"
    echo "Status: Plugin enabled (uncommented)."
else
    # If not commented, add the // (Comment out)
    sed -i 's/\"oh-my-opencode\"/\/\/ \"oh-my-opencode\"/' "$CONFIG_FILE"
    echo "Status: Plugin disabled (commented out)."
fi
