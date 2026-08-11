set -e

script_dir="$(dirname "$(readlink -f "$0")")"

# obtain gnunet namespaces from "$script_dir"/../.data/gnunet
# and put it into "$state_dir"/upm/config (as default namespace)

cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
[ "$cpu_vendor_id" = AuthenticAMD ] && ucode=ucode-amd
[ "$cpu_vendor_id" = GenuineIntel ] && ucode=ucode-intel

pacstrap -K /mnt base $ucode memtest86+-efi linux linux-firmware linux-firmware-marvell sof-firmware \
	fwupd btrfs-progs dosfstools opendoas nano bash-completion man-db \
	bluez pipewire-audio pipewire-pulse wireplumber \
	adobe-source-code-pro-fonts noto-fonts-emoji noto-fonts noto-fonts-cjk
# linux-stable initramfs-tools tpm2-tools cryptsetup
# base-full-firmware (firmware-linux for all) fwupd base-full-core
# nyagetty util-linux-dmesg bash-completion
# util-linux-fdisk util-linux-fstrim util-linux-mkfs btrfs-progs dosfstools exfatprogs
# elogind sway
# chrony less nano opendoas syslog-ng util-linux-zramctl
# pipewire bluez networkmanager modemmanager iputils dnsmasq geoclue
# fonts-noto fonts-noto-emoji-ttf fonts-noto-sans-cjk
# gtk4 libadwaita gtksourceview gst-plugins-good gst-libav poppler-glib-libs webkitgtk4 iio-sensor-proxy-meta libgweather
# vte-gtk4 gtk4-layer-shell python-gobject


echo '#!/bin/sh
if [ "$1" = "pre-commit" ]; then
	true
elif [ "$1" = "post-commit" ]; then
	[ -f /boot/vmlinuz-stable ] && mv /boot/vmlinuz-stable /boot/vmlinuz
	efi_path="$(echo /usr/lib/systemd/boot/efi/system-boot*.efi)"
	[ -f "$efi_path" ] && mv "$efi_path" /boot/
fi
' > "$new_root"/etc/apk/commit_hooks.d/create-boot-files
chmod +x "$new_root"/etc/apk/commit_hooks.d/create-boot-files

chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey

chroot "$new_root" sh /usr/local/share/systemd-boot/bootup.sh

