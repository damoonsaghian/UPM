# this function can be used in .upm scripts to clone a tag branch from a git repository
gitag_clone() {
	# https://www.programming-books.io/essential/git/
	# https://man.archlinux.org/listing/git
	# https://git-scm.com/docs/partial-clone
	# --depth 1
	
	# to verify git tag signatures use ssh-keygen
	# git config --global gpg.format ssh
	# echo "$(git config --get user.email) namespaces=\"git\" $(cat "$path_to_ssh_public_key")
	# " >> "$path_to_allowed_signers_file"
	# git config --global gpg.ssh.allowedSignersFile "$path_to_allowed_signers_file"
	# 	https://blog.dbrgn.ch/2021/11/16/git-ssh-signatures/
	# 	https://www.git-tower.com/blog/setting-up-ssh-for-commit-signing/
	# 	https://calebhearth.com/sign-git-with-ssh
	# 	https://github.com/git/git/blob/master/Documentation/config/gpg.adoc
	# 	https://git-scm.com/docs/git-verify-tag
	# if a gpg key is given, download and build gpg package
}

# this function can be used in .upm scripts to create executables in $pkg_dir/exec
# and optionaly export them to $pkg_dir/cmd or $pkg_dir/app
# usage guide:
# upmx [-cmd|-app] <file-path> ...
upmx() {
	local executable_name="$1"
	local destination_dir_relpath="$2"
	local destination_path="$script_dir/.cache/upm/build/$ARCH/$destination_dir_relpath/$executable_name"
	
	mkdir -p "$script_dir/.cache/upm/build/$ARCH/$destination_dir_relpath"
	
	# put the file in $build_dir/exec
	# make it executable
	
	cat <<-'EOF' > "$destination_path"
	#!/usr/bin/env sh
	script_dir="$(dirname "$(readlink -f "$0")")"
	export PATH="$script_dir/../../exec:$PATH"
	export LD_LIBRARY_PATH="$script_dir/../../lib"
	export XDG_DATA_DIRS="$script_dir/../../data:$XDG_DATA_DIRS"
	EOF
	
	echo "exec \$script_dir/../../exec/$executable_name" >> "$destination_path"
	chmod +x "$destination_path"
}

# this function can be used in .upm scripts to import run'time dependency packages
# hardlink files in "cmd" and "lib" and "data" directories
upmi() {
	local gn_namespace="$1"
	local pkg_name="$2"
	[ -z "$2" ] && {
		# read gn_namespace from the first line of ".data/gnunet/project"
		gn_namespace=
		pkg_name="$1"
	}
	
	upmb "$gn_namespace" "$pkg_name"
	# hardlink the files in "$PKG$pkg_name/cmd" "$PKG$pkg_name/lib" and "$PKG$pkg_name/data" into:
	# 	"$build_dir/exec" "$build_dir/lib" and "$build_dir/data"
	# do not symlink symlinks; make a symlink to the origin
	
	# append the URL of the package to ".cache/upm/builds/imp" (if not already)
	
	# increment the number stored in upmcount file
	
	# imports:
	# , libs: symlink the files listed in $dep_pkg_dir/exp/lib into $pkg_dir/lib
	# , commands: symlink the files listed in $dep_pkg_dir/exp/cmd into $pkg_dir/cmd
	# , lib data (like fonts and icons):
	# 	symlink the data directories listed in $dep_pkg_dir/exp/data into $pkg_dir/data
}

mklink() {
	# if $1 differs from the same file in build dir, make a hard'link
}

pkg_dir=""
build_dir=""
gn_namespace=""
pkg_name=""
upmbuildsh_dir="$pkg_dir"

# each package of a project is built in .cache/upm/<pkg-name>

# cd into the package dir

if [ -z "$2" ]; then
	pkg_dir="$1"
	build_dir="$pkg_dir/.cache/upm/build/$TARGET/$pkg_name"
	
	UPM_TEST=1
	# at the end of UPMbuild.sh scripts, we can include test instructions, after this line:
	# [ -z UPM_TEST ] && return
	
	# read the gnunet namespace in $pkg_dir/.data/gnunet
	GNNS=
else
	gn_namespace="$1"
	pkg_name="$2"
	build_dir="$state_dir/upm/build/$gn_namespace/$pkg_name"
	
	# if gn_namespace is revoked try the alternative ones from .data/gnunet/$gn_namespace
	# also print a warning
	
	if [ "$(id -u)" = 0 ]; then
		upm_download $gn_namespace $pkg_name
	else
		doas upm download $gn_namespace $pkg_name
	fi
	
	eval PKG$pkg_name="\"$build_dir\""
	# packages needed as build'time dependency, are mentioned in the "UPMbuild.sh" script, like this:
	# 	upmb <gnunet-namespace> <package-name>
	# now we can use "$PKG<package-name>" where ever you want to access a file in a package
	
	# if prebuild package is downloaded:
	# import all the packages mentioned in the "imp" file
	# and thats it, return
	
	# if "UPMbuild.sh" file is already open, it means that there is a cyclic dependency
	# so just download a prebuilt package (even when "build'from'src" is in config)
	# then warn and return, to avoid an infinite loop
fi

# if "$build_dir" already exists:
# , create "${build_dir}-new"
# , at the end: exch "${build_dir}-new" "$build_dir"

# bubblewrap
. "$pkg_dir"/UPMbuild.sh
