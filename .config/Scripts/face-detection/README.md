# Face Detection for Hypridle

This directory contains a Go-based face detection script that integrates with hypridle to check if someone is present near the laptop every 5 minutes.

## Features

- Fast face detection using OpenCV (primary method)
- Fallback methods for systems without OpenCV
- Optimized for speed and low resource usage
- Returns appropriate exit codes for hypridle integration

## Installation

### Method 1: Full OpenCV Setup (Recommended)

1. Install OpenCV development packages:
   ```bash
   # Arch Linux
   sudo pacman -S opencv opencv-contrib

   # Ubuntu/Debian
   sudo apt install libopencv-dev

   # Fedora
   sudo dnf install opencv-devel
   ```

2. Build the application:
   ```bash
   cd ~/.config/Scripts/face-detection
   go build -o face-detector
   ```

### Method 2: Minimal Setup (Fallback)

If OpenCV isn't available, the script will automatically fall back to simpler detection methods using:

1. Install basic camera tools:
   ```bash
   # Arch Linux
   sudo pacman -S v4l-utils ffmpeg

   # Ubuntu/Debian  
   sudo apt install v4l-utils ffmpeg fswebcam

   # Optional: imagemagick for better image analysis
   sudo pacman -S imagemagick  # or sudo apt install imagemagick
   ```

2. Build the application:
   ```bash
   cd ~/.config/Scripts/face-detection
   go build -o face-detector
   ```

## Testing

Test the face detection:
```bash
./face-detector
echo $?  # 0 = face detected, 1 = no face, 2 = error
```

## Integration with Hypridle

The hypridle configuration has been updated to use this script. The detector runs at the 5-minute timeout to check for presence before proceeding with display/lock actions.

## Exit Codes

- `0`: Face detected - stay active
- `1`: No face detected - allow lock/sleep
- `2`: Error occurred

## Performance

- Detection timeout: 3 seconds maximum
- Camera resolution: 320x240 for speed
- Optimized for minimal CPU/memory usage
- Graceful fallbacks if camera unavailable