#!/bin/sh

if [ $# -lt 1 ]; then
	exit 0;
fi

function get_current_root_device
{
	for i in `cat /proc/cmdline`; do
		if [ ${i:0:5} = "root=" ]; then
			CURRENT_ROOT="${i:5}"
		fi
	done
}

function get_update_part
{
	CURRENT_PART="${CURRENT_ROOT: -1}"
	if [ $CURRENT_PART = "4" ]; then
		UPDATE_PART="5";
	else
		UPDATE_PART="4";
	fi
}

function get_update_device
{
	UPDATE_ROOT=${CURRENT_ROOT%?}${UPDATE_PART}
}

function format_update_device
{
	umount $UPDATE_ROOT
	umount /dev/mmcblk0p6
	mkfs.ext4 $UPDATE_ROOT -F -L rootfs${UPDATE_PART}
}

function reboot
{
	echo "Rebooting U54 Board"
	echo 506 > /sys/class/gpio/export
	cd /sys/class/gpio/gpio506
	sleep 5
	echo in > direction
	sleep 5
	echo out > direction
	sleep 5

}


if [ $1 == "preinst" ]; then
	# get the current root device
	get_current_root_device

	# get the device to be updated
	get_update_part

	get_update_device
	echo $UPDATE_ROOT

	# format the device to be updated
	#format_update_device

	echo "create symbolic link"
	# create a symlink for the update process
	umount /dev/mmcblk0p6
	ln -sf $UPDATE_ROOT /dev/update
fi

if [ $1 == "postinst" ]; then

	get_current_root_device
	get_update_part
	echo $UPDATE_PART
	get_update_device
#	echo Update U-Boot variable: bootpart=$UPDATE_PART
	echo new partition: $UPDATE_ROOT
	if [[ "$UPDATE_PART" -eq 4 ]]; then
		#fw_setenv bootargs earlycon=sbi root=/dev/mmcblk0p4 rootwait console=ttySIF0 console=tty0
		fw_setenv active_part 4
		fw_setenv first_time_boot_b 1
		fw_setenv part_b_boot_success 0
		mkdir -p /mnt/userdata
#		mount /dev/mmcblk0p6 /mnt/user-data
		mount /dev/mmcblk0p6 /mnt
		
	else
		#fw_setenv bootargs earlycon=sbi root=/dev/mmcblk0p5 rootwait console=ttySIF0 console=tty0
		fw_setenv active_part 5
		fw_setenv first_time_boot_b 1
		fw_setenv part_b_boot_success 0 
		
#		mkdir -p /mnt/4
#		mkdir -p /mnt/5
#		mkdir -p /mnt/userdata
#		mount /dev/mmcblk0p4 /mnt/4
#		mount /dev/mmcblk0p5 /mnt/5
#		mount /dev/mmcblk0p6 /mnt/userdata
#		cp -R /mnt/4/home/root/swupdate /mnt/5/home/root/swupdate
#		umount /mnt/4
#		umount /mnt/5

	fi
	sleep 5	
	reboot
#	fw_setenv bootpart $UPDATE_PART

#	fi

#	get_update_part

#	fw_setenv mmcbootpart $UPDATE_PART
#	fw_setenv mmcrootpart $UPDATE_PART
fi

