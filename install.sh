#!/bin/bash

# ==========================================
# Arch Linux Post Install Setup Script
# For: ThinkPad X1 Carbon Gen 8
# CPU: AMD Ryzen 5 4500U
# GPU: AMD Radeon (amdgpu)
# ==========================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
success() { echo -e "${GREEN}[DONE]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# ==========================================
# Welcome
# ==========================================
clear
echo "=========================================="
echo "      Arch Linux Post Install Setup       "
echo "=========================================="
echo ""

read -p "Enter your username: " USERNAME
read -p "Enter your GitHub username: " GITHUB_USER
read -p "Enter your GitHub noreply email: " GITHUB_EMAIL

echo ""

# Make sure the user actually exists before doing anything
if ! id "$USERNAME" &>/dev/null; then
    error "User '$USERNAME' does not exist. Did you create it during Arch install?"
fi

info "Starting setup for user: $USERNAME"
echo ""

# ==========================================
# AMD GPU Drivers
# Needed for: Hyprland GPU acceleration,
# screen tearing prevention, video playback
# ==========================================
info "Installing AMD GPU drivers..."

sudo pacman -S --noconfirm \
    mesa \
    vulkan-radeon \
    libva-mesa-driver \
    amd-ucode \
|| error "AMD driver install failed"

success "AMD GPU drivers installed"

# ==========================================
# AUR Helper (yay)
# Needed for: installing packages from AUR
# that are not in official Arch repos
# ==========================================
info "Installing yay AUR helper..."

sudo pacman -S --noconfirm git base-devel \
|| error "Failed to install git and base-devel"

if [ ! -d "/home/$USERNAME/yay" ]; then
    git clone https://aur.archlinux.org/yay.git /home/$USERNAME/yay \
    || error "Failed to clone yay"
fi

cd /home/$USERNAME/yay
makepkg -si --noconfirm || error "Failed to build yay"
cd /home/$USERNAME
rm -rf /home/$USERNAME/yay

success "yay installed"

# ==========================================
# Core System Packages
# ==========================================
info "Installing core system packages..."

sudo pacman -S --noconfirm \
    hyprland \
    wayland \
    xorg-xwayland \
    pipewire \
    pipewire-pulse \
    wireplumber \
    networkmanager \
    nm-connection-editor \
    polkit-gnome \
|| error "Failed to install core system packages"

success "Core system packages installed"

# ==========================================
# Desktop Stack
# hyprpaper  = wallpaper
# waybar     = status bar
# wofi       = app launcher
# dunst      = notifications
# grim+slurp = screenshots
# kitty      = terminal
# yazi       = file manager
# ffmpegthumbnailer+poppler = file previews
# ==========================================
info "Installing desktop stack..."

sudo pacman -S --noconfirm \
    kitty \
    waybar \
    wofi \
    dunst \
    hyprpaper \
    grim \
    slurp \
    yazi \
    ffmpegthumbnailer \
    poppler \
|| error "Failed to install desktop stack"

success "Desktop stack installed"

# ==========================================
# Fonts
# ==========================================
info "Installing fonts..."

sudo pacman -S --noconfirm \
    ttf-jetbrains-mono-nerd \
    noto-fonts \
    noto-fonts-emoji \
|| error "Failed to install fonts"

success "Fonts installed"

# ==========================================
# Daily Use Apps
# ==========================================
info "Installing daily apps..."

sudo pacman -S --noconfirm \
    firefox \
    mpv \
    imv \
    nano \
    curl \
    python-pip \
|| error "Failed to install daily apps"

success "Daily apps installed"

# ==========================================
# Security Tools (official repos only)
# All open source, widely audited,
# used by security professionals daily
# openbsd-netcat is the correct Arch package
# name - plain 'netcat' does not exist on Arch
# ==========================================
info "Installing security tools..."

sudo pacman -S --noconfirm \
    nmap \
    wireshark-qt \
    tcpdump \
    openbsd-netcat \
    hydra \
    john \
    hashcat \
|| error "Failed to install security tools"

success "Security tools installed"

# ==========================================
# Go Language + Go Based Security Tools
# Tools are installed as your user not root
# so they go to the correct home directory
# ==========================================
info "Installing Go and Go based security tools..."

sudo pacman -S --noconfirm go \
|| error "Failed to install Go"

# Run as your user not root
# so tools install to /home/USERNAME/go/bin
sudo -u "$USERNAME" bash << GOEOF
export GOPATH=/home/$USERNAME/go
export PATH=\$PATH:\$GOPATH/bin
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/OJ/gobuster/v3@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
GOEOF

success "Go tools installed"

# ==========================================
# Python Based Security Tools
# --break-system-packages is required on
# Arch to install pip packages system wide
# ==========================================
info "Installing Python security tools..."

sudo -u "$USERNAME" pip install \
    sqlmap \
    theharvester \
    sherlock-project \
    --break-system-packages \
|| error "Failed to install Python security tools"

success "Python security tools installed"

# ==========================================
# Enable NetworkManager
# Pipewire cannot be enabled as a user
# service before a desktop session exists
# so it autostarts via Hyprland exec-once
# ==========================================
info "Enabling services..."

sudo systemctl enable NetworkManager \
|| error "Failed to enable NetworkManager"

success "Services enabled"

# ==========================================
# Configure Git
# Runs as your user not root so config
# goes to your home directory not roots
# ==========================================
info "Configuring git..."

sudo -u "$USERNAME" git config --global user.name "$GITHUB_USER"
sudo -u "$USERNAME" git config --global user.email "$GITHUB_EMAIL"

success "Git configured"

# ==========================================
# Create Config Directories
# ==========================================
info "Creating config directories..."

mkdir -p /home/$USERNAME/.config/hypr
mkdir -p /home/$USERNAME/.config/waybar
mkdir -p /home/$USERNAME/.config/kitty
mkdir -p /home/$USERNAME/.config/wofi
mkdir -p /home/$USERNAME/.config/dunst

success "Config directories created"

# ==========================================
# Hyprland Config
# Using full /home/USERNAME path instead
# of ~ because hyprpaper does not always
# expand ~ correctly
# ==========================================
info "Writing Hyprland config..."

cat > /home/$USERNAME/.config/hypr/hyprland.conf << EOF
monitor=,preferred,auto,1

# Autostart
exec-once = pipewire
exec-once = pipewire-pulse
exec-once = wireplumber
exec-once = waybar
exec-once = hyprpaper
exec-once = dunst
exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
    col.active_border = rgba(cba6f7ff)
    col.inactive_border = rgba(595959aa)
    layout = dwindle
}

