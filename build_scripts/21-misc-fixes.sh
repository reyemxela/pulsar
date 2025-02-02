#!/usr/bin/bash

set -ouex pipefail

sed -i 's/bootc = .*/bootc = true/; s/rpm_ostree = .*/rpm_ostree = false/' /usr/share/ublue-os/topgrade.toml || true

sed -i 's/AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=none/' /etc/rpm-ostreed.conf