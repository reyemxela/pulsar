#!/usr/bin/bash

set -ouex pipefail

mkdir -p /var/roothome
chmod 0700 /var/roothome

ln -sf /run /var/run