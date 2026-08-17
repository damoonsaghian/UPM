#!/usr/bin/env sh

script_dir="$(dirname "$(readlink -f "$0")")"

# notifications: error, update process, update finished

case "$1" in
install) apk add "$2" ;;
remove) apk del "$2" ;;
update)
	apk update
	# if interactive, and fwupd has updates available, ask user whether to update firmware
	# boot'firmware updates need special care
	# unless there is a read'only backup, firmware update is not a good idea
	# so warn and ask the user if she wants the update
	# doas fwupdmgr get-devices
	# doas fwupdmgr refresh
	# doas fwupdmgr get-updates
	# doas fwupdmgr update
	;;
find) apk search $2 ;;
esac

exit

# https://www.programming-books.io/essential/bash/
# https://cppcheatsheet.com/notes/tools/bash.html
# https://steinbaugh.com/posts/posix.html
# https://www.shellcheck.net/

# https://github.com/chimera-linux/cports/blob/master/Usage.md
# https://github.com/chimera-linux/cports/blob/master/Packaging.md

# clang cross'compilation
# bootstraping and cross compilation
# https://www.linuxfromscratch.org/lfs/view/stable/
# https://t2sde.org/handbook/html/index.html
# https://buildroot.org/downloads/manual/manual.html
# https://github.com/glasnostlinux/glasnost
# https://github.com/iglunix
# https://github.com/oasislinux/oasis
# https://mcilloni.ovh/2021/02/09/cxx-cross-clang/
# https://libcxx.llvm.org/

# package name includes its gnunet namespace

# reproducible builds
# during building, a .bdep file will be created that contains all the build dependencies and their versions,
# 	in the order mentioned in the .upm file
# this file can be used to reproduce the build
# the built files then will be compared (using the CHK of files in gnunet),
# 	and if there is any incompatabilities, the user will be notified
# use gnunet-directory to get CHK of the files in official gnunet namespace
# use gnunet-publish --simulate-only to obtain the CHK of built files
# https://stagex.tools/

# high'performance linker
# https://pkgs.chimera-linux.org/package/current/main/x86_64/mold

[ -z "$ARCH" ] && ARCH="$(uname --machine)"

if [ "$(id -u)" = 0 ]; then
	dinit_dir="$UPM_ROOT"/usr/share/dinit # system services
	dbus_dir="$UPM_ROOT"/usr/share/dbus-1 # dbus interfaces and services
	apps_dir="$UPM_ROOT"/usr/share/applications
	cmd_dir="$UPM_ROOT"/usr/bin
	state_dir="$UPM_ROOT"/var/lib
	cache_dir="$UPM_ROOT"/var/cache
else
	data_dir="$XDG_DATA_HOME"
	[ -z "$data_dir" ] && data_dir="$HOME"/.local/share
	dbus_dir="$data_dir"/dbus-1
	apps_dir="$data_dir"/applications

	cmd_dir="$HOME"/.local/bin
	
	state_dir="$XDG_STATE_HOME"
	[ -z "$state_dir" ] && state_dir="$HOME"/.local/state
	cache_dir="$XDG_CACHE_HOME"
	[ -z "$cache_dir" ] && cache_dir="$HOME"/.cache
fi

pkgs_dir="$state_dir"/upm/pkgs

mkdir -p "$cmd_dir" "$dinit_dir" "$dbus_dir" "$apps_dir" "$state_dir" "$cache_dir" "$pkgs_dir"

upm_download() {
	# download source packages into "$cache_dir"/upm/pkgs-src/<pkg-name>/
	# download built packages into  "$cache_dir"/upm/pkgs-built/<pkg-name>/
	# if the gnunet namespace is not one of the default ones, it would be <pkg-name>-<gnunet-namespace> instead
}

