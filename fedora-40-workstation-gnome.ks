# perform kickstart installation from first optical drive
cdrom

# kickstart installation in text mode
text --non-interactive

# accept any end user license agreement without user input
eula --agreed

# run initial setup application on first time system booted
firstboot --enable

# on completion of installation reboot and attempt to eject cdrom
reboot --eject

# enable firewall
firewall --enabled --ssh --http

# keyboard layout
keyboard --vckeymap=us --xlayouts='us'

# set default langauge
lang en_US

# set root password
rootpw --iscrypted --lock <PASS>

# enable selinux
selinux --enforcing

# enabled services
services --enabled=chronyd,firewalld,gdm

# disabled services
services --disabled=cups

# set time zone
timezone Australia/Canberra

# set time source
timesource --ntp-server 0.au.pool.ntp.org
timesource --ntp-server 1.au.pool.ntp.org
timesource --ntp-server 2.au.pool.ntp.org
timesource --ntp-server 3.au.pool.ntp.org

# create users
user --name=<USERNAME> --shell=/bin/bash --iscrypted --password=<PASS>
user --name=svc_ansible --shell=/bin/bash --iscrypted --password=<PASS>
user --name=svc_monitor --shell=/bin/bash --iscrypted --password=<PASS>
user --name=svc_backup --shell=/bin/bash --iscrypted --password=<PASS>

# network configuration
network --bootproto=dhcp --active

# ignore all other disks
ignoredisk --only-use=sda

# clear any existing partitions
clearpart -drives=sda --all

# automatic partitioning
autopart --type=btrfs

# setup boot loader
bootloader

# disk partitioning
part /boot --fstype="xfs" --ondisk=sda --size=1024
part /boot/efi --fstype="efi" --ondisk=sda --size=600 --fsoptions="umask=0077,shortname=winnt"
part btrfs.720 --fstype="btrfs" --ondisk=sda --grow

# btrfs file system
btrfs none --label=system btrfs.720
btrfs / --subvol --name=root LABEL=system
btrfs /home --subvol --name=home LABEL=system

%packages
@base-x
alacritty
bash
bash-completion
dejavu-sans-mono-fonts
dnf-automatic
distrobox
firewalld
fuse
gdm
gnome-system-monitor
gnome-shell
gnome-shell-extension-apps-menu
gnome-shell-extension-blur-my-shell
gnome-shell-extension-caffeine
gnome-shell-extension-dash-to-dock
gnome-shell-extension-forge
gnome-shell-extension-frippery-applications-menu
gnome-shell-extension-openweather
gnome-shell-extension-places-menu
mozilla-fira-mono-fonts
mozilla-fira-sans-fonts
nautilus
NetworkManager-wifi
openssh-server
onedrive
policycoreutils
policycoreutils-python-utils
selinux-policy
selinux-policy-devel
vim
zram

%end

%post

# flatpak system applications
flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --system -y flathub \
    org.gnome.Loupe \
    org.gnome.baobab \
    org.gnome.TextEditor \
    org.gnome.Logs \
    org.gnome.font-viewer \
    org.gnome.Connections \
    org.gnome.Extensions \
    org.gnome.Totem \
    org.gnome.Music \
    ca.desrt.dconf-editor \
    org.gnome.seahorse.Application \
    io.github.realmazharhussain.GdmSettings \
    page.codeberg.libre_menu_editor.LibreMenuEditor \
    org.libreoffice.LibreOffice \
    page.codeberg.JakobDev.jdFlatpakSnapshot \
    com.github.tchx84.Flatseal

# enable gdm
systemctl enable gdm.service




### Probably move the below into profile.d
flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# user applications
flatpak install --user -y flathub \ 
    com.bitwarden.desktop \
    com.github.tchx84.Flatseal \
    com.visualstudio.code \
    com.valvesoftware.Steam \
    com.github.marhkb.Pods \
    com.discordapp.Discord \
    de.haeckerfelix.Fragments \
    io.github.dvlv.boxbuddyrs \
    md.obsidian.Obsidian \
    me.proton.Mail \
    net.lutris.Lutris \
    org.gnome.Boxes \
    org.mozilla.firefox

# enable window min, max, and close
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'

# set inactive to do nothing
dbus-launch gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-timeout '0'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-timeout '0'

# setup onedrive (will require user input to complete)
touch /home/<USERNAME>/.config/systemd/user/onedrive.service
cat <<EOF > /home/<USERNAME>/.config/systemd/user/onedrive.service
[Unit]
Description=OneDrive client
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/onedrive --monitor

[Install]
WantedBy=default.target
EOF

%end