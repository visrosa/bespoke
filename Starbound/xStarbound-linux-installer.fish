#! /usr/bin/env fish
# xStarbound installer script for Linux (Fish shell)
# Based on release notes for v4.0.6

# ------------------------
# Defaults
# ------------------------
set release_url https://github.com/xStarbound/xStarbound/releases/latest/download
set docs_file "docs.zip"
set linux_static_file "linux-static.tar.gz"
set linux_dynamic_file "linux.tar.gz"
set linux_file $linux_static_file
set linux_utils_file "linux-utils.tar.gz"
set xSBassets_file "xSBassets.pak"
set xSBCompat_file "xSBCompat.pak"
set ME_patch_file "MyEnterniaScriptPatch.pak"
set frackin_patch_file "FrackinPatch.pak"
set NPCMechs_patch_file "NPCMechsScriptPatch.pak"

set prefix (pwd)/xStarbound
set include_docs true
set cleanup true
set create_empty_dirs true
set patch_ME false
set patch_frackin false
set patch_NPCMechs false
set downloader "wget -qc"
set verbose false

# -----------------
# Argument parsing
# -----------------
argparse \
    'prefix=' \
    'use-static-build' 'use-dynamic-build' \
    'include-docs' 'no-docs' \
    'cleanup' 'no-cleanup' \
    'create-empty-dirs' 'no-empty-dirs' \
    'patch-me' 'patch-frackin' 'patch-npcmechs' 'patch-all' \
    'downloader=' \
    'verbose' \
    'help' \
    -- $argv

if set -ql _flag_help
    echo "Usage: (script) [options]"
    echo
    echo "Options:"
    echo "  --prefix PATH              Install to PATH (default: ./xStarbound)"
    echo "  --use-static-build         Install statically linked Linux binaries (default)"
    echo "  --use-dynamic-build        Install dynamically linked Linux binaries"
    echo "  --include-docs             Download and unpack docs (default)"
    echo "  --no-docs                  Skip docs"
    echo "  --cleanup                  Remove archives after extraction (default)"
    echo "  --no-cleanup               Keep archives"
    echo "  --create-empty-dirs        Create empty Starbound dirs (default)"
    echo "  --no-empty-dirs            Skip creating empty dirs"
    echo "  --patch-me                 Install MyEnternia patch"
    echo "  --patch-frackin            Install Frackin' Universe patch"
    echo "  --patch-npcmechs           Install NPC Mechs patch"
    echo "  --patch-all                Install all available patches"
    echo "  --downloader CMD           Command to use for downloads (default: wget -c)"
    echo "  --verbose                  Show extraction details"
    echo "  --help                     Show this message"
    exit 0
end

# Apply options
if set -ql _flag_prefix
    set prefix (realpath $_flag_prefix)
end

if set -ql _flag_use_dynamic_build
    set linux_file $linux_dynamic_file
end
if set -ql _flag_use_static_build
    set linux_file $linux_static_file
end

if set -ql _flag_no_docs
    set include_docs false
end
if set -ql _flag_include_docs
    set include_docs true
end

if set -ql _flag_no_cleanup
    set cleanup false
end
if set -ql _flag_cleanup
    set cleanup true
end

if set -ql _flag_no_empty_dirs
    set create_empty_dirs false
end
if set -ql _flag_create_empty_dirs
    set create_empty_dirs true
end

if set -ql _flag_patch_me
    set patch_ME true
end
if set -ql _flag_patch_frackin
    set patch_frackin true
end
if set -ql _flag_patch_npcmechs
    set patch_NPCMechs true
end
if set -ql _flag_patch_all
    set patch_ME true
    set patch_frackin true
    set patch_NPCMechs true
end

if set -ql _flag_downloader
    set downloader $_flag_downloader
end

if set -ql _flag_verbose
    set verbose true
end

# ------------------------
# Install steps
# ------------------------
echo -n (set_color brmagenta --bold)"Installing "(set_color red --bold)"xStarbound"(set_color normal)". "
echo (set_color brmagenta) "Check "(set_color --italic)"--help"(set_color normal)(set_color brmagenta)" for usage options."(set_color normal)
echo -n (set_color magenta)"   Target directory: "(set_color cyan)"$prefix"(set_color normal)
echo (set_color grey --dim) " (change with --prefix PATH)"(set_color normal)
mkdir -p $prefix
cd $prefix

# Docs
if test $include_docs = "true"
    echo -n (set_color magenta)"📘 Downloading docs..."(set_color normal)
    echo (set_color grey --dim) "(disable with --no-docs)"(set_color normal)
    eval $downloader "$release_url/$docs_file"
    unzip -q $docs_file
    if test $cleanup = "true"
        rm $docs_file
    end
end

# Linux binaries + utils
mkdir -p xsb-linux
for f in $linux_file $linux_utils_file
    echo (set_color magenta)"📦 Downloading and extracting "(set_color cyan)"$f"(set_color normal)"..."
    eval $downloader "$release_url/$f"
    if test $verbose = "true"
        tar -xvzf $f -C xsb-linux
    else
        tar -xzf $f -C xsb-linux
    end
    if test $cleanup = "true"
        rm $f
    end
end

# Assets
mkdir -p xsb-assets
echo (set_color magenta)"🎨 Downloading assets..."(set_color normal)
eval $downloader "$release_url/$xSBassets_file" -P xsb-assets
echo (set_color magenta)"🎨 Downloading xSBCompat"(set_color normal)
eval $downloader "$release_url/$xSBCompat_file" -P xsb-assets

# Optional patches
mkdir -p mods
if test $patch_ME = "true"
    echo (set_color magenta)" 🧩 Installing "(set_color cyan)"MyEnternia patch"(set_color normal)"..."
    eval $downloader "$release_url/$ME_patch_file" -P mods
end
if test $patch_frackin = "true"
    echo (set_color magenta)" 🧩 Installing "(set_color cyan)"Frackin' Universe patch"(set_color normal)"..."
    eval $downloader "$release_url/$frackin_patch_file" -P mods
end
if test $patch_NPCMechs = "true"
    echo (set_color magenta)" 🧩 Installing "(set_color cyan)"NPC Mechs patch"(set_color normal)"..."
    eval $downloader "$release_url/$NPCMechs_patch_file" -P mods
end

# Empty dirs
if test $create_empty_dirs = "true"
    echo (set_color magenta)"📂 Creating empty Starbound directories..."(set_color normal)
    mkdir -p assets storage
end

echo (set_color brmagenta --bold)"Installation complete!"(set_color normal)
