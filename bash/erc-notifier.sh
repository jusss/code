#!/bin/bash
### use quote for $1 and $2 will not split by space in them
racket ~/lab2/notifier.rkt "$1" "$2" &
pid=$!
sleep 3
kill -9 $pid
