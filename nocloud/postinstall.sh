#!/usr/bin/env bash
set -Eeuo pipefail

exec > >(tee -a /var/log/vinicius-postinstall.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

MARKER=/var/lib/vinicius-postinstall.done
[[ -e "$MARKER" ]] && exit 0

log() { printf '[%s] %s\n' "$(date -Is)" "$*"; }
retry() {
  local attempt=1
  until "$@"; do
    if (( attempt >= 4 )); then
      return 1
    fi
    log "Falha na tentativa ${attempt}: $*"
    attempt=$((attempt + 1))
    sleep $((attempt * 10))
  done
}
wait_for_apt() {
  while fuser /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock >/dev/null 2>&1; do
    sleep 5
  done
}
install_optional() {
  local pkg
  for pkg in "$@"; do
    apt-get install -y "$pkg" || log "Pacote opcional indisponível: $pkg"
  done
}

trap 'log "ERRO na linha $LINENO. Consulte /var/log/vinicius-postinstall.log"' ERR

source /etc/os-release
CODENAME="${VERSION_CODENAME:-noble}"
DEB_ARCH="$(dpkg --print-architecture)"
USER_NAME="$(getent passwd | awk -F: '$3 >= 1000 && $3 < 60000 && $1 != "nobody" {print $1; exit}')"
if [[ -z "$USER_NAME" ]]; then
  log "Nenhum usuário desktop encontrado. O serviço tentará novamente no próximo boot."
  exit 1
fi
USER_HOME="$(getent passwd "$USER_NAME" | cut -d: -f6)"

log "Provisionando Ubuntu para $USER_NAME em $CODENAME/$DEB_ARCH"
wait_for_apt
retry apt-get update
apt-get install -y \
  software-properties-common curl wget ca-certificates gnupg git xz-utils \
  build-essential cmake ninja-build pkg-config dkms linux-headers-generic linux-firmware mokutil \
  python3-full python3-pip python3-venv pipx flatpak gnome-software-plugin-flatpak \
  openssh-server ufw fail2ban net-tools iproute2 dnsutils traceroute mtr-tiny nmap tcpdump \
  ethtool iperf3 socat jq ripgrep fzf htop btop tree tmux unzip zip p7zip-full rsync rclone \
  vim nano shellcheck lsof strace usbutils pciutils lshw smartmontools nvme-cli lm-sensors \
  bluez blueman libinput-tools evtest wl-clipboard xclip dconf-cli gnome-tweaks wireguard-tools

install_optional \
  language-pack-en language-pack-gnome-en language-pack-ja language-pack-gnome-ja \
  language-pack-pt language-pack-gnome-pt ibus-mozc mozc-data mozc-server logiops \
  gnome-shell-extension-dashtodock gnome-shell-extension-desktop-icons-ng \
  gnome-shell-extension-tiling-assistant gnome-shell-extension-appindicator

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
cat >/etc/apt/sources.list.d/docker.sources <<EOF_DOCKER
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${DEB_ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
EOF_DOCKER

curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
  https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor --yes -o /usr/share/keyrings/microsoft.gpg
cat >/etc/apt/sources.list.d/vscode.sources <<EOF_CODE
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: ${DEB_ARCH}
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF_CODE

retry apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt-get install -y brave-browser || log "Brave não disponível para ${DEB_ARCH}"
apt-get install -y code || log "VS Code não disponível para ${DEB_ARCH}"
systemctl enable --now docker containerd ssh fail2ban bluetooth
usermod -aG docker "$USER_NAME"

case "$(uname -m)" in
  x86_64) NODE_ARCH=x64 ;;
  aarch64|arm64) NODE_ARCH=arm64 ;;
  *) NODE_ARCH="" ;;
esac
if [[ -n "$NODE_ARCH" ]]; then
  NODE_BASE=https://nodejs.org/dist/latest-v24.x
  NODE_FILE="$(curl -fsSL "$NODE_BASE/SHASUMS256.txt" | awk -v a="linux-${NODE_ARCH}.tar.xz" '$2 ~ a"$" {print $2; exit}')"
  if [[ -n "$NODE_FILE" ]]; then
    tmp="$(mktemp -d)"
    curl -fsSL "$NODE_BASE/$NODE_FILE" -o "$tmp/$NODE_FILE"
    (cd "$tmp" && curl -fsSL "$NODE_BASE/SHASUMS256.txt" | grep "  $NODE_FILE$" | sha256sum -c -)
    rm -rf /usr/local/lib/nodejs
    install -d /usr/local/lib/nodejs
    tar -xJf "$tmp/$NODE_FILE" -C /usr/local/lib/nodejs --strip-components=1
    ln -sf /usr/local/lib/nodejs/bin/node /usr/local/bin/node
    ln -sf /usr/local/lib/nodejs/bin/npm /usr/local/bin/npm
    ln -sf /usr/local/lib/nodejs/bin/npx /usr/local/bin/npx
    /usr/local/bin/npm install -g corepack@latest
    /usr/local/lib/nodejs/bin/corepack enable
    /usr/local/lib/nodejs/bin/corepack prepare pnpm@latest --activate
    ln -sf /usr/local/lib/nodejs/bin/pnpm /usr/local/bin/pnpm || true
    rm -rf "$tmp"
  fi