decoration {
    rounding = 10
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

animations {
    enabled = true
}

dwindle {
    pseudotile = true
    preserve_split = true
}

\$mainMod = SUPER

# Basic controls
bind = \$mainMod, Return, exec, kitty
bind = \$mainMod, Q, killactive
bind = \$mainMod, M, exit
bind = \$mainMod, Space, exec, wofi --show drun
bind = \$mainMod, F, fullscreen

# Move focus
bind = \$mainMod, left, movefocus, l
bind = \$mainMod, right, movefocus, r
bind = \$mainMod, up, movefocus, u
bind = \$mainMod, down, movefocus, d

# Move windows
bind = \$mainMod SHIFT, left, movewindow, l
bind = \$mainMod SHIFT, right, movewindow, r
bind = \$mainMod SHIFT, up, movewindow, u
bind = \$mainMod SHIFT, down, movewindow, d

# Workspaces
bind = \$mainMod, 1, workspace, 1
bind = \$mainMod, 2, workspace, 2
bind = \$mainMod, 3, workspace, 3
bind = \$mainMod, 4, workspace, 4
bind = \$mainMod, 5, workspace, 5

# Move window to workspace
bind = \$mainMod SHIFT, 1, movetoworkspace, 1
bind = \$mainMod SHIFT, 2, movetoworkspace, 2
bind = \$mainMod SHIFT, 3, movetoworkspace, 3
bind = \$mainMod SHIFT, 4, movetoworkspace, 4
bind = \$mainMod SHIFT, 5, movetoworkspace, 5

# Screenshot
bind = \$mainMod, S, exec, grim -g "\$(slurp)" /home/$USERNAME/screenshot.png
EOF

success "Hyprland config written"

# ==========================================
# Hyprpaper Config
# Full path used instead of ~ 
# ==========================================
info "Writing hyprpaper config..."

cat > /home/$USERNAME/.config/hypr/hyprpaper.conf << EOF
preload = /home/$USERNAME/wallpaper.webp
wallpaper = ,/home/$USERNAME/wallpaper.webp
EOF

success "Hyprpaper config written"

# ==========================================
# Waybar Config
# ==========================================
info "Writing Waybar config..."

cat > /home/$USERNAME/.config/waybar/config << 'EOF'
{
    "layer": "top",
    "position": "top",
    "height": 30,
    "modules-left": ["hyprland/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["pulseaudio", "network", "battery", "tray"],
    "clock": {
        "format": "{:%I:%M %p}",
        "format-alt": "{:%Y-%m-%d}"
    },
    "network": {
        "format-wifi": " {essid}",
        "format-ethernet": " connected",
        "format-disconnected": "disconnected"
    },
    "pulseaudio": {
        "format": " {volume}%",
        "format-muted": " muted"
    },
    "battery": {
        "format": " {capacity}%",
        "format-charging": " {capacity}%"
    }
}
EOF

success "Waybar config written"

# ==========================================
# Waybar Style
# ==========================================
info "Writing Waybar style..."

cat > /home/$USERNAME/.config/waybar/style.css << 'EOF'
* {
    font-family: "JetBrainsMono Nerd Font";
    font-size: 13px;
}

window#waybar {
    background-color: rgba(26, 27, 38, 0.9);
    color: #cba6f7;
    border-bottom: 2px solid rgba(203, 166, 247, 0.4);
}

#workspaces button {
    padding: 0 8px;
    color: #cba6f7;
}

