#!/system/bin/sh

PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

BBX=/system/xbin/busybox

# Inicio
mount -o remount,rw -t auto /
mount -o remount,rw -t auto /system
mount -t rootfs -o remount,rw rootfs

if [ -f $BBX ]; then
	chown 0:2000 $BBX
	chmod 0755 $BBX
	$BBX --install -s /system/xbin
	ln -s $BBX /sbin/busybox
	ln -s $BBX /system/bin/busybox
	sync
fi

# Set environment and create symlinks: /bin, /etc, /lib, and /etc/mtab
set_environment ()
{
	# create /bin symlinks
	if [ ! -e /bin ]; then
		$BBX ln -s /system/bin /bin
	fi

	# create /etc symlinks
	if [ ! -e /etc ]; then
		$BBX ln -s /system/etc /etc
	fi

	# create /lib symlinks
	if [ ! -e /lib ]; then
		$BBX ln -s /system/lib /lib
	fi

	# symlink /etc/mtab to /proc/self/mounts
	if [ ! -e /system/etc/mtab ]; then
		$BBX ln -s /proc/self/mounts /system/etc/mtab
	fi
}

if [ -x $BBX ]; then
	set_environment
fi

########################################################

# Permissions for LMK
chmod 0664 /sys/module/lowmemorykiller/parameters/adj
chmod 0664 /sys/module/lowmemorykiller/parameters/cost
chmod 0664 /sys/module/lowmemorykiller/parameters/minfree
chmod 0664 /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
chmod 0664 /sys/module/lowmemorykiller/parameters/vmpressure_file_min

# Tune LMK to Medium
echo "1536,2048,4096,16384,28672,32768" > /sys/module/lowmemorykiller/parameters/minfree
#echo "32" > /sys/module/lowmemorykiller/parameters/cost
#echo "0,1,6,12,13,15" > /sys/module/lowmemorykiller/parameters/adj

# Set Max GPU
echo 533000000 > /sys/class/kgsl/kgsl-3d0/max_gpuclk

# Kcal Settings
echo 256 256 256 > /sys/devices/platform/kcal_ctrl.0/kcal
echo 35 > /sys/devices/platform/kcal_ctrl.0/kcal_min
echo 1 > /sys/devices/platform/kcal_ctrl.0/kcal_enable
echo 0 > /sys/devices/platform/kcal_ctrl.0/kcal_invert
echo 275 > /sys/devices/platform/kcal_ctrl.0/kcal_sat
echo 0 > /sys/devices/platform/kcal_ctrl.0/kcal_hue
echo 251 > /sys/devices/platform/kcal_ctrl.0/kcal_val
echo 258 > /sys/devices/platform/kcal_ctrl.0/kcal_cont

# Set IOSched
echo "zen" > /sys/block/mmcblk0/queue/scheduler

# general queue tweaks
for i in /sys/block/*/queue; do
  echo 512 > $i/nr_requests;
  echo 512 > $i/read_ahead_kb;
  echo 2 > $i/rq_affinity;
  echo 0 > $i/nomerges;
  echo 0 > $i/add_random;
  echo 0 > $i/rotational;
done;
for j in /sys/block/*/bdi; do
  echo 5 > $j/min_ratio;
done;

# Disable Dynamic FSync
echo 0 > /sys/kernel/dyn_fsync/Dyn_fsync_active

# Adaptive LMK
echo 1 > /sys/module/lowmemorykiller/parameters/enable_adaptive_lmk
echo 53059 > /sys/module/lowmemorykiller/parameters/vmpressure_file_min

# Process Reclaim
echo 1 > /sys/module/process_reclaim/parameters/enable_process_reclaim
echo 50 > /sys/module/process_reclaim/parameters/pressure_min
echo 70 > /sys/module/process_reclaim/parameters/pressure_max
echo 512 > /sys/module/process_reclaim/parameters/per_swap_size
echo 30 > /sys/module/process_reclaim/parameters/swap_opt_eff

