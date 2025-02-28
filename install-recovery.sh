set -e

echo
if [[ "$(cat /sys/class/mtd/mtd11/name)" == "rootfs" ]]; then
	echo "currently active OS slot: primary OS slot (mtd11)"
elif [[ "$(cat /sys/class/mtd/mtd21/name)" == "rootfs" ]]; then
	echo "currently active OS slot: secondary OS slot (mtd21)"
	echo
	echo "OpenWrt installation on this router requires relocating the critical fw_env partition"
	echo "to consolidate free space, which involves overwriting the secondary OS slot (mtd21)."
	echo "installation cannot proceed because the OS is currently running from this slot."
	echo
	echo "recommended steps:"
	echo "1) copy currently running OS from secondary slot (mtd21) to primary slot (mtd11)."
	echo "2) switch active OS slot to primary:"
	echo "   a) make sure the contents of 0:BOOTCONFIG (mtd12) are valid."
	echo "   b) set the 'age' field of 0:BOOTCONFIG1 (mtd19) to zero."
	echo "      age is the second 32-bit word of the partition (byte offsets 4 though 7)."
	echo "3) reboot and retry the installation."
	echo
	echo "error: secondary OS slot is currently active"
	exit 1
else
	echo "error: could not determine currently active OS slot"
	exit 1
fi

if [[ "$1" != "-f" ]]; then
	echo
	echo "checking current firmware version (-f to disable check)"
	echo "55f6b818d40eafde3067e0505bd1343f  /etc/svn.info" | md5sum -c -
fi

echo
echo "checking for downloaded initramfs recovery image"
ls -l /tmp/recovery.bin

echo
echo "creating recovery volume"
ubirmvol /dev/ubi0 -N recovery || true
ubimkvol /dev/ubi0 -N recovery -n 9 -s 12MiB
echo "installing recovery"
ubiupdatevol /dev/ubi0_9 /tmp/recovery.bin

echo
echo "checking status of new fw_env partition"
if [[ "$(head -c 4 /dev/mtd21)" == "UBI#" ]]; then
	echo "stock ubi partition found, data copy from stock fw_env needed"
	echo "verifying contents of stock fw_env partition"
	head -c 512 /dev/mtd22 | strings | grep -e MySpectrumWiFi -e SpectrumSetup
	echo "attempting backup of fw_env data"
	if ubimkvol /dev/ubi0 -N fw_env_backup -n 8 -s 126976; then
		dd if=/dev/mtd22 bs=126976 count=1 | ubiupdatevol -s 126976 /dev/ubi0_8 -
	fi
	echo "copying contents of stock fw_env partition"
	mtd erase /dev/mtd21 && dd if=/dev/mtd22 bs=128K count=1 | mtd write - /dev/mtd21
else
	echo "custom non-ubi partition found"
fi
echo "verifying contents of new fw_env partition"
head -c 512 /dev/mtd21 | strings | grep -e MySpectrumWiFi -e SpectrumSetup

# NOTE: to revert the move use:
#head -c 512 /dev/mtd21 | strings | grep -e MySpectrumWiFi -e SpectrumSetup && mtd erase /dev/mtd22 && dd if=/dev/mtd21 bs=128K count=1 | mtd write - /dev/mtd22

echo
echo "checking status of config ubi partition"
if mount | fgrep "ubi1:ubi_config on /config"; then
	echo "wiping config ubi partition"
	umount /config && ubidetach -m 23 && mtd erase /dev/mtd23
fi

echo
echo "setting up u-boot environment"
fw_setenv -s - <<"EOF"

boot_stock bootipq
boot_custom test -n "$boot_pre" && run boot_pre; run boot_main; run boot_recovery; run boot_tftp

boot_main set mtdids nand0=nand0 && set mtdparts mtdparts=nand0:155M@0x6500000(mtd_ubi) && ubi part mtd_ubi && ubi read 0x44000000 kernel && bootm

boot_recovery run boot_ubi_recovery; run boot_extra_recovery
boot_ubi_recovery set mtdids nand0=nand0 && set mtdparts mtdparts=nand0:155M@0x6500000(mtd_ubi) && ubi part mtd_ubi && ubi read 0x44000000 recovery && bootm
boot_extra_recovery set mtdids nand0=nand0 && set mtdparts mtdparts=nand0:64M@0x1340000(mtd_extra) && ubi part mtd_extra && ubi read 0x44000000 recovery && bootm

boot_tftp test -n "$ipaddr" || set ipaddr 192.168.1.1; test -n "$serverip" || set serverip 192.168.1.2; tftpboot recovery.bin && bootm

bootcmd run boot_custom

EOF

sync

echo
echo "all done!"
echo
echo "a reboot should now take you to the recovery initramfs firmware"
echo "from there do a sysupgrade to a squashfs firmware to finish the install"
echo

