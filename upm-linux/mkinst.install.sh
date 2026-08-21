# installs a minimal Linux'based system, with a user interface based on UShell and Uni

script_dir="$(dirname "$(readlink -f "$0")")"

while ! ping -c 2 -w 5 ping.archlinux.org; do
	nmcli d wifi list
	printf "enter the desired SSID: "
	read -r ssid
	nmcli d wifi connect "$ssid"
done

# format a storage device for installing the new system
new_root="$(mktemp -d /run/user/"$(id -u)"/new_root.XXX)"
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
bash
bluez
boot
chrony
cryptsetup
dbus
dinit
dte
eudev
fsprogs
fwupd
gnunet
linux
netman
opendoas
pipewire
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

echo; echo "set root password (can be the same as he one used to encrypt the root partition)"
echo "WARNING! do not use this password carelessly"
echo "in practice, it's only required for manually changing system files, ie almost never"
while ! chroot "$new_root" passwd root; do
	echo "please retry"
done

# create a normal user
chroot "$new_root" useradd --base-dir / --create-home --shell /usr/bin/ushell nu
echo; echo "set lock'screen password"
while ! chroot "$new_root" passwd nu; do
	echo "please retry"
done

echo; echo "installation completed successfully"
printf "reboot the system? (Y/n) "
read -r ans
[ "$ans" != n ] && [ "$ans" != no ] && reboot