fi

flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub org.telegram.desktop || true
flatpak install --system -y flathub com.discordapp.Discord || true
flatpak install --system -y flathub com.mattjakeman.ExtensionManager || true

cat >/etc/ssh/sshd_config.d/90-vinicius.conf <<'EOF_SSH'
PermitRootLogin no
PasswordAuthentication yes
PubkeyAuthentication yes
KbdInteractiveAuthentication no
X11Forwarding no
EOF_SSH
sshd -t
systemctl restart ssh
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw --force enable

cat >/etc/logid.cfg <<'EOF_LOGID'
devices: (
  {
    name: "Wireless Mouse MX Master 3";
    smartshift: { on: true; threshold: 10; torque: 50; };
    hiresscroll: { hires: true; invert: false; target: false; };
    dpi: 1000;
    buttons: (
      { cid: 0xc3; action = { type: "Gestures"; gestures: (
        { direction: "Up"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; },
        { direction: "Down"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; },
        { direction: "Left"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_PAGEUP"]; }; },
        { direction: "Right"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_LEFTMETA", "KEY_PAGEDOWN"]; }; },
        { direction: "None"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; }
      ); }; },
      { cid: 0x53; action = { type: "Keypress"; keys: ["KEY_LEFTALT", "KEY_LEFT"]; }; },
      { cid: 0x56; action = { type: "ToggleSmartshift"; }; },
      { cid: 0x52; action = { type: "Keypress"; keys: ["KEY_PLAYPAUSE"]; }; },
      { cid: 0xc4; action = { type: "Keypress"; keys: ["KEY_LEFTALT", "KEY_TAB"]; }; }
    );
  },
  {
    name: "MX Master 3S";
    smartshift: { on: true; threshold: 10; torque: 50; };
    hiresscroll: { hires: true; invert: false; target: false; };
    dpi: 1000;
  }
);
EOF_LOGID
systemctl enable --now logid || true

if lsusb -d 2c4e:0115 >/dev/null 2>&1; then
  modprobe btusb || true
  sleep 3
  if ! bluetoothctl list 2>/dev/null | grep -q Controller; then
    rm -rf /opt/ma530
    git clone --depth=1 https://github.com/vcanonici/Mercusys-MA530-Ubuntu-Driver.git /opt/ma530
    (cd /opt/ma530 && MA530_USE_DKMS=1 ./scripts/agent_install.sh) || log "Fallback DKMS do MA530 falhou; consulte o log."
  fi
fi

install -d -m 0755 -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/.local/bin" "$USER_HOME/.config/autostart"
cat >"$USER_HOME/.local/bin/apply-vinicius-gnome" <<'EOF_GNOME'
#!/usr/bin/env bash
set -u

gsettings set org.gnome.shell.keybindings show-screenshot-ui "['<Ctrl><Shift>s']" || true
gsettings set org.gnome.mutter check-alive-timeout 30000 || true
gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click false || true
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true || true
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.28125 || true
gsettings set org.gnome.desktop.peripherals.touchpad click-method areas || true
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true || true
gsettings set org.gnome.desktop.peripherals.mouse accel-profile adaptive || true
gsettings set org.gnome.desktop.peripherals.mouse speed 0.6 || true
gsettings set org.gnome.desktop.input-sources sources "[('xkb','br'),('xkb','us'),('ibus','mozc-jp'),('xkb','jp'),('xkb','pt')]" || true

gnome-extensions disable ubuntu-dock@ubuntu.com || true
for ext in dash-to-dock@micxgx.gmail.com ding@rastersoft.com tiling-assistant@ubuntu.com ubuntu-appindicators@ubuntu.com; do
  gnome-extensions enable "$ext" || true
done

gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM || true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false || true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed false || true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true || true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide true || true
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 42 || true
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode DYNAMIC || true

rm -f "$HOME/.config/autostart/vinicius-gnome.desktop"
EOF_GNOME
chmod 0755 "$USER_HOME/.local/bin/apply-vinicius-gnome"
cat >"$USER_HOME/.config/autostart/vinicius-gnome.desktop" <<EOF_DESKTOP
[Desktop Entry]
Type=Application
Name=Aplicar configurações Vinicius
Exec=${USER_HOME}/.local/bin/apply-vinicius-gnome
X-GNOME-Autostart-enabled=true
NoDisplay=true
EOF_DESKTOP
chown -R "$USER_NAME:$USER_NAME" "$USER_HOME/.local" "$USER_HOME/.config"

apt-get autoremove -y
apt-get clean
install -d /var/lib
printf 'completed=%s\n' "$(date -Is)" >"$MARKER"
log "Provisionamento concluído. Reinicie a sessão para carregar todas as extensões."
