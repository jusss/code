#!/usr/bin/env bash
#
# adb_push.sh — copy files to Android device via local find + adb push
# usage: ./adb_push.sh [local_dir_B] [remote_dir_A]
#        B = local source dir (default: current dir)
#        A = remote destination dir on the device (default: /sdcard/DCIM)
#
# Subdirectory handling: the local tree is walked recursively with find;
# every directory is created on the device first (mkdir -p), then each
# file is pushed to its mirrored remote path. NUL-delimited find output
# makes filenames with spaces/newlines safe.

# **`adb_push.sh` — recursive push**
# - Local tree walked with `find . -mindepth 1 -print0` (parents before contents)
# - Every directory is created on the device first via `adb shell mkdir -p "$A/$rel"`, **then** files push to `$A/$rel`
# - Symlinks are pushed as links, not followed into infinite loops; NUL-delimited `find` survives even newline-in-filename



B="${1:-.}"              # local source dir
A="${2:-/sdcard/DCIM}"   # remote destination dir on the device
LIST="/tmp/b.txt"        # local file list output

B="${B%/}"               # strip trailing slash if present
A="${A%/}"

# make sure a device is connected
if ! adb get-state >/dev/null 2>&1; then
    echo "error: no adb device connected" >&2
    exit 1
fi

# make sure the local source dir exists
if [ ! -d "$B" ]; then
    echo "error: local dir not found: $B" >&2
    exit 1
fi

cd "$B" || exit 1

# 1. walk the local tree (parents listed before their contents) -> /tmp/b.txt
find . -mindepth 1 -print0 > "$LIST"

# make sure the remote destination dir exists
adb shell "mkdir -p \"$A\"" || { echo "error: cannot create remote dir: $A" >&2; exit 1; }

# 2. loop through the list: mkdir remote dirs, push files
while IFS= read -r -d '' p || [ -n "$p" ]; do
    rel="${p#./}"                        # ./sub/file.txt -> sub/file.txt
    if [ -d "$p" ] && [ ! -L "$p" ]; then
        echo "  mkdir: $A/$rel"
        adb shell "mkdir -p \"$A/$rel\"" || echo "warn: failed to mkdir $rel" >&2
    else
        echo "  push: $B/$rel -> $A/$rel"
        adb push "$p" "$A/$rel" || echo "warn: failed to push $rel" >&2
    fi
done < "$LIST"

echo "done. file list saved to $LIST"