upm_install() {
	local gn_namespace="$1"
	local pkg_name="$2"
	local build_dir="$pkgs_dir/$gn_namespace/$pkg_name/.cache"
	
	# read upmi entries in .upm file, the:
	# , create imports file
	# , download imported packages (dependencies)
	
	if [ "$(id -u)" = 0 ] || bwrap --version >/dev/null 2>&1; then
		# run upm-build.sh inside bubblewrap sandbox, which have write access only to it's own build dir
		# https://wiki.archlinux.org/title/Bubblewrap/Examples
		sh "$script_dir"/upm-build.sh "$gn_namespace" "$pkg_name"
	else
		sh "$script_dir"/upm-build.sh "$gn_namespace" "$pkg_name"
	fi
	
	# store "$gn_namespace $pkg_name" in $state_dir/upm/installed (if not already)
	# if $pkg_name exists already, and namespaces does not match, but owners match, replace,
	# 	otherwise exit with error
	
	# if a symlink with the same name already exists:
	# if it's linked into the same package, skip
	# otherwise if the owners match, replace then, otherwise exit with error
	
	# create symlinks from "$build_dir/inst/cmd/*" files into "$cmd_dir"
	
	# create .desktop files from "$build_dir/inst/app/*" files into "$apps_dir"
	# .desktop file name: $pkg_name.$app_name.desktop
	# icon_path=""
	# [Desktop Entry]
	# Type=Application
	# StartupNotify=true
	# Name=$app_name
	# Icon=$(echo $build_dir/inst/app/$app_name.*)
	# Exec=$build_dir/inst/app/$app_name
	
	# create symlinks from "$build_dir/inst/dbus/*" directories to "$dbus_dir"
	
	[ "$(id -u)" = 0 ] || return 0
	
	# create symlinks from "$build_dir/inst/sv/*" directories, to "$dinit_dir"
	
	# when package is $gnunet_namespace/systemd-boot or linux
	# run bootup.sh
	
	# when package is $gnunet_namespace/linux
	# link modules to /lib/modules
}

upm_search() {
	# search in gnunet for extra packages
}

upm_list() {
	# list installed packages filterd by $1
}

if [ "$1" = build ]; then
	if [ -z "$3" ]; then
		project_dir="$2"
		[ -z "$project_dir" ] && project_dir=.
			
		if [ -f "$2/0.upm" ]; then
			upmb "$project_dir"
		else
			# search for ".upm" (case insensitive) in "$project_dir"
			# the first one found, plus those sibling directories containing a .upm, are the packages to be built
			# run upmb for each
		fi
	else
		upmb "$2" "$3"
	fi
elif [ "$1" = import ]; then
	upm_import "$2" "$3"
elif [ "$1" = install ]; then
		upm_install "$2" "$3"
elif [ "$1" = remove ]; then
	gn_namespace="$2"
	pkg_name="$3"
	pkg_dir="/upm/$gn_namespace/$pkg_name"
	
	if [ "$(id -u)" = 0 ]; then
		# exit if package_name is: acpid bash bluez chrony dash dbus dte eudev fwupd gnunet systemd-boot linux netman dinit
		# 	sbase upm doas tz util-linux
		# warn if package_name is sway, swapps, termulator, or uni
	fi
	
	# for packages mentioned in "imp" file:
	# , decrement the number stored in their upmcount file
	# , if the number gets zero, and it's not in $state_dir/upm/installed file, remove that package too
	
	# remove it from $state_dir/upm/installed file, but remove the package dir, only if upmcount is zero
	
	# removes the files mentioned in "$pkg_dir/exp/cmd" from "$cmd_dir"
	
	# remove corresponding symlinks in "$apps_dir" and "$dinit_dir"
	
	# remove package directory
elif [ "$1" = update ]; then
	# during update reuse unchanged files from last version
	
	# for each line in $state_dir/upm/installed
	# upm_install "$gn_namespace" "$package_name"
	
	# check in each update, if the ref count of files in .cache/upm/builds is 1, clean that package
	# file_ref_count=$(stat -c %h filename)
	
	# when the namespace directory is empty, delete it
	
	# fwupd
	# boot'firmware updates need special care
	# unless there is a read'only backup, firmware update is not a good idea
	# so warn and ask the user if she wants the update
	# doas fwupdmgr get-devices
	# doas fwupdmgr refresh
	# doas fwupdmgr get-updates
	# doas fwupdmgr update
elif [ "$1" = mkinst ]; then
	. "$script_dir"/mkinst.sh
elif [ "$1" = publish ]; then
	# keep two versions in repo
	
	# a package is made of the content of a directory containg a 0.upm file
	# or a <pkg-name>.upm file and all its sibling files and directories named <pkg-name> or <pkg-name>.*
	
	# upm will search for upm files in the project directory and the first level of sub'directories
	
	# <pkg-name>-<version>
	
	# cross'built the package for all architectures mentioned in "$state_dir/upm.conf" (value of "arch" entry),
	# and put the results in in "~/./upm/builds/<arch>/"
	# in ".upm" scripts we can use "$carch" variable when cross'building
	# "$carch" is an empty string when not cross'building
	upm_publish
else
	echo "usage guide:"
	echo "	upm build [<project-path>]"
	echo "	upm build <gnunet-namespace> <package-name>"
	echo "	upm import <gnunet-namespace> <package-name>"
	echo "	upm download <gnunet-namespace> <package-name>"
	echo "	upm install <gnunet-namespace> <package-name>"
	echo "	upm remove <gnunet-namespace> <package-name>"
	echo "	upm update"
	echo "	upm find"
	echo "	upm findapp"
	echo "	upm mkinst [<device-name>] [x86_64|aarch64|riscv64]"
	echo "	upm publish"
fi