mkdir -p /mnt/boot/loader/entries
cat <<-EOF > /mnt/boot/loader/loader.conf
default  arch.conf
timeout  0
auto-entries no
editor   no
EOF
root_uuid="$(blkid /dev/"$target_partition2" | sed -nr 's/^.*[[:space:]]+UUID="([^"]*)".*$/\1/p')"
cat <<-EOF > /mnt/boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$ucode.img
initrd  /initramfs-linux.img
options root=UUID=$root_uuid rw
EOF
cat <<-EOF > /mnt/boot/loader/entries/arch-fallback.conf
title   Arch Linux (fallback initramfs)
linux   /vmlinuz-linux
initrd  /$ucode.img
initrd  /initramfs-linux-fallback.img
options root=UUID=$root_uuid rw
EOF
cat <<-EOF > /mnt/boot/loader/entries/memtest.conf
title Memtest86+
efi /memtest86+/memtest.efi
EOF

arch-chroot /mnt bootctl install
mkdir -p /mnt/etc/pacman.d/hooks
cat <<-EOF > /mnt/etc/pacman.d/hooks/95-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd
[Action]
Description = Gracefully upgrading systemd-boot...
When = PostTransaction
Exec = /usr/bin/systemctl restart systemd-boot-update.service
EOF

# to prevent BadUSB, write udev rules that once a bluetooth keyboard is connected,
# blocks usb (excluding btusb) input devices (keyboard, mouse, michrophone),
# https://manned.org/man/udev
# https://www.reactivated.net/writing_udev_rules.html

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$new_root"/var/lib/upm
	echo "build'from'src" > "$new_root"/var/lib/upm/config
fi

cp "$script_dir"/upm.py /mnt/usr/local/bin/upm
chmod +x /mnt/usr/local/bin/upm
echo 'permit nopass nu cmd /usr/local/bin/upm' > /mnt/etc/doas.d/upm.conf

state_dir="$XDG_STATE_HOME"
[ -z "$state_dir" ] && state_dir="$HOME"/.local/state

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$state_dir"/upm
	echo "build'from'src" > "$state_dir"/upm/config
fi

gnunet_namespace="$(cat "$scripr_dir"/../.data/gnunet/namespace)"
if [ -n "$gnunet_namespace" ]; then
	echo "$gnunet_namespace" > "$state_dir"/upm/config
	python3 "$script_dir"/upm.py install "$gnunet_namespace" upm
fi

echo '* * * * * ID=autoupdate FREQ=1d/5m autoupdate' > "$new_root"/etc/cron.d/autoupdate

ln -s /usr/bin/doas /mnt/usr/local/bin/sudo

# no multi'user: no need for pam_uaccess
# PAM is centralized, complicated and useless
# we really just need password based login
# fingerprint on its own is insecure, and as extra method, it's just a hassle
# face recognition is ridiculous as a security method
# CCID smartcards seems useless, because when physical access is possible, smartcards can't help much, so why bother
# in addition, for a single user system with no login, these can be implemented by the lock screen
# so there is really no need for PAM

echo; echo "set root password (can be the same as the one used to encrypt the root partition)"
echo "WARNING! do not use this password carelessly"
echo "in practice, it's only required for manually changing system files, ie almost never"
while ! chroot "$new_root" passwd; do
	echo "please retry"
done

# create a normal user
arch-chroot /mnt useradd --base-dir / --create-home --shell /usr/local/bin/swayshell nu

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done
echo 'permit nopass nu cmd /usr/bin/passwd nu' > /mnt/etc/doas.d/passwd.conf

cat <<-'EOF' > /mnt/usr/local/bin/autologin
# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304

modprobe zram
zramctl /dev/zram0 --algorithm zstd --size "$(($(grep -Po "MemTotal:\s*\K\d+" /proc/meminfo)/2))KiB"
mkswap -U clear /dev/zram0
swapon --discard --priority 100 /dev/zram0

# todo: implement a parent control service, which needs root password for activation and deactivation
# it runs as user "parent" (create if does not exist) and reports (through gnunet f2f) various data
# including the status of the device (so the parent will know if the os is replaced)

exec login -f nu
EOF
chmod +x /mnt/usr/local/bin/autologin

echo '[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --noreset --noclear -l /usr/local/bin/autologin - ${TERM}
' > /mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf
echo '[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --skip-login --nonewline --noissue --noreset --noclear -l /usr/local/bin/autologin - ${TERM}
' > /mnt/etc/systemd/system/getty@tty2.service.d/autologin.conf

# mono'space fonts:
# , wide characters are forced to squeeze
# , narrow characters are forced to stretch
# , bold characters don't have enough room
# proportional font for code:
# , generous spacing
# , large punctuation
# , and easily distinguishable characters
# , while allowing each character to take up the space that it needs
# Iosevka Aile (just change "I" character)
# "https://github.com/iaolo/iA-Fonts/tree/master/iA%20Writer%20Quattro" (just change "I" character)
#
# monospace font is still needed for terminal emulator
# https://github.com/adobe-fonts/source-code-pro

# "$script_dir"/sway.conf
cp "$script_dir"/swayshell.py /mnt/usr/local/bin/swayshell
chmod +x /mnt/usr/local/bin/swayshell

# libtorrent-rasterbar-python
# torrents do in'place first'write for preallocated space
# BTRFS can do in'place writes for a file by disabling COW
# but we don't want to disable COW for these files (unlike databases and virtual machine images)
# apparently BTRFS supports in'place first'write (falloc) without disabling COW, isn't it?
# https://www.reddit.com/r/btrfs/comments/timsw2/clarification_needed_is_preallocationcow_actually/
# https://www.reddit.com/r/btrfs/comments/s8vidr/how_does_preallocation_work_with_btrfs/

cp -r "$script_dir"/../ushell "$new_root"/usr/local/share/ushell
chmod +x "$new_root"/usr/local/share/ushell/1.sh
ln -s "$new_root"/usr/local/share/ushell/1.sh "$new_root"/usr/local/bin/ushell

cp "$script_dir"/../ushell/tz-guess.sh /mnt/etc/NetworkManager/dispatcher.d/09-tz-guess
chmod 755 /mnt/etc/NetworkManager/dispatcher.d/09-tz-guess

cp -r "$script_dir"/../uni "$new_root"/usr/local/share/
ln -s /usr/local/share/uni/1.py /mnt/usr/local/bin/uni
chmod +x /usr/local/share/uni/1.py

mkdir -p "$new_root"/usr/local/share/applications
echo '[Desktop Entry]
Name=Uni
Comment=Collaborative Development
Icon=uni
exec=qml6 /usr/local/share/uni/main.qml
StartupNotify=true
Type=Application
' > "$new_root"/usr/local/share/applications/uni.desktop
mkdir -p "$new_root"/usr/local/share/icons/hicolor/scalable/apps
ln -s /usr/local/share/uni/data/uni.svg "$new_root"/usr/local/share/icons/hicolor/scalable/apps/

chmod +x "$new_root"/usr/local/share/uni/usm.sh
ln -s /usr/local/share/uni/usm.sh "$new_root"/usr/local/bin/usm
echo 'permit nopass nu cmd /usr/local/bin/sd' > "$new_root"/etc/doas.d/sd.conf

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot
