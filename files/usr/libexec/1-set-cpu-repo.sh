#!/bin/bash
set -euo pipefail

CPU_ARCH="$1"

if [ -z "$CPU_ARCH" ]; then
    echo "CPU architecture not provided. Defaulting to v3."
    CPU_ARCH="v3"
fi

echo "Setting CPU architecture to $CPU_ARCH"

if [ "$CPU_ARCH" = "znver4" ]; then
    # The base image is cachyos-v4, so [cachyos-v4] already exists.
    # We must inject znver4 ABOVE v4 so it takes priority, while keeping v4 as a fallback.
    REPO_FILE=$(mktemp)
    cat > "$REPO_FILE" <<EOF
[cachyos-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

[cachyos-core-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

[cachyos-extra-znver4]
Include = /etc/pacman.d/cachyos-v4-mirrorlist

EOF

    # Insert znver4 right before the first [cachyos-v4] entry
    awk -v repo_file="$REPO_FILE" '/^#?\[cachyos-v4\]/ && !done { system("cat " repo_file); done=1 } { print }' /etc/pacman.conf > /etc/pacman.conf.tmp && mv /etc/pacman.conf.tmp /etc/pacman.conf
    rm -f "$REPO_FILE"

    # Synchronize and force reinstall to pull the znver4 binaries over the v4 ones
    echo "Synchronizing package databases..."
    pacman -Syy
    
    echo "Reinstalling packages to apply znver4 optimizations..."
    pacman -Qqn | pacman -S --noconfirm -

else
    # If v4 or v3, the docker base images already have the correct pacman.conf.
    echo "Base image already configured for $CPU_ARCH. No repository injection needed."
fi

echo "CPU optimization step complete."