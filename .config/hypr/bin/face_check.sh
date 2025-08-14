#!/bin/bash
if pgrep -x hyprlock >/dev/null; then
    exit 0
fi
cd ~/face_check/
./venv/bin/python -W ignore::UserWarning face_recognition_ir.py
if [ $? -eq 0 ]; then
    loginctl lock-session
else
    echo "Face recognition is okay"
    exit 1
fi
