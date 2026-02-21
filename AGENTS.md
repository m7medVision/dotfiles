# AGENTS.md

This repository is a personal NixOS + Home Manager flake, plus assorted dotfiles under `.config/`.
Agents working here should optimize for **safe evaluation/activation** (Nix) and **minimal, reversible changes**.

## Repo map

- `nixos_config/flake.nix` — flake inputs/outputs (NixOS config entrypoint)
- `nixos_config/hosts/laptop/` — host-specific NixOS modules
- `nixos_config/home/mohammed/` — Home Manager configuration
  - `home.nix` — imports list (main HM module)
  - `modules/` — modular HM config
    - `packages/{apps,dev-tools,utils}.nix`
    - `programs/{git,gh,zen-browser,vicinae}.nix`
    - `symlinks.nix` — dotfile symlinks via Home Manager
- `.config/` — app configs (typically symlinked into place)
- `justfile` — common operational commands (preferred entrypoint)

## Commands (build / test / lint / format)

### Day-to-day (preferred): `just`

`/home/mohammed/dotfiles/justfile` defines:

```bash
just rebuild   # nh os switch ~/dotfiles/nixos_config --hostname laptop
just build     # nh os build  ~/dotfiles/nixos_config --hostname laptop
just update    # nix flake update --flake ~/dotfiles/nixos_config
just clean     # nh clean all
```

Notes:
- `nh` is configured in `nixos_config/hosts/laptop/nh.nix` (sets flake path).
- These commands are the closest thing this repo has to “build/tests”.

### Direct NixOS rebuild (when not using `nh`)

```bash
sudo nixos-rebuild build --flake ~/dotfiles/nixos_config#laptop
sudo nixos-rebuild switch --flake ~/dotfiles/nixos_config#laptop
sudo nixos-rebuild dry-activate --flake ~/dotfiles/nixos_config#laptop
sudo nixos-rebuild rollback
```

### Home Manager (standalone)

```bash
home-manager switch --flake ~/dotfiles/nixos_config
```

### Flake evaluation / checks

This flake currently does **not** define custom `checks`.
Still useful:

```bash
nix flake show ~/dotfiles/nixos_config
nix flake metadata ~/dotfiles/nixos_config
nix flake check ~/dotfiles/nixos_config        # may be a no-op beyond evaluation
```

### Lint / format / tests

- There is **no repo-wide lint/test runner** (no CI workflows, no package.json, no Makefile).
- Formatting is primarily editor-driven.
  - Neovim `conform` config includes `shfmt` for `sh`:
    `.config/nvim/lua/mohammed/plugins/conform.lua`.
- If you introduce a formatter/linter (e.g. `alejandra`, `nixfmt-rfc-style`, `statix`, `deadnix`, `treefmt`), add explicit commands here.

### “Run a single test”

There are no unit tests in this repo.
The closest “single test” is building a specific target:

```bash
# Build the laptop system without switching
sudo nixos-rebuild build --flake ~/dotfiles/nixos_config#laptop

# Or via nh:
nh os build ~/dotfiles/nixos_config --hostname laptop
```

## Cursor / Copilot rules

- No `.cursor/rules/`, `.cursorrules`, or `.github/copilot-instructions.md` exist in this repository at the time of writing.

## Code style (match existing patterns)

### Nix

**Indentation / formatting**
- 2-space indent throughout.
- Prefer small, readable attribute sets; nest for grouping.
- Use `let … in { … }` for small helpers (see `modules/programs/zen-browser.nix`).

**Module signatures**
- Use `{ ... }:` for modules that don’t need arguments.
- When needed, destructure only what you use and keep `...`:

```nix
{ pkgs, inputs, lib, config, ... }: {
  # ...
}
```

Observed examples:
- `home/mohammed/modules/packages/apps.nix`: `{ pkgs, ... }:`
- `home/mohammed/modules/programs/zen-browser.nix`: `{ pkgs, inputs, lib, ... }: { ... }`

**Imports**
- `imports = [ ... ];` with one entry per line.
- In `home.nix`, keep imports grouped by category (core / packages / programs).

**Packages modules**
- Prefer `home.packages = with pkgs; [ ... ];`
- Group with `#` category headers and keep package names alphabetical within a category.

**Lists**
- Prefer one element per line for long lists.
- For lists of attrsets, one object per “block” (see `keyboardShortcuts` in `zen-browser.nix`).

**Strings**
- Use `"..."` for normal strings.
- Use `'' ... ''` for multi-line strings.

**Flake inputs**
- Keep inputs commented and grouped.
- For third-party inputs, set `inputs.nixpkgs.follows = "nixpkgs"` (or explicitly follow `nixpkgs-unstable` if that dependency needs it).

**Symlinks**
- Use Home Manager’s out-of-store symlinks for dotfiles:

```nix
home.file.".config/appname".source =
  config.lib.file.mkOutOfStoreSymlink "/home/mohammed/dotfiles/.config/appname";
```

### Shell (bash/zsh)

If adding scripts:
- Use `#!/usr/bin/env bash` (or `zsh` if truly zsh-specific).
- Use strict mode for bash:

```bash
set -euo pipefail
```

- Prefer `[[ ... ]]` tests, quote variables, and use `local` in functions.
- Format with `shfmt` (consistent with Neovim configuration).

### Naming conventions

- Nix modules: `kebab-case.nix` (e.g. `dev-tools.nix`, `zen-browser.nix`).
- Hosts: lowercase (e.g. `laptop`).
- Nix attr names: follow upstream option names; otherwise use `camelCase`.
- Shell vars: `UPPER_SNAKE_CASE` for exported env vars; `lower_snake_case` for locals.

### Error handling / safety (Nix)

- Prefer `nixos-rebuild build` (or `just build`) before switching.
- When enabling services/programs, set `enable = true;` explicitly.
- Avoid large refactors in the same change as functional changes.

**Common gotchas**
- Flakes only see files tracked by git. If you add new files, ensure they’re added to git before running rebuilds.
- Keep previous generations available for rollback.

## Git workflow

- Use small commits with a clear “why”.
- Before committing changes that affect the system, run a build:
  - `just build` or `sudo nixos-rebuild build --flake ~/dotfiles/nixos_config#laptop`.
