# Justfile for dotfiles management

# Build and switch to the laptop configuration
rebuild:
	sudo nixos-rebuild switch --flake ~/dotfiles/nixos_config#laptop

# Test build (no activation)
build:
	sudo nixos-rebuild build --flake ~/dotfiles/nixos_config#laptop

# Dry-activate configuration
check:
	sudo nixos-rebuild dry-activate --flake ~/dotfiles/nixos_config#laptop

# Home Manager switch (standalone)
home:
	home-manager switch --flake ~/dotfiles/nixos_config

# Update flake inputs
update:
	nix flake update --flake ~/dotfiles/nixos_config
