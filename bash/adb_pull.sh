#!/usr/bin/env bash
#
# adb_pull.sh — copy files from Android device via adb shell ls + adb pull
# usage: ./adb_pull.sh [remote_dir_A] [local_dir_B]
#
# Subdirectory handling: the remote tree is walked recursively; each file
# is pulled individually and the directory structure is mirrored under $B
# (including empty directories). Directories are recognized by the trailing
# '/' that `ls -p` appends.

# **`adb_pull.sh` — recursive pull**
# - Uses `ls -1Ap` → directories get a trailing `/`, which the script detects
# - Recurses into each subdirectory, mirroring the structure under `$B`
# - `mkdir -p` on the local side — even **empty remote dirs** are reproduced
# - Hidden dotfiles (`.hidden`) are now included (`-A` flag)

# **One remaining caveat:** on the *remote* side (pull), a filename containing a newline would still break line-based parsing — that's a limit of parsing `ls` output over adb shell. If you ever hit that edge case, the cleanest fix is `adb pull "$A/" "$B"` and letting adb walk the tree itself.


A="${1:-/sdcard/DCIM}"   # source dir on the device
B="${2:-.}"              # local destination (default: current dir)
LIST="/tmp/a.txt"        # top-level listing snapshot

A="${A%/}"               # strip trailing slash if present
B="${B%/}"               # ditto (cosmetic: avoids "dir//" in messages)

# make sure a device is connected
if ! adb get-state >/dev/null 2>&1; then
    echo "error: no adb device connected" >&2
    exit 1
fi

# 1. list top-level entries -> /tmp/a.txt  ('/' suffix marks directories)
if ! adb shell "ls -1Ap \"$A\"" > "$LIST"; then
    echo "error: cannot list remote dir: $A" >&2
    exit 1
fi

# 2. recursive copy: list entries, pull files, mirror dirs
pull_dir() {                       # $1 = remote dir, $2 = local dir
    local src="$1" dst="$2" f
    mkdir -p "$dst"                # create local dir (also covers empty dirs)
    # NOTE: `</dev/null` on every adb command below is essential. Commands
    # started inside the `while read` loop inherit the loop's stdin (the
    # `ls` pipe), and adb *reads* local stdin (it forwards it to the
    # device) — so it would swallow the rest of the listing and the loop
    # would stop after the first entry or two.
    adb shell "ls -1Ap \"$src\"" </dev/null | tr -d '\r' |
    while IFS= read -r f || [ -n "$f" ]; do
        [ -z "$f" ] && continue    # skip empty lines
        case "$f" in
        */)                        # entry ends with '/' -> subdirectory
            f="${f%/}"
            echo "  dir : $src/$f"
            pull_dir "$src/$f" "$dst/$f"
            ;;
        *)                         # regular file -> pull it
            echo "  pull: $src/$f -> $dst/"
            adb pull "$src/$f" "$dst" </dev/null || echo "warn: failed to pull $f" >&2
            ;;
        esac
    done
}

pull_dir "$A" "$B"

echo "done. top-level file list saved to $LIST"
