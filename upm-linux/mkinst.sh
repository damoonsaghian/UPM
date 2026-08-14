echo "this will create a bootable installer, on a removable storage device"
# usage: sh mkinst.sh <target-dir> [<arch>]

# ask the user to choose a removable storage device
device_name=

command -c usm || {
	usm() {
		# implement "usm mkefi" and "usm mount" using udisks
		# https://storaged.org/udisks/docs/ref-dbus.html
	}
}

# format a removable storage device and mount it
usm mkefi "$device_name"
# mount the partition:
target_dir=/run/user/$(id -u)/mounts/"$device_name"
mkdir -p $target_dir
usm mount /dev/"$device_name" $target_dir

target_dir="$1"
[ -z "$target_dir" ] && {
	echo "usage: sh mkinst.sh <target-dir> [<arch>]"
}

arch="$2"
while [ -z "$arch" ]; do
	echo "the following architectures are supported:"
	echo "	1) x86_64"
	echo "	2) aarch64"
	echo "	3) riscv64"
	echo "enter the number of the desired architechture: "
	read -r ans
	case "$ans" in
	1) arch=x86_64 ;;
	2) arch=aarch64 ;;
	3) arch=riscv64 ;;
	esac
done

cd "$target_dir"

# create  an initramfs (for $arch) that includes programs needed to install Uni
# https://pkgs.chimera-linux.org/package/current/main/x86_64/initramfs-tools
# https://wiki.alpinelinux.org/wiki/How_to_make_a_custom_ISO_image_with_mkimage
mkdir initfs
# init, login, install.py, web browser

echo 'bash
bluez
chrony
cryptsetup
dbus
dinit
dte
eudev
gnunet
linux
netman
opendoas
pipewire
powerman
tpm2tools
utils
upm
ushell
uni' | while read -r pkg_name; do
	ROOT_DIR="$wdir"/initfs sh "$script_dir"/upm.sh install "$pkg_name"
done

usm umount $target

echo "bootable installer successfully created"
echo "now boot into the installation media, and follow the instructions"
