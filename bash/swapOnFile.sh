#!/bin/bash
umask 066; dd bs=1M count=4096 if=/dev/zero of=/myswap; mkswap /myswap;
swapon /myswap

