package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"gocv.io/x/gocv"
)

const (
	// Exit codes for hypridle
	ExitFaceDetected = 0 // Face found, don't lock
	ExitNoFace       = 1 // No face found, proceed with lock
	ExitError        = 2 // Error occurred
)

func main() {
	// Quick face detection with timeout
	detected, err := detectFaceQuick(3 * time.Second)
	if err != nil {
		log.Printf("Error detecting face: %v", err)
		os.Exit(ExitError)
	}

	if detected {
		fmt.Println("Face detected - staying active")
		os.Exit(ExitFaceDetected)
	} else {
		fmt.Println("No face detected - allowing lock")
		os.Exit(ExitNoFace)
	}
}

func detectFaceQuick(timeout time.Duration) (bool, error) {
	// Try OpenCV method first, fall back to shell method if OpenCV not available
	if isOpenCVAvailable() {
		return detectFaceOpenCV(timeout)
	}
	
	// Fallback to shell-based detection
	return detectFaceShell(timeout)
}

func isOpenCVAvailable() bool {
	// Check if OpenCV is available by trying to create a cascade classifier
	classifier := gocv.NewCascadeClassifier()
	defer classifier.Close()
	
	// Try to load a cascade file (this will fail if OpenCV isn't properly installed)
	cascadePath := findCascadeFile()
	return cascadePath != "" && classifier.Load(cascadePath)
}

func findCascadeFile() string {
	// Common locations for Haar cascade files
	possiblePaths := []string{
		"/usr/share/opencv4/haarcascades/haarcascade_frontalface_alt.xml",
		"/usr/share/opencv/haarcascades/haarcascade_frontalface_alt.xml",
		"/usr/local/share/opencv4/haarcascades/haarcascade_frontalface_alt.xml",
		"/usr/local/share/opencv/haarcascades/haarcascade_frontalface_alt.xml",
		"./haarcascade_frontalface_alt.xml",
	}
	
	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}
	return ""
}

func detectFaceOpenCV(timeout time.Duration) (bool, error) {
	// Load the Haar cascade classifier for face detection
	classifier := gocv.NewCascadeClassifier()
	defer classifier.Close()

	cascadePath := findCascadeFile()
	if cascadePath == "" || !classifier.Load(cascadePath) {
		return false, fmt.Errorf("failed to load Haar cascade classifier")
	}

	// Open the default camera
	webcam, err := gocv.VideoCaptureDevice(0)
	if err != nil {
		return false, fmt.Errorf("failed to open camera: %v", err)
	}
	defer webcam.Close()

	// Set camera properties for speed
	webcam.Set(gocv.VideoCaptureFrameWidth, 320)
	webcam.Set(gocv.VideoCaptureFrameHeight, 240)
	webcam.Set(gocv.VideoCaptureFPS, 10)

	img := gocv.NewMat()
	defer img.Close()

	gray := gocv.NewMat()
	defer gray.Close()

	startTime := time.Now()

	// Check for faces with timeout
	for time.Since(startTime) < timeout {
		if ok := webcam.Read(&img); !ok {
			continue
		}
		if img.Empty() {
			continue
		}

		// Convert to grayscale for faster processing
		gocv.CvtColor(img, &gray, gocv.ColorBGRToGray)

		// Detect faces
		rects := classifier.DetectMultiScale(gray)
		
		if len(rects) > 0 {
			return true, nil
		}

		// Small delay to prevent excessive CPU usage
		time.Sleep(100 * time.Millisecond)
	}

	return false, nil
}

func detectFaceShell(timeout time.Duration) (bool, error) {
	// Fallback method using shell commands
	// This uses fswebcam + basic image analysis or motion detection
	
	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	
	// Check if camera is accessible via v4l2
	if !isCameraAccessible() {
		return false, fmt.Errorf("camera not accessible")
	}
	
	// Use a simple heuristic: capture an image and check if it's not completely dark
	// This is a basic presence detection
	tempDir := "/tmp"
	imagePath := filepath.Join(tempDir, "face_check.jpg")
	
	// Try different tools in order of preference
	tools := []string{"fswebcam", "ffmpeg"}
	
	for _, tool := range tools {
		if cmd := exec.LookPath(tool); cmd != "" {
			detected, err := captureAndAnalyze(ctx, tool, imagePath)
			if err == nil {
				return detected, nil
			}
		}
	}
	
	// Final fallback: check if camera device shows recent activity
	return checkCameraActivity()
}

func isCameraAccessible() bool {
	// Check if camera device exists and is accessible
	devices := []string{"/dev/video0", "/dev/video1", "/dev/video2"}
	
	for _, device := range devices {
		if _, err := os.Stat(device); err == nil {
			return true
		}
	}
	return false
}

func captureAndAnalyze(ctx context.Context, tool, imagePath string) (bool, error) {
	var cmd *exec.Cmd
	
	switch tool {
	case "fswebcam":
		cmd = exec.CommandContext(ctx, "fswebcam", "-r", "320x240", "--no-banner", "-S", "3", imagePath)
	case "ffmpeg":
		cmd = exec.CommandContext(ctx, "ffmpeg", "-f", "v4l2", "-i", "/dev/video0", "-vframes", "1", "-s", "320x240", "-y", imagePath)
	default:
		return false, fmt.Errorf("unsupported tool: %s", tool)
	}
	
	// Capture image
	if err := cmd.Run(); err != nil {
		return false, err
	}
	
	// Basic analysis: check if image has sufficient variation (not just black)
	// This is a simple heuristic for presence detection
	detected, err := analyzeImageBasic(imagePath)
	
	// Clean up
	os.Remove(imagePath)
	
	return detected, err
}

func analyzeImageBasic(imagePath string) (bool, error) {
	// Get file size as a simple heuristic
	info, err := os.Stat(imagePath)
	if err != nil {
		return false, err
	}
	
	// If image is very small, likely no meaningful content (e.g., black screen)
	if info.Size() < 1000 {
		return false, nil
	}
	
	// Use imagemagick identify if available for more sophisticated analysis
	if cmd := exec.LookPath("identify"); cmd != "" {
		output, err := exec.Command("identify", "-ping", "-format", "%[mean]", imagePath).Output()
		if err == nil {
			// If mean pixel value is too low, probably just dark/empty
			meanStr := strings.TrimSpace(string(output))
			if meanStr != "" && !strings.Contains(meanStr, "0.") {
				return true, nil
			}
		}
	}
	
	// Fallback: assume presence if we got a reasonable sized image
	return info.Size() > 5000, nil
}

func checkCameraActivity() (bool, error) {
	// Final fallback: check if any process is using the camera
	// This can indicate someone is present and using video apps
	
	cmd := exec.Command("lsof", "/dev/video0")
	output, err := cmd.Output()
	if err != nil {
		// lsof not available or no camera access
		return false, nil
	}
	
	// If output has content, camera is in use
	return len(strings.TrimSpace(string(output))) > 0, nil
}