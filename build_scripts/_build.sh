#!/usr/bin/bash

set -oue pipefail

mkdir -p /var/lib/alternatives

for script in /ctx/build_scripts/*-*.sh; do
	printf "::group::\e[1;33m ===%s===\e[0m\n" "$(basename "$script")"
	$script
	printf "::endgroup::\n"
done

set -x

ostree container commit
bootc container lint