#workspaces button.active {
    color: #89b4fa;
    border-bottom: 2px solid #89b4fa;
}

#clock, #network, #pulseaudio, #battery {
    padding: 0 10px;
    color: #cba6f7;
}
EOF

success "Waybar style written"

# ==========================================
# Kitty Config
# ==========================================
info "Writing Kitty config..."

cat > /home/$USERNAME/.config/kitty/kitty.conf << 'EOF'
font_family JetBrainsMono Nerd Font
font_size 12.0
background_opacity 0.9
confirm_os_window_close 0
EOF

success "Kitty config written"

# ==========================================
# Add Go to PATH permanently
# So security tools are accessible from
# terminal after every login
# ==========================================
info "Adding Go to PATH..."

# Only add if not already in bashrc
if ! grep -q "GOPATH" /home/$USERNAME/.bashrc; then
    echo 'export GOPATH=$HOME/go' >> /home/$USERNAME/.bashrc
    echo 'export PATH=$PATH:$GOPATH/bin' >> /home/$USERNAME/.bashrc
fi

success "Go PATH added"

# ==========================================
# Download Wallpaper
# ==========================================
info "Downloading wallpaper..."

curl -L -o /home/$USERNAME/wallpaper.webp \
    "https://images6.alphacoders.com/849/thumbbig-849827.webp" \
|| error "Failed to download wallpaper"

success "Wallpaper downloaded"

# ==========================================
# Clone Dotfiles from GitHub
# Skips if already exists so script is
# safe to run more than once
# ==========================================
info "Cloning dotfiles from GitHub..."

if [ ! -d "/home/$USERNAME/dotfiles" ]; then
    sudo -u "$USERNAME" git clone \
        https://github.com/$GITHUB_USER/dotfiles.git \
        /home/$USERNAME/dotfiles \
    || error "Failed to clone dotfiles"
else
    info "Dotfiles folder already exists, skipping"
fi

success "Dotfiles cloned"

# ==========================================
# Fix Permissions
# Everything should be owned by your user
# not root since script runs with sudo
# ==========================================
info "Setting permissions..."

chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
chown -R $USERNAME:$USERNAME /home/$USERNAME/dotfiles
chown -R $USERNAME:$USERNAME /home/$USERNAME/go
chown $USERNAME:$USERNAME /home/$USERNAME/wallpaper.webp
chown $USERNAME:$USERNAME /home/$USERNAME/.bashrc

success "Permissions set"

# ==========================================
# Done
# ==========================================
echo ""
echo "=========================================="
success "Setup complete!"
echo "=========================================="
echo ""
echo "  Type 'Hyprland' to start your desktop"
echo ""
