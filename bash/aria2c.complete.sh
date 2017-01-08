#!/bin/bash
echo "Called with [$1] [$2] [$3]"
### aria2c --on-download-complete hook.sh http://example.org/file.iso
### Called with [1]               [1]     [/path/to/file.iso]
### this script will receive three parameters from aria2c when you use --on-download-complete option
### These arguments are: GID, the number of files and file path
/usr/bin/env DISPLAY=$DISPLAY ~/lab/notifier.py "aria2c" "download complete!"
### /usr/bin/poweroff

