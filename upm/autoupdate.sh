# ensuring exclusivity
[ -e /tmp/lock.upm ] && exit
trap "trap - EXIT; rm /tmp/lock.upm" EXIT INT TERM QUIT HUP PIPE
touch /tmp/lock.upm

# a 5min delay, for when it's started on boot
sleep 300

# if net is down, wait for it to get up

# do not run autoupdate on metered connection
metered_connection=true
while [ $metered_connection = true ]; do
	case nmcli --terse --field METERED general in
	yes*)
		# wait for network change
		;;
	*) metered_connection = false ;;
	esac
done

[ -e /sys/class/power_supply/BAT0 ] &&
	[ "$(cat /sys/class/power_supply/BAT0/status)" = Discharging ] &&
	[ "$(cat /sys/class/power_supply/BAT0/capacity)" -lt 30 ] &&
	# watch cat /sys/class/power_supply/BAT0/status and when it's Charging, continue

upm update
