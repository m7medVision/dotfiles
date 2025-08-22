#!/bin/bash

SCRIPT_DIR="$HOME/AuraFace"
PYTHON_BIN="$SCRIPT_DIR/venv/bin/python"
RECOGNITION_SCRIPT="$SCRIPT_DIR/recognition.py"
LOG_FILE="$HOME/.face-security.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

check_face_recognition() {
    if [ ! -f "$PYTHON_BIN" ]; then
        log_message "ERROR: Python virtual environment not found at $PYTHON_BIN"
        return 1
    fi

    if [ ! -f "$RECOGNITION_SCRIPT" ]; then
        log_message "ERROR: Recognition script not found at $RECOGNITION_SCRIPT"
        return 1
    fi

    cd "$SCRIPT_DIR" || {
        log_message "ERROR: Could not change to directory $SCRIPT_DIR"
        return 1
    }

    log_message "Running face recognition check..."

    if timeout 30 "$PYTHON_BIN" recognition.py camera --speed-mode 1 --headless; then
        log_message "Face recognition SUCCESS: Authorized user detected"
        return 0
    else
        exit_code=$?
        if [ $exit_code -eq 1 ]; then
            log_message "Face recognition FAILED: Unauthorized user detected - LOCKING SYSTEM"

            if command -v hyprctl &> /dev/null; then
                loginctl lock-session
            elif command -v gnome-screensaver-command &> /dev/null; then
                gnome-screensaver-command -l
            else
                log_message "WARNING: No screen locker found"
            fi

            # Send notification if available
            if command -v notify-send &> /dev/null; then
                notify-send "🔒 Security Alert" "Unauthorized user detected - System locked" --urgency=critical
            fi

            return 1
        else
            log_message "Face recognition ERROR: Script failed with exit code $exit_code"
            return $exit_code
        fi
    fi
}

main() {
    check_face_recognition
}

main "$@"
