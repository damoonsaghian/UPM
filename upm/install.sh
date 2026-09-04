set -e

script_dir="$(dirname "$(readlink -f "$0")")"

# https://wiki.archlinux.org/title/Bubblewrap
# https://bxt.rs/blog/easy-sandboxing-on-linux-with-bubblewrap/
# https://sloonz.github.io/posts/sandboxing-2/

state_dir="$XDG_STATE_HOME"
[ -z "$state_dir" ] && state_dir="$HOME"/.local/state
mkdir -p "$state_dir"/upm

# obtain gnunet namespaces from "$script_dir"/../.data/gnunet
# and put it into "$state_dir"/upm/config (as default namespace)
gnunet_namespace="$(cat "$scripr_dir"/../.data/gnunet/namespace)"
if [ -n "$gnunet_namespace" ]; then
	echo "$gnunet_namespace" > "$state_dir"/upm/config
	python3 "$script_dir"/upm.py install "$gnunet_namespace" upm
fi

echo "UPM will try to download binary packages (instead of building from source), if they are available for your system"
printf "do you want to always built packages from source? (y/N) "
read -r ans
if [ "$ans" = y ]; then
	echo "build'from'src" > "$state_dir"/upm/config
fi

cp "$script_dir"/upm.sh "$HOME"/.local/bin/upm
chmod +x "$HOME"/.local/bin/upm

# dinit user services
# "$HOME"/.config/autostart/dinit.desktop

# crond user service
# echo '* * * * * ID=autoupdate FREQ=1d/5m autoupdate' > "$HOME"/.config/cron.d/autoupdate

echo; echo "installation completed successfully"