# More Tweaks
echo 0 > /proc/sys/kernel/randomize_va_space
echo 0 > /proc/sys/vm/page-cluster
echo 60 > /proc/sys/vm/vfs_cache_pressure
echo 20 > /proc/sys/vm/dirty_ratio
echo 5 > /proc/sys/vm/dirty_background_ratio
echo 3000 > /proc/sys/vm/dirty_writeback_centisecs
echo 500 > /proc/sys/vm/dirty_expire_centisecs
echo 80 > /proc/sys/vm/swappiness
echo 4096 > /proc/sys/vm/min_free_kbytes

# ZRAM
echo 4 > /sys/block/zram0/max_comp_stream

# Enable ARCH Power
echo 1 > /sys/kernel/sched/arch_power
echo 0 > /sys/kernel/sched/gentle_fair_sleepers

# Power Mode
echo 1 > /sys/module/msm_pm/modes/cpu0/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu1/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu2/retention/idle_enabled
echo 1 > /sys/module/msm_pm/modes/cpu3/retention/idle_enabled

# Tune entropy parameters.
echo 1366 > /proc/sys/kernel/random/read_wakeup_threshold
echo 2048 > /proc/sys/kernel/random/write_wakeup_threshold

# Vibrator amplitude
echo 50 > /sys/class/timed_output/vibrator/amp

# disable debugging on some modules
echo 0 > /sys/module/kernel/parameters/initcall_debug
echo 0 > /sys/module/alarm/parameters/debug_mask
echo 0 > /sys/module/alarm_dev/parameters/debug_mask
echo 0 > /sys/module/binder/parameters/debug_mask
echo 0 > /sys/module/xt_qtaguid/parameters/debug_mask

#####
#Supersu
#
/system/xbin/daemonsu --auto-daemon &

########################################################
# initialize init.d
#
if [ -d /system/etc/init.d ]; then
	/sbin/busybox run-parts /system/etc/init.d
fi;

########################################################
# Google Services battery drain fixer
#

# stop google service and restart it on boot. this remove high cpu load and ram leak!
	if [ "$($BBX pidof com.google.android.gms | wc -l)" -eq "1" ]; then
		$BBX kill "$($BBX pidof com.google.android.gms)";
	fi;
	if [ "$($BBX pidof com.google.android.gms.unstable | wc -l)" -eq "1" ]; then
		$BBX kill "$($BBX pidof com.google.android.gms.unstable)";
	fi;
	if [ "$($BBX pidof com.google.android.gms.persistent | wc -l)" -eq "1" ]; then
		$BBX kill "$($BBX pidof com.google.android.gms.persistent)";
	fi;
	if [ "$($BBX pidof com.google.android.gms.wearable | wc -l)" -eq "1" ]; then
		$BBX kill "$($BBX pidof com.google.android.gms.wearable)";
	fi;

# Google Services battery drain fixer by Alcolawl@xda
# http://forum.xda-developers.com/google-nexus-5/general/script-google-play-services-battery-t3059585/post59563859
$busybox sleep 10
pm enable com.google.android.gms/.update.SystemUpdateActivity
pm enable com.google.android.gms/.update.SystemUpdateService
pm enable com.google.android.gms/.update.SystemUpdateService$ActiveReceiver
pm enable com.google.android.gms/.update.SystemUpdateService$Receiver
pm enable com.google.android.gms/.update.SystemUpdateService$SecretCodeReceiver
pm enable com.google.android.gsf/.update.SystemUpdateActivity
pm enable com.google.android.gsf/.update.SystemUpdatePanoActivity
pm enable com.google.android.gsf/.update.SystemUpdateService
pm enable com.google.android.gsf/.update.SystemUpdateService$Receiver
pm enable com.google.android.gsf/.update.SystemUpdateService$SecretCodeReceiver

exit;
