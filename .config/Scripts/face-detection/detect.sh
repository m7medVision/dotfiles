#!/bin/bash

# Simple shell-based face/presence detection script
# Fallback for systems where Go/OpenCV setup is complex

# Exit codes
EXIT_FACE_DETECTED=0
EXIT_NO_FACE=1
EXIT_ERROR=2

# Configuration
TIMEOUT=3
TEMP_DIR="/tmp"
IMAGE_PATH="$TEMP_DIR/presence_check.jpg"

# Function to check if camera is accessible
check_camera() {
    for device in /dev/video{0..2}; do
        if [[ -e "$device" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to capture and analyze with fswebcam
detect_with_fswebcam() {
    if ! command -v fswebcam &> /dev/null; then
        return 1
    fi
    
    # Capture image quietly
    if fswebcam -r 320x240 --no-banner -S 3 "$IMAGE_PATH" &>/dev/null; then
        # Check if image has reasonable size (not just black)
        local size=$(stat -f%z "$IMAGE_PATH" 2>/dev/null || stat -c%s "$IMAGE_PATH" 2>/dev/null)
        rm -f "$IMAGE_PATH"
        
        if [[ $size -gt 5000 ]]; then
            return 0  # Presence detected
        fi
    fi
    
    return 1
}

# Function to capture and analyze with ffmpeg
detect_with_ffmpeg() {
    if ! command -v ffmpeg &> /dev/null; then
        return 1
    fi
    
    # Capture single frame
    if timeout $TIMEOUT ffmpeg -f v4l2 -i /dev/video0 -vframes 1 -s 320x240 -y "$IMAGE_PATH" &>/dev/null; then
        # Check if image has reasonable size
        local size=$(stat -f%z "$IMAGE_PATH" 2>/dev/null || stat -c%s "$IMAGE_PATH" 2>/dev/null)
        rm -f "$IMAGE_PATH"
        
        if [[ $size -gt 5000 ]]; then
            return 0  # Presence detected
        fi
    fi
    
    return 1
}

# Function to check camera usage
check_camera_usage() {
    if command -v lsof &> /dev/null; then
        # Check if any process is using camera
        if lsof /dev/video* &>/dev/null; then
            return 0  # Camera in use, assume presence
        fi
    fi
    return 1
}

# Main detection logic
main() {
    echo "Starting presence detection..."
    
    # Check if camera is accessible
    if ! check_camera; then
        echo "No camera found"
        exit $EXIT_ERROR
    fi
    
    # Try detection methods in order of preference
    if detect_with_fswebcam || detect_with_ffmpeg || check_camera_usage; then
        echo "Presence detected - staying active"
        exit $EXIT_FACE_DETECTED
    else
        echo "No presence detected - allowing lock"
        exit $EXIT_NO_FACE
    fi
}

# Run main function
main "$@"