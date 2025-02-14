#!/usr/bin/bash
set -euo pipefail

trap '[[ $BASH_COMMAND != echo\ \"===* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

# Package lists
FEDORA_PACKAGES=(
  android-tools
  aria2
  bleachbit
  cmatrix
  cockpit
  cockpit-bridge
  cockpit-machines
  cockpit-networkmanager
  cockpit-ostree
  cockpit-podman
  cockpit-selinux
  cockpit-storaged
  cockpit-system
  croc
  fish
  gnome-disk-utility
  gparted
  htop
  isoimagewriter
  john
  neovim
  nmap
  openrgb
  powerline-fonts
  qbittorrent
  rclone
  rustup
  ShellCheck
  shfmt
  solaar
  thefuck
  tor
  torbrowser-launcher
  torsocks
  virt-manager
  virt-viewer
  wireshark
  yt-dlp
  zsh
)

RPM_FUSION_PACKAGES=(
  audacious
  audacious-plugins-freeworld
  telegram-desktop
)

NEGATIVO17_MULTIMEDIA_PACKAGES=(
  HandBrake-cli
  HandBrake-gui
  mpv
  vlc
)

TERRA_PACKAGES=(
  audacity-freeworld
  coolercontrol
  ghostty
  hack-nerd-fonts
  starship
  ubuntu-nerd-fonts
  ubuntumono-nerd-fonts
  WoeUSB-ng
  youtube-music
)

DOCKER_PACKAGES=(
  containerd.io
  docker-buildx-plugin
  docker-ce
  docker-ce-cli
  docker-compose-plugin
)

log "Starting Amy OS build process"

# Install packages
log "Installing Fedora packages"
dnf5 -y install "${FEDORA_PACKAGES[@]}"

log "Installing RPM Fusion packages"
dnf5 -y install --enable-repo="*rpmfusion*" "${RPM_FUSION_PACKAGES[@]}"

log "Installing negativo17 Multimedia packages"
dnf5 -y install --enable-repo="fedora-multimedia" "${NEGATIVO17_MULTIMEDIA_PACKAGES[@]}"

log "Installing Terra packages"
dnf5 -y install --enable-repo="terra" "${TERRA_PACKAGES[@]}"

log "Installing Docker"
dnf5 -y install --enable-repo="docker-ce" "${DOCKER_PACKAGES[@]}"

# Install individual packages from their repos
log "Installing additional packages"
dnf5 -y install --enable-repo="brave-browser" brave-browser
dnf5 -y install --enable-repo="cloudflare-warp" cloudflare-warp
dnf5 -y install --enable-repo="signal-desktop" signal-desktop
dnf5 -y install --enable-repo="vscode" code

# Install packages from COPR repos
log "Installing COPR packages"
for repo in \
  "gloriouseggroll/nobara-41:lact scrcpy" \
  "ublue-os/staging:devpod"; do
  IFS=: read -r repo_name pkg_name <<<"$repo"
  dnf5 -y copr enable "$repo_name"
  dnf5 -y install "$pkg_name"
  dnf5 -y copr disable "$repo_name"
done

# Install Cursor
log "Installing Cursor"
# GUI version
curl --retry 3 -Lo /tmp/cursor-gui.appimage "https://downloader.cursor.sh/linux/appImage/x64"
chmod +x /tmp/cursor-gui.appimage
/tmp/cursor-gui.appimage --appimage-extract
mkdir -p /usr/share/cursor
cp -r ./squashfs-root/* /usr/share/cursor
rm -rf ./squashfs-root
chmod -R a+rX /usr/share/cursor
mkdir -p /usr/share/cursor/bin
install -m 0755 /usr/share/cursor/resources/app/bin/cursor /usr/share/cursor/bin/cursor
# Move Cursor AppImage wrapper script as fallback
mv /usr/bin/cursor /usr/bin/cursor-appimage
ln -s /usr/share/cursor/bin/cursor /usr/bin/cursor
cp -r /usr/share/cursor/usr/share/icons/hicolor/* /usr/share/icons/hicolor
# CLI version
curl --retry 3 -Lo /tmp/cursor-cli.tar.gz "https://api2.cursor.sh/updates/download-latest?os=cli-alpine-x64"
tar -xzf /tmp/cursor-cli.tar.gz -C /tmp
install -m 0755 /tmp/cursor /usr/share/cursor/bin/cursor-tunnel
ln -s /usr/share/cursor/bin/cursor-tunnel /usr/bin/cursor-cli

# Enable services
log "Enabling system services"
systemctl enable docker libvirtd

# Disable autostart
log "Disabling autostart"
rm -f /etc/xdg/autostart/{solaar.desktop,com.cloudflare.WarpTaskbar.desktop}
rm -f /etc/skel/.config/autostart/steam.desktop

# Configure system
log "Configuring system"
echo "import \"/usr/share/amyos/just/install-apps.just\"" >>/usr/share/ublue-os/justfile
echo "eval \"\$(starship init bash)\"" >>/etc/bashrc
echo "eval \"\$(thefuck --alias)\"" >>/etc/bashrc
echo "starship init fish | source" >>/etc/fish/config.fish
echo "thefuck --alias | source" >>/etc/fish/config.fish

log "Build process completed"
