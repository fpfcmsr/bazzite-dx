#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Starting system cleanup"

# repo management
sed -i 's@enabled=1@enabled=0@g' /etc/yum.repos.d/vscode.repo

# Remove autostart files
rm /etc/skel/.config/autostart/steam.desktop

# Clean package manager cache
dnf5 clean all

# Clean temporary files
rm -rf /tmp/*

# Cleanup the entirety of `/var`.
# None of these get in the end-user system and bootc lints get super mad if anything is in there
rm -rf /var
mkdir -p /var

# Commit and lint container
bootc container lint || true

log "Cleanup completed"
