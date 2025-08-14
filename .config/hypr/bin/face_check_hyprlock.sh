
#!/bin/bash
if pgrep -x hyprlock >/dev/null; then
    cd ~/face_check/
    ./venv/bin/python -W ignore::UserWarning face_recognition_ir.py
    if [ $? -eq 0 ]; then
        exit 0
    else
        loginctl unlock-session
        exit 1
    fi
fi
