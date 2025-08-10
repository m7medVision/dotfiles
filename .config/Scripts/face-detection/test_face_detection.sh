#!/bin/bash

# Test script for face detection functionality
# Usage: ./test_face_detection.sh [--verbose]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERBOSE=false

if [[ "$1" == "--verbose" ]]; then
    VERBOSE=true
fi

log() {
    echo "[TEST] $1"
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[DEBUG] $1"
    fi
}

# Test system capabilities
test_system() {
    log "Testing system capabilities..."
    
    verbose_log "Checking for Go..."
    if command -v go &>/dev/null; then
        log "✓ Go is available ($(go version))"
    else
        log "✗ Go is not available"
    fi
    
    verbose_log "Checking for camera devices..."
    camera_found=false
    for device in /dev/video{0..2}; do
        if [[ -e "$device" ]]; then
            log "✓ Camera device found: $device"
            camera_found=true
            break
        fi
    done
    
    if [[ "$camera_found" == "false" ]]; then
        log "✗ No camera devices found"
    fi
    
    verbose_log "Checking for OpenCV..."
    if pkg-config --exists opencv4 &>/dev/null; then
        log "✓ OpenCV is available"
    else
        log "✗ OpenCV is not available"
    fi
    
    verbose_log "Checking for camera tools..."
    tools_found=0
    for tool in fswebcam ffmpeg v4l2-ctl; do
        if command -v "$tool" &>/dev/null; then
            log "✓ $tool is available"
            ((tools_found++))
        else
            verbose_log "✗ $tool is not available"
        fi
    done
    
    if [[ $tools_found -eq 0 ]]; then
        log "⚠ No camera tools available - detection may not work"
    fi
}

# Test Go detector
test_go_detector() {
    log "Testing Go detector..."
    
    cd "$SCRIPT_DIR"
    
    if [[ -x "./face-detector" ]]; then
        log "✓ Go binary exists"
    else
        verbose_log "Building Go detector..."
        if make build &>/dev/null; then
            log "✓ Go detector built successfully"
        else
            log "✗ Failed to build Go detector"
            return 1
        fi
    fi
    
    log "Running Go detector test..."
    timeout 10s ./face-detector
    exit_code=$?
    
    case $exit_code in
        0) log "✓ Go detector: Face detected" ;;
        1) log "✓ Go detector: No face detected" ;;
        2) log "⚠ Go detector: Error occurred" ;;
        124) log "⚠ Go detector: Timed out" ;;
        *) log "✗ Go detector: Unknown exit code $exit_code" ;;
    esac
}

# Test shell detector
test_shell_detector() {
    log "Testing shell detector..."
    
    if [[ -x "$SCRIPT_DIR/detect.sh" ]]; then
        log "✓ Shell script exists"
    else
        log "✗ Shell script not found"
        return 1
    fi
    
    log "Running shell detector test..."
    timeout 10s "$SCRIPT_DIR/detect.sh"
    exit_code=$?
    
    case $exit_code in
        0) log "✓ Shell detector: Presence detected" ;;
        1) log "✓ Shell detector: No presence detected" ;;
        2) log "⚠ Shell detector: Error occurred" ;;
        124) log "⚠ Shell detector: Timed out" ;;
        *) log "✗ Shell detector: Unknown exit code $exit_code" ;;
    esac
}

# Test wrapper script
test_wrapper() {
    log "Testing wrapper script..."
    
    if [[ -x "$SCRIPT_DIR/face_check_and_lock.sh" ]]; then
        log "✓ Wrapper script exists"
    else
        log "✗ Wrapper script not found"
        return 1
    fi
    
    log "Running wrapper script test..."
    timeout 10s "$SCRIPT_DIR/face_check_and_lock.sh"
    exit_code=$?
    
    case $exit_code in
        0) log "✓ Wrapper script completed successfully" ;;
        124) log "⚠ Wrapper script: Timed out" ;;
        *) log "⚠ Wrapper script: Exit code $exit_code" ;;
    esac
    
    # Check log file
    if [[ -f "/tmp/hypridle-face-detection.log" ]]; then
        log "✓ Log file created"
        if [[ "$VERBOSE" == "true" ]]; then
            verbose_log "Recent log entries:"
            tail -5 /tmp/hypridle-face-detection.log | while read line; do
                verbose_log "  $line"
            done
        fi
    else
        log "⚠ No log file found"
    fi
}

# Main test function
main() {
    log "Face Detection Test Suite"
    log "========================"
    echo
    
    test_system
    echo
    
    test_shell_detector
    echo
    
    test_go_detector
    echo
    
    test_wrapper
    echo
    
    log "Test completed. Check logs above for any issues."
    
    if [[ "$camera_found" == "false" ]]; then
        echo
        log "NOTE: No camera detected. On a real system with camera:"
        log "1. Install camera tools: make install-arch (or -ubuntu/-fedora)"
        log "2. Build detector: make build"
        log "3. Test: make test"
    fi
}

main "$@"