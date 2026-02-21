# Justfile for dotfiles management

# Build and switch to the laptop configuration using nh
rebuild:
	nh os switch ~/dotfiles/nixos_config --hostname laptop

# Test build (no activation) using nh
build:
	nh os build ~/dotfiles/nixos_config --hostname laptop

# Update flake inputs
update:
	nix flake update --flake ~/dotfiles/nixos_config

# Clean old generations using nh
clean:
	nh clean all
