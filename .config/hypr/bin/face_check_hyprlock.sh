
#!/bin/bash
if pgrep -x hyprlock > /dev/null; then
    cd ~/face_check/
    ./venv/bin/python -W ignore::UserWarning face_recognition_ir.py
    if [ $? -eq 0 ]; then
        exit 0
    else
        pkill -USR1 hyprlock
        exit 1
    fi
else
    echo "Hyprlock is not running."
    exit 1
fi
