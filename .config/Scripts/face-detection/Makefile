.PHONY: build clean install test help

# Binary name
BINARY := face-detector
SHELL_SCRIPT := detect.sh

# Build the Go binary
build:
	@echo "Building face detector..."
	@go build -o $(BINARY) .

# Clean build artifacts
clean:
	@echo "Cleaning up..."
	@rm -f $(BINARY)

# Install dependencies (Arch Linux)
install-arch:
	@echo "Installing dependencies for Arch Linux..."
	sudo pacman -S --needed opencv v4l-utils ffmpeg imagemagick

# Install dependencies (Ubuntu/Debian)
install-ubuntu:
	@echo "Installing dependencies for Ubuntu/Debian..."
	sudo apt update && sudo apt install libopencv-dev v4l-utils ffmpeg fswebcam imagemagick

# Install dependencies (Fedora)
install-fedora:
	@echo "Installing dependencies for Fedora..."
	sudo dnf install opencv-devel v4l-utils ffmpeg ImageMagick

# Test the face detector
test:
	@echo "Testing face detection..."
	@if [ -x "./$(BINARY)" ]; then \
		echo "Testing Go binary:"; \
		./$(BINARY); \
		echo "Exit code: $$?"; \
	elif [ -x "./$(SHELL_SCRIPT)" ]; then \
		echo "Testing shell script:"; \
		./$(SHELL_SCRIPT); \
		echo "Exit code: $$?"; \
	else \
		echo "No executable found. Run 'make build' first."; \
		exit 1; \
	fi

# Quick test with shell script
test-shell:
	@echo "Testing shell script detector..."
	@./$(SHELL_SCRIPT)
	@echo "Exit code: $$?"

# Check system capabilities
check-system:
	@echo "Checking system capabilities..."
	@echo "Camera devices:"
	@ls -la /dev/video* 2>/dev/null || echo "  No camera devices found"
	@echo ""
	@echo "Available tools:"
	@command -v go >/dev/null && echo "  ✓ Go" || echo "  ✗ Go"
	@pkg-config --exists opencv4 && echo "  ✓ OpenCV" || echo "  ✗ OpenCV"
	@command -v fswebcam >/dev/null && echo "  ✓ fswebcam" || echo "  ✗ fswebcam"
	@command -v ffmpeg >/dev/null && echo "  ✓ ffmpeg" || echo "  ✗ ffmpeg"
	@command -v v4l2-ctl >/dev/null && echo "  ✓ v4l2-ctl" || echo "  ✗ v4l2-ctl"
	@command -v lsof >/dev/null && echo "  ✓ lsof" || echo "  ✗ lsof"

# Help
help:
	@echo "Face Detection Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make build         Build the Go binary"
	@echo "  make clean         Clean build artifacts"
	@echo "  make test          Test the detector"
	@echo "  make test-shell    Test shell script version"
	@echo "  make check-system  Check system capabilities"
	@echo ""
	@echo "Installation (choose your distro):"
	@echo "  make install-arch     Install deps on Arch Linux"
	@echo "  make install-ubuntu   Install deps on Ubuntu/Debian"
	@echo "  make install-fedora   Install deps on Fedora"
	@echo ""
	@echo "Exit codes:"
	@echo "  0 = Face/presence detected"
	@echo "  1 = No face/presence detected"
	@echo "  2 = Error occurred"