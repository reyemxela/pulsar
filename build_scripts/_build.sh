#!/usr/bin/bash

set -oue pipefail

mkdir -p /var/lib/alternatives

for script in /ctx/build_scripts/*-*.sh; do
	printf "::group:: ===%s===\n" "$(basename "$script")"
	$script
	printf "::endgroup::\n"
done

set -x

ostree container commit
bootc container lint