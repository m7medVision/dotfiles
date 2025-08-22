#!/bin/bash
set -e

echo "🔒 Setting up Face Recognition Security System..."

# Ensure AuraFace exists
if [ ! -d "$HOME/AuraFace" ]; then
    echo "❌ ERROR: AuraFace directory not found at $HOME/AuraFace"
    echo "Please set up your face recognition system first."
    exit 1
fi

# Check if recognition script exists
if [ ! -f "$HOME/AuraFace/venv/bin/python" ] || [ ! -f "$HOME/AuraFace/recognition.py" ]; then
    echo "❌ ERROR: AuraFace components not found"
    echo "Please ensure $HOME/AuraFace/venv/bin/python and $HOME/AuraFace/recognition.py exist"
    exit 1
fi

# Create systemd user directory
mkdir -p ~/.config/systemd/user

echo "📁 Created systemd user directory"

# Check if files already exist
if [ -f ~/.config/systemd/user/face-security.timer ] && [ -f ~/.config/systemd/user/face-security.service ]; then
    echo "✅ Systemd service files already exist"
else
    echo "❌ Systemd service files not found in dotfiles"
    echo "Please run 'stow .' first to set up your dotfiles"
    exit 1
fi

# Reload systemd user services
systemctl --user daemon-reload
echo "🔄 Reloaded systemd user services"

# Enable and start the timer
systemctl --user enable face-security.timer
systemctl --user start face-security.timer
echo "⏰ Enabled and started face recognition security timer"

# Show status
echo ""
echo "✅ Face Recognition Security System is now active!"
echo ""
echo "📊 Commands:"
echo "  Check status:  systemctl --user status face-security.timer"
echo "  View logs:     journalctl --user -u face-security.service -f"
echo "  Manual run:    systemctl --user start face-security.service"
echo "  Stop system:   systemctl --user stop face-security.timer"
echo "  Disable:       systemctl --user disable face-security.timer"
echo ""
echo "📋 Configuration:"
echo "  • Runs every 5 minutes with random delay up to 30 minutes"
echo "  • Logs to: ~/.face-security.log"
echo "  • Uses: $HOME/AuraFace/venv/bin/python"
echo "  • Script location: ~/.config/Scripts/face-security.sh"
echo ""
echo "🔐 System will automatically lock if unauthorized user detected!"
