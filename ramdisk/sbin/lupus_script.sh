#!/sbin/busybox sh
BB=/sbin/busybox

$BB mount -o remount,rw /system
$BB mount -t rootfs -o remount,rw rootfs
$BB chmod 777 /res/uci.sh

# some minor tweaks
$BB echo 90 > /proc/sys/vm/swappiness
for i in /sys/block/*/queue/add_random;do $BB echo 0 > $i;done
$BB echo 0 > /proc/sys/kernel/randomize_va_space

# install Stweaks
if [ ! -f /system/app/STweaks.apk ]; then
  $BB cat /res/STweaks.apk > /system/app/STweaks.apk
  $BB chown 0.0 /system/app/STweaks.apk
  $BB chmod 644 /system/app/STweaks.apk
fi

$BB rm -f /res/Stweaks.apk

$BB mkdir -p /mnt/ntfs
$BB chmod 777 /mnt/ntfs
$BB mount -o mode=0777,gid=1000 -t tmpfs tmpfs /mnt/ntfs


#echo "[S] Checking modules" > /system/LuPuS-wifi-error.txt

current_sysWifi=`$BB md5sum /system/lib/modules/scsi_wait_scan.ko | $BB awk '{print $1}'`
kernel_wifi=`$BB md5sum /lib/modules/scsi_wait_scan.ko | $BB awk '{print $1}'`

if [[ "${current_sysWifi}" == "${kernel_wifi}" ]]; then
#	$BB echo "MD5 of sys =${current_sysWifi} &  MD5 of kern: ${kernel_wifi}" >> /system/LuPuS-wifi-error.txt
	$BB rm -rf /lib
elif [[ "${current_sysWifi}" != "${kernel_wifi}" ]]; then
#	$BB echo "MD5 of sys =${current_sysWifi} & MD5 of kern =${kernel_wifi}" >> /system/LuPuS-wifi-error.txt
#	$BB echo "[W] Wifi is NOT ok" >> /system/LuPuS-wifi-error.txt
		if [ -d /system/lib/modules ]; then
#			$BB echo "    Moving modules to modules.old" >> /system/LuPuS-wifi-error.txt
			$BB rm -rf /system/lib/modules.old
			$BB mv -f /system/lib/modules /system/lib/modules.old
			$BB rm -rf /system/lib/modules
		fi
#		$BB echo "    Copying new modules to system" >> /system/LuPuS-wifi-error.txt
		$BB cp -r /lib/modules /system/lib/modules
		$BB rm -rf /lib
		$BB chmod -R 755 /system/lib/modules
#else
#		$BB echo "[E] Error --- modules not installed..." >> /system/LuPuS-wifi-error.txt
fi	 








# UCI
/res/uci.sh apply
#$BB mkdir -p /data/.lupus

# Init.d
if [ -d /system/etc/init.d ]; then
  $BB run-parts /system/etc/init.d
fi

$BB mount -t rootfs -o remount,ro rootfs
$BB mount -o remount,ro /system
