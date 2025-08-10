# Face Detection Setup Guide

This guide will help you set up the face detection system that integrates with hypridle to check for presence every 5 minutes.

## Quick Start

1. **Install dependencies** (choose your distribution):
   ```bash
   cd ~/.config/Scripts/face-detection
   
   # Arch Linux
   make install-arch
   
   # Ubuntu/Debian
   make install-ubuntu
   
   # Fedora
   make install-fedora
   ```

2. **Build the detector**:
   ```bash
   make build
   ```

3. **Test the system**:
   ```bash
   make test
   # or for detailed output:
   ./test_face_detection.sh --verbose
   ```

4. **Restart hypridle** (if running):
   ```bash
   pkill hypridle
   hypridle &
   ```

## How It Works

The system integrates with your existing hypridle configuration:

- **1 minute**: Dim screen brightness
- **2 minutes**: Lock screen  
- **5 minutes**: **Face detection check** → Only turn off display if no face detected
- **30 minutes**: Suspend system

### Face Detection Logic

At the 5-minute mark, the system:
1. Captures camera image (3-second timeout)
2. Analyzes for face presence
3. **If face detected**: Keeps screen on
4. **If no face**: Turns off display as normal
5. **If error**: Safely proceeds with display off

## Exit Codes

- `0`: Face detected - stay active
- `1`: No face detected - proceed with lock/display off
- `2`: Error occurred - safe fallback

## Troubleshooting

### No Camera Detected
```bash
# Check camera devices
ls -la /dev/video*

# Test camera access
make check-system
```

### OpenCV Build Fails
The system automatically falls back to shell-based detection using standard camera tools.

### Permission Issues
```bash
# Add user to video group
sudo usermod -a -G video $USER
# Then log out and back in
```

### Testing Individual Components

```bash
# Test shell detector only
./detect.sh

# Test Go detector only  
./face-detector

# Test wrapper script
./face_check_and_lock.sh

# Check logs
tail -f /tmp/hypridle-face-detection.log
```

## Performance

- **Detection time**: 3 seconds maximum
- **CPU usage**: Minimal (low resolution, optimized)
- **Memory usage**: < 50MB during detection
- **Camera resolution**: 320x240 for speed

## Advanced Configuration

### Adjust Detection Timeout
Edit `main.go` and change:
```go
detected, err := detectFaceQuick(3 * time.Second)  // Change timeout here
```

### Change Detection Sensitivity
For OpenCV detection, modify in `main.go`:
```go
rects := classifier.DetectMultiScale(gray)
// Add parameters: DetectMultiScale(gray, 1.1, 3, 0, image.Point{30, 30}, image.Point{})
```

### Different Camera Device
Edit `detect.sh` to use different camera:
```bash
ffmpeg -f v4l2 -i /dev/video1  # Change from video0 to video1
```

## Security Notes

- Camera access is only during detection (3-second bursts)
- No images are stored permanently
- All processing is local (no network access)
- Logs contain no sensitive information

## Integration with Other Tools

The face detection can be used independently:

```bash
# Use in your own scripts
if ~/.config/Scripts/face-detection/face-detector; then
    echo "Someone is present"
else
    echo "No one detected"
fi
```

## Uninstalling

To remove face detection:

1. Restore original hypridle.conf:
   ```bash
   # Change this line in ~/.config/hypr/hypridle.conf:
   on-timeout = hyprctl dispatch dpms off
   ```

2. Remove the face detection directory:
   ```bash
   rm -rf ~/.config/Scripts/face-detection
   ```

3. Restart hypridle:
   ```bash
   pkill hypridle && hypridle &
   ```