#!/bin/bash
count=0;for i in *.srt; do mv "$i" "$count"; count=$((count+1)); done;

