# set resource limits for realtime applications like the rt module in pipewire
ulimit -r 95 -e -19 -l 4194304

modprobe zram
zramctl /dev/zram0 --algorithm zstd --size "$(($(grep -Po 'MemTotal:\s*\K\d+' /proc/meminfo)/2))KiB"
mkswap -U clear /dev/zram0
swapon --discard --priority 100 /dev/zram0

# todo: implement a parent control service, which needs root password for activation and deactivation
# it runs as user "parent" (create if does not exist) and reports (through gnunet f2f) various data
# including the status of the device (so the parent will know if the os is replaced)

exec login -f nu
