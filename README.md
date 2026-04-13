# Bespoke Scripts

A collection of utility scripts for system administration, game management, and terminal formatting.

## Scripts

### **Starbound/**

#### `Starbound_mod_mv.fish`
Fish shell script for managing Starbound mods. Unpacks Workshop `.pak` files from Steam using xStarbound's asset_unpacker, extracts metadata, and organizes mods into a dedicated mods directory by their internal names.

#### `xStarbound-linux-installer.fish`
Automated installation script for xStarbound on Linux. Handles downloading and extracting binaries (static/dynamic), assets, documentation, and optional compatibility patches (MyEnternia, Frackin' Universe, NPC Mechs). Provides extensive CLI options for customization.

### **backup_game_savefiles.fish**
Fish function for creating versioned backups and restoring snapshots of game save files. Supports The Binding of Isaac and Dead Cells with timestamped snapshots. Usage:
- `bkpsv isaac` — create backup
- `bkpsv isaac restore [SNAPSHOT]` — restore from snapshot
- `bkpsv deadcells [restore SNAPSHOT]` — same for Dead Cells

### **emerge-prettifier.pl**
Perl script that prettifies Portage `emerge` output. Applies terminal formatting including bold blue section headers, bullet point conversion, path dimming, and intelligent indentation for build steps. Handles ANSI color codes and line wrapping while preserving readability.

### **xmodmap_visualizer.py**
Python utility to visualize the current X11 keyboard layout in the terminal. Parses X11 keysym definitions and displays alphanumeric and numeric keypad layouts as ASCII keycap grids, showing all four shift states (normal, shift, AltGr, AltGr+shift).

## Language Composition

- **Perl**: 44.5%
- **Shell**: 40.6%
- **Python**: 14.9%