# installs a minimal Linux'based system, with a user interface based on UShell and Uni

script_dir="$(dirname "$(readlink -f "$0")")"

while ! ping -c 2 -w 5 ping.archlinux.org; do
	nmcli d wifi list
	printf "enter the desired SSID: "
	read -r ssid
	nmcli d wifi connect "$ssid"
done

# format a storage device for installing the new system
new_root="$(mktemp -d /Data/Variable/run/user/"$(id u)"/uni.XXX)"
. "$script_dir"/install-mkfs.sh

cp -r "$script_dir"/../uni "$new_root"/usr/local/share/
mkdir -p "$new_root"/usr/local/share/icons/hicolor/scalable/apps
ln -s /usr/local/share/uni/data/uni.svg "$new_root"/usr/local/share/icons/hicolor/scalable/apps/

mkdir -p "$new_root"/usr/local/share/applications
echo '[Desktop Entry]
Name=Uni
Comment=Collaborative Development
Icon=uni
exec=qml6 /usr/local/share/uni/main.qml
StartupNotify=true
Type=Application
' > "$new_root"/usr/local/share/applications/uni.desktop

chmod +x "$new_root"/usr/local/share/uni/sd.sh
ln -s /usr/local/share/uni/sd.sh "$new_root"/usr/local/bin/sd
echo 'permit nopass nu cmd /usr/local/bin/sd' > "$new_root"/etc/doas.d/sd.conf

exit

# obtain gnunet namespaces from "$script_dir"/../.meta/gnunet, and put it into "$state_dir"/upm/config

# format a storage device for installing the new system
new_root="$(mktemp -d /Data/Variable/run/user/"$(id u)"/uni.XXX)"
. "$script_dir"/install-mkfs.sh

mkdir -p "$new_root"/{root,tmp,run,proc,sys,dev}
chmod a+w "$target_dir"/tmp

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$new_root"/var/lib/upm
	echo "build'from'src" > "$new_root"/var/lib/upm/config
fi

export PATH="$new_root/usr/bin:$PATH"

# upm offline mode, use cache

# eudev eudev-netifnames earlyoom acpid zzz bluez \
# 	networkmanager-cli wireless-regdb mobile-broadband-provider-info ppp-pppoe dnsmasq chrony dcron fwupd
# tasks: udev udev-trigger udev-settle udev-postmount earlyoom acpid bluetooth
# 	networkmanager networkmanager-dispatcher chronyd dcron fwupd

echo 'acpid
bluez
chrony
cryptsetup
dbus
dinit
doas
dte
eudev
gnunet
linux
netman
pipewire
sbase
sh
tpm2-tools
uni
upm
ushare
ushell
util-linux' | {
	gnunet_namespace="$(cat "$scripr_dir"/../.meta/gns)"
	while read -r pkg_name; do
		UPM_ROOT="$target_dir" sh "$script_dir"/upm.sh install "$gnunet_namespace" "$pkg_name"
	done
}

echo '* * * * * ID=autoupdate FREQ=1d/5m autoupdate' > "$new_root"/etc/cron.d/autoupdate

##########
#  boot  #
##########

echo "disable_trigger=yes" > "$new_root"/etc/mkinitfs/mkinitfs.conf

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

# linux systemd-boot mkinitfs btrfs-progs cryptsetup tpm2-tools
case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	# [ "$cpu_vendor_id" = AuthenticAMD ] && install amd-ucode
	# [ "$cpu_vendor_id" = GenuineIntel ] && install intel-ucode
;;
esac

chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey

chroot "$new_root" sh /usr/local/share/systemd-boot/bootup.sh

# systemd-boot

# bootup.sh
# run when kernel or systemd-boot are updated

# micrcodes

# tpm2-tools
# tmp-getkey.sh

# cryptsetup
# with nettle backend

# wireless-regdb
# fwupd

# doas rules for poweroff and reboot of init system

# acpid (listen for, and process, ACPI events related to lid-switch activation and the power and suspend keys)

# https://wiki.archlinux.org/title/Laptop_Mode_Tools
# https://github.com/rickysarraf/laptop-mode-tools
# https://github.com/rickysarraf/laptop-mode-tools/blob/lmt-upstream/Documentation/laptop-mode.txt
# https://github.com/rickysarraf/laptop-mode-tools/wiki
# use xrandr to lower screen refresh rate, when on battery

# suspend system with support for hooks (needed for some drivers)
# https://github.com/jirutka/zzz
# doas rules

# mkinst.sh

# btrfs-progs
# dosfstools
# exfatprogs

# https://github.com/libarchive/libarchive
# --with-nettle --without-openssl
# https://github.com/cybernoid/archivemount

# avahi
# skip avahi-glib

# bluez
# create doas rules to use as normal user

# chrony
# how to sync time over gnunet? vpn over gnunet maybe?

# networkmanager
# crypto=gnutls polkit=false
# wpa_supplicant or iwd (without dhcp)
# modemmanager

# gnutls
# disable p11-kit, cause it's useless
# because when a system is compromized, though it can protect the private key itself,
# it can't prevent using the private key (eg for signing)
# ca-certificates

# tmp2-tss and qtnetwork need openssl

