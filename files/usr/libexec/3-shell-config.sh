#!/bin/bash
set -euo pipefail

echo "Configuring global environments for Bash, Zsh, and Fish..."

# -----------------------------------------------------------------------------
# 1. Global Environment Variables (Applies to Desktop Environment & GUI apps)
# -----------------------------------------------------------------------------
mkdir -p /etc/profile.d
cat > /etc/profile.d/boppos-wayland.sh <<'EOF'
# Forces Electron apps (Discord, VS Code, Obsidian) to run natively on Wayland.
export ELECTRON_OZONE_PLATFORM_HINT="auto"
EOF
chmod +x /etc/profile.d/boppos-wayland.sh

# -----------------------------------------------------------------------------
# 2. BASH Configuration
# -----------------------------------------------------------------------------
cat >> /etc/bash.bashrc <<'EOF'
# Added by BoppOS build process

if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "/var/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

eval "$(starship init bash)"
eval "$(zoxide init bash)"
alias ls='eza --icons'
EOF

# -----------------------------------------------------------------------------
# 3. ZSH Configuration
# -----------------------------------------------------------------------------
mkdir -p /etc/zsh
cat >> /etc/zsh/zshrc <<'EOF'
# Added by BoppOS build process

if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -x "/var/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
alias ls='eza --icons'
EOF

# -----------------------------------------------------------------------------
# 4. FISH Configuration
# -----------------------------------------------------------------------------
# Fish uses a conf.d directory for drop-in snippets, which is much cleaner.
mkdir -p /etc/fish/conf.d
cat > /etc/fish/conf.d/boppos.fish <<'EOF'
# Added by BoppOS build process

# Homebrew setup for fish syntax
if test -x /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -x /var/home/linuxbrew/.linuxbrew/bin/brew
    eval (/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# Fish does not natively read /etc/profile.d/ on some setups, 
# so we export the Wayland hint here just to be safe for terminal launches.
set -gx ELECTRON_OZONE_PLATFORM_HINT "auto"

# We check if the binaries exist first so fish doesn't throw red errors
if command -v starship >/dev/null
    starship init fish | source
end

if command -v zoxide >/dev/null
    zoxide init fish | source
end

if command -v eza >/dev/null
    alias ls='eza --icons'
end
EOF

echo "Shell configuration complete."