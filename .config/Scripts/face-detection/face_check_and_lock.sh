#!/bin/bash

# Face detection wrapper script for hypridle integration
# This script checks for face/presence and only turns off screen if no one is detected

# Get the actual script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GO_DETECTOR="$SCRIPT_DIR/face-detector"
SHELL_DETECTOR="$SCRIPT_DIR/detect.sh"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Face Detection: $1" >> /tmp/hypridle-face-detection.log
}

# Main detection logic
run_detection() {
    log_message "Starting face detection check..."
    
    # Try Go binary first, then fall back to shell script
    if [[ -x "$GO_DETECTOR" ]]; then
        log_message "Using Go detector"
        "$GO_DETECTOR"
        exit_code=$?
    elif [[ -x "$SHELL_DETECTOR" ]]; then
        log_message "Using shell detector"
        "$SHELL_DETECTOR"  
        exit_code=$?
    else
        log_message "No detector found, building Go detector..."
        cd "$SCRIPT_DIR"
        if make build &>/dev/null; then
            log_message "Go detector built successfully"
            "$GO_DETECTOR"
            exit_code=$?
        else
            log_message "Failed to build Go detector, proceeding with screen off"
            exit_code=1
        fi
    fi
    
    case $exit_code in
        0)
            log_message "Face detected - keeping screen on"
            # Don't turn off screen, someone is present
            ;;
        1)
            log_message "No face detected - turning off screen"
            # Turn off screen as originally intended
            if command -v hyprctl &>/dev/null; then
                hyprctl dispatch dpms off
            else
                log_message "hyprctl not found, cannot control display"
            fi
            ;;
        2)
            log_message "Detection error - turning off screen as fallback"
            # Error occurred, proceed with screen off as safe fallback
            if command -v hyprctl &>/dev/null; then
                hyprctl dispatch dpms off
            else
                log_message "hyprctl not found, cannot control display"
            fi
            ;;
        *)
            log_message "Unknown exit code: $exit_code - turning off screen"
            if command -v hyprctl &>/dev/null; then
                hyprctl dispatch dpms off
            else
                log_message "hyprctl not found, cannot control display"
            fi
            ;;
    esac
}

# Run the detection
run_detection