# https://git.lysator.liu.se/lsh/lsh
# https://www.lysator.liu.se/~nisse/lsh/lsh.html
# create ssh and and ssh-keygen executables, and provide at least those options needed by git and upm
# or configure git to use ssh program in a way that is compatible with lsh:
# 	https://github.com/git/git/blob/master/Documentation/config/ssh.adoc

# curl
# http/https only curl (with gnutls backend)
# for http/3:
# https://github.com/ngtcp2/ngtcp2
# https://github.com/lxin/quic (only works on linux)

# https://gitlab.freedesktop.org/pipewire/pipewire
# https://wiki.alpinelinux.org/wiki/PipeWire
# https://docs.voidlinux.org/config/media/pipewire.html
# https://wiki.archlinux.org/title/PipeWire
# https://gitlab.freedesktop.org/pipewire/media-session
# enable pulse, disable gstreamer glib jack
# libpw-v4l2.so
# pipewire-spa-bluez

# autologin.sh
# agetty service for tty1: /usr/bin/getty -n -l /usr/bin/autologin 38400 tty1
# agetty service for tty2: /usr/bin/getty --skip-login -l /usr/bin/autologin tty2 linux

# user services: pipewire, wireplumber, and dbus
# https://manpages.debian.org/trixie/dbus-daemon/dbus-daemon.1.en.html

##########
#  user  #
##########

echo; echo "set root password (can be the same as he one used to encrypt the root partition)"
echo "WARNING! do not use this password carelessly"
echo "in practice, it's only required for manually changing system files, ie almost never"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

# create a normal user
chroot "$new_root" adduser --empty-password --home /nu --shell /usr/bin/ushell nu # add to audio and video group
chroot "$new_root" chown nu: /nu

echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done

sed 's@tty1:respawn:\(.*\)getty@tty1:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab > "$new_root"/etc/inittab.tmp
sed 's@tty2:respawn:\(.*\)getty@tty2:respawn:\1getty -n -l /usr/local/bin/autologin@' \
	"$new_root"/etc/inittab.tmp > "$new_root"/etc/inittab

ln -s /usr/local/share/util-linux/autologin.sh "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/share/util-linux/autologin.sh

# no multi'user: no need for logind or even pam_uaccess
# PAM is centralized, complicated and useless
# we really just need password based login
# fingerprint on its own is insecure, and as extra method, it's just a hassle
# face recognition is ridiculous as a security method
# CCID smartcards seems useless, because when physical access is possible, smartcards can't help much
# 	so why bother
# in addition, for a single user system with no login, these can be implemented by the lock screen
# 	so there is no need for PAM

############
#  Ushell  #
############

if apk info quickshell >/dev/null 2>&1; then
	apk_new quickshell --virtual .quickshell
else
	apk_new git clang cmake ninja-is-really-ninja pkgconf spirv-tools wayland-protocols qt6-qtshadertools-dev \
		jemalloc-dev pipewire-dev libdrm-dev mesa-dev wayland-dev \
		qt6-qtbase-dev qt6-qtdeclarative-dev qt6-qtsvg-dev qt6-qtwayland-dev --virtual .quickshell
		chroot "$new_root" sh "$script_dir"/upm.sh quickshell
fi
apk_new setpriv doas-sudo-shim musl-locales exfatprogs tzdata geoclue bash bash-completion dbus \
	pipewire pipewire-pulse pipewire-alsa pipewire-echo-cancel pipewire-spa-bluez wireplumber sof-firmware \
	mesa-dri-gallium mesa-va-gallium breeze breeze-icons \
	font-adobe-source-code-pro font-noto font-noto-emoji \
	font-noto-armenian font-noto-georgian font-noto-hebrew font-noto-arabic font-noto-ethiopic font-noto-nko \
	font-noto-devanagari font-noto-gujarati font-noto-telugu font-noto-kannada font-noto-malayalam \
	font-noto-oriya font-noto-bengali font-noto-tamil font-noto-myanmar \
	font-noto-thai font-noto-lao font-noto-khmer font-noto-cjk \
	qt6-qtvirtualkeyboard qt6-qtsensors mauikit-terminal .quickshell --virtual .codev-shell
rc_new dbus
rc_new --nu dbus
rc_new --nu pipewire
rc_new --nu wireplumber

cp -r "$script_dir"/../codev-shell "$new_root"/usr/local/share/codev-shell
chmod +x "$new_root"/usr/local/share/codev-shell/codev-shell.sh
ln -s "$new_root"/usr/local/share/codev-shell/codev-shell.sh "$new_root"/usr/local/bin/codev-shell

cat <<-EOF > "$new_root"/etc/doas.d/codev-shell.conf
permit nopass nu cmd setpriv --reuid=nu --regid=nu --groups=input,video,audio /usr/local/bin/codev-shell priv
permit nopass nu cmd /usr/bin/passwd nu
EOF

echo '#!/bin/sh
case "$2" in
up) sudo -u nu sh /usr/local/share/codev-shell/system.sh tz guess ;;
esac
' > /etc/NetworkManager/dispatcher.d/09-dispatch-script
chmod 755 /etc/NetworkManager/dispatcher.d/09-dispatch-script

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot
