

sudo apt update -y
sudo apt install -y  \
  openssh-sftp-server \
  network-manager \
  xserver-xorg \
  openbox \
  lightdm \
  dbus-x11 \
  chromium \
  curl \
  ca-certificates \
  gnupg \
  initramfs-tools \
  xinit \
  x11-xserver-utils

curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt -y install nodejs

node -v
npm -v

# sudo nano /boot/cmdline.txt
#quiet splash loglevel=0 vt.global_cursor_default=0
#root=UUID=xxxx rw quiet splash loglevel=0 vt.global_cursor_default=0

#NON SBC
#/etc/default/grub
#GRUB_CMDLINE_LINUX_DEFAULT="consoleblank=0"
#GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=0 vt.global_cursor_default=0 consoleblank=0"

# Create Kiosk User
sudo useradd -m -s /bin/bash kiosk || true
sudo passwd -d kiosk
sudo usermod -aG video,audio,input,render kiosk

sudo nano /etc/lightdm/lightdm.conf
# [Seat:*]
# autologin-user=kiosk
# autologin-user-timeout=0
# user-session=openbox

sudo -u kiosk mkdir -p /home/kiosk/.config/openbox
sudo -u kiosk nano /home/kiosk/.config/openbox/autostart
# #!/bin/sh

# # Disable screen blanking
# xset -dpms
# xset s off
# xset s noblank

# # Small delay to ensure display is ready
# sleep 1

# # Start Firefox in kiosk mode
# firefox-esr --kiosk --profile /home/kiosk/.firefox-kiosk file:///home/kiosk/index.html &


sudo systemctl edit getty@tty1
#If it opens an editor with content, delete everything inside so it’s empty.

sudo systemctl daemon-reexec
#This removes root auto-login on tty1.

sudo systemctl enable lightdm
sudo systemctl set-default graphical.target
systemctl status lightdm

# loginctl
# who

sudo nano /etc/systemd/system/family-calendar.service
# [Install]
# WantedBy=graphical.target

# [Unit]
# Description=Family Calendar Server
# After=network.target

# [Service]
# Type=simple
# User=root
# WorkingDirectory=/root/app
# ExecStart=/usr/bin/node server.js
# Restart=always
# RestartSec=5

# [Install]
# WantedBy=multi-user.target

sudo systemctl daemon-reload
sudo systemctl enable family-calendar
sudo systemctl start family-calendar