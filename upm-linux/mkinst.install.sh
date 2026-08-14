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

mkdir -p "$new_root"/{root,tmp,run,proc,sys,dev}
chmod a+w "$target_dir"/tmp

# obtain gnunet namespaces from "$script_dir"/../.data/gnunet
# and put it into "$new_root"/var/lib/upm/config (as default namespace)

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	mkdir -p "$new_root"/var/lib/upm
	echo "build'from'src" > "$new_root"/var/lib/upm/config
fi

cp "$script_dir"/upm.sh "$new_root"/usr/bin/upm
chmod +x "$new_root"/usr/bin/upm
echo 'permit nopass nu cmd /usr/bin/upm' > "$new_root"/etc/doas.d/upm.conf

export PATH="$new_root/usr/bin:$PATH"

case "$(uname -m)" in
x86*)
	cpu_vendor_id="$(cat /proc/cpuinfo | grep vendor_id | head -n1 | sed -n "s/vendor_id[[:space:]]*:[[:space:]]*//p")"
	[ "$cpu_vendor_id" = AuthenticAMD ] && ucode=ucode-amd
	[ "$cpu_vendor_id" = GenuineIntel ] && ucode=ucode-intel
;;
esac

echo "$ucode
acpid
bluez
boot
chrony
cryptsetup
dbus
dinit
doas
dte
eudev
fsprogs
fwupd
gnunet
linux
netman
pipewire
sbase
sh
tpm2tools
uni
upm
ushare
ushell
utils" | {
	gnunet_namespace="$(cat "$scripr_dir"/../.meta/gns)"
	while read -r pkg_name; do
		UPM_ROOT="$target_dir" sh "$script_dir"/upm.sh install "$gnunet_namespace" "$pkg_name"
	done
}

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


chmod +x "$new_root"/usr/local/share/codev-util/tpm-getkey.sh
ln -s /usr/local/share/codev-util/tpm-getkey.sh "$new_root"/usr/local/bin/tpm-getkey

chroot "$new_root" sh /usr/local/share/systemd-boot/bootup.sh

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
# libseat only works for wlroots based wayland compositors
# pipewire does not use libseat; so the user must be in video and audio groups
# it's ok, since the system is single user, and only input devices must be protected (to protect root passsword)
# https://wiki.alpinelinux.org/wiki/Setting_up_a_new_user#Groups_for_desktop_usage
chroot "$new_root" useradd --base-dir / --create-home --shell /usr/bin/ushell nu
echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done
echo 'permit nopass nu cmd /usr/bin/passwd nu' > /mnt/etc/doas.d/passwd.conf

ln -s /usr/local/share/util-linux/autologin.sh "$new_root"/usr/local/bin/autologin
chmod +x "$new_root"/usr/local/share/util-linux/autologin.sh
# create autologin dinit services for tty1 and tty2
# /usr/bin/agetty --skip-login --nonewline --noissue --noreset --noclear -l /usr/local/bin/autologin - ${TERM}

# no multi'user: no need for pam_uaccess
# PAM is centralized, complicated and useless
# we really just need password based login
# fingerprint on its own is insecure, and as extra method, it's just a hassle
# face recognition is ridiculous as a security method
# CCID smartcards seems useless, because when physical access is possible, smartcards can't help much, so why bother
# in addition, for a single user system with no login, these can be implemented by the lock screen
# so there is really no need for PAM

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot
