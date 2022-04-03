check() {
	local file="$1"
	echo checking "$1"
	if ! cmp "$1" -; then
		echo
		echo "### ERROR: $1"
		cat "$1"
		echo
	fi
}

echo
echo "This script checks the current state of your router in depth."
echo "If all checks pass, you are good to go on installing OpenWRT."
echo "The router USB port should be empty when running this script."
echo

check /proc/cmdline <<EOF
console=ttyMSM0,115200n8 ubi.mtd=rootfs root=mtd:ubi_rootfs rootfstype=squashfs
EOF

check /etc/svn.info <<EOF
Path: .
URL: svn://10.10.67.238:36901/svn/Router/TR4400v2/TR4400v2_0419b/Source
Repository Root: svn://10.10.67.238:36901/svn/Router/TR4400v2
Repository UUID: a6b6dc33-2ea1-44c0-8bf5-3169134277e6
Revision: 1418
Node Kind: directory
Schedule: normal
Last Changed Author: sandy
Last Changed Rev: 1418
Last Changed Date: 2018-03-01 16:54:42 +0800 (Thu, 01 Mar 2018)

VERSION:
Build from: sercomm-QCA-Server /home2/mark/TR4400v2_0419b_0301/Source by mark
DATE: Thu Mar 1 17:10:58 CST 2018
BOARD_ID: TR4400-CH
EOF

check /etc/openwrt_release <<EOF
DISTRIB_ID="OpenWrt"
DISTRIB_RELEASE="Bleeding Edge"
DISTRIB_REVISION="r1121"
DISTRIB_CODENAME="barrier_breaker"
DISTRIB_TARGET="ipq806x/generic"
DISTRIB_DESCRIPTION="OpenWrt Barrier Breaker r1121"
DISTRIB_TAINTS="no-all busybox override"
EOF

check /proc/version <<EOF
Linux version 3.14.43 (mark@sercomm-QCA-Server) (gcc version 4.8.3 (OpenWrt/Linaro GCC 4.8-2014.01 r1121) ) #1 SMP PREEMPT Thu Mar 1 14:52:59 CST 2018
EOF

check /proc/mtd <<EOF
dev:    size   erasesize  name
mtd0: 00040000 00020000 "0:SBL1"
mtd1: 00140000 00020000 "0:MIBIB"
mtd2: 00140000 00020000 "0:SBL2"
mtd3: 00280000 00020000 "0:SBL3"
mtd4: 00120000 00020000 "0:DDRCONFIG"
mtd5: 00120000 00020000 "0:SSD"
mtd6: 00280000 00020000 "0:TZ"
mtd7: 00280000 00020000 "0:RPM"
mtd8: 00500000 00020000 "0:APPSBL"
mtd9: 00080000 00020000 "0:APPSBLENV"
mtd10: 00140000 00020000 "0:ART"
mtd11: 04000000 00020000 "rootfs"
mtd12: 00060000 00020000 "0:BOOTCONFIG"
mtd13: 00140000 00020000 "0:SBL2_1"
mtd14: 00280000 00020000 "0:SBL3_1"
mtd15: 00120000 00020000 "0:DDRCONFIG_1"
mtd16: 00120000 00020000 "0:SSD_1"
mtd17: 00280000 00020000 "0:TZ_1"
mtd18: 00280000 00020000 "0:RPM_1"
mtd19: 00060000 00020000 "0:BOOTCONFIG1"
mtd20: 00500000 00020000 "0:APPSBL_1"
mtd21: 04000000 00020000 "rootfs_1"
mtd22: 00100000 00020000 "fw_env"
mtd23: 00800000 00020000 "config"
mtd24: 00200000 00020000 "PKI"
mtd25: 00100000 00020000 "scfgmgr"
mtd26: 00008000 00008000 "spi32766.0"
mtd27: 003e0000 0001f000 "kernel"
mtd28: 01e08000 0001f000 "ubi_rootfs"
mtd29: 0001f000 0001f000 "rootfs_data"
mtd30: 00744000 0001f000 "ubi_config"
EOF

check /proc/mounts <<EOF
rootfs / rootfs rw 0 0
mtd:ubi_rootfs /rom squashfs ro,relatime 0 0
proc /proc proc rw,noatime 0 0
sysfs /sys sysfs rw,noatime 0 0
tmpfs /tmp tmpfs rw,nosuid,nodev,noatime 0 0
tmpfs /tmp/root tmpfs rw,noatime,mode=755 0 0
overlayfs:/tmp/root / overlayfs rw,noatime,lowerdir=/,upperdir=/tmp/root 0 0
tmpfs /dev tmpfs rw,relatime,size=512k,mode=755 0 0
devpts /dev/pts devpts rw,relatime,mode=600 0 0
debugfs /sys/kernel/debug debugfs rw,noatime 0 0
ramfs /home ramfs rw,relatime 0 0
ramfs /mnt ramfs rw,relatime 0 0
ramfs /etc ramfs rw,relatime 0 0
ubi1:ubi_config /config ubifs rw,relatime 0 0
EOF

check /proc/bus/pci/devices <<EOF
0000	17cb0101	44	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	
0100	168c0046	44	         8000004	               0	               0	               0	               0	               0	               0	          200000	               0	               0	               0	               0	               0	               0	ath_pci
0000	17cb0101	5a	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	               0	
0100	168c0040	5a	        2e000004	               0	               0	               0	               0	               0	               0	          200000	               0	               0	               0	               0	               0	               0	ath_pci
EOF

check /etc/fw_env.config <<EOF
/dev/mtd9 0x0 0x40000 0x00020000 2
EOF

mkdir -p /tmp/lanchon
cd /tmp/lanchon

fw_printenv >fw_printenv
check fw_printenv <<EOF
baudrate=115200
bootargs=console=ttyMSM0,115200n8
bootcmd=bootipq
bootdelay=2
ethact=eth0
machid=1260
stderr=serial
stdin=serial
stdout=serial
EOF

dmesg | grep -o "UBI: attached .*" >dmesg-ubi-attached
check dmesg-ubi-attached <<EOF
UBI: attached mtd11 (name "rootfs", size 64 MiB) to ubi0
UBI: attached mtd23 (name "config", size 8 MiB) to ubi1
EOF

dmesg | grep -o "UBIFS: mounted .*" >dmesg-ubifs-mounted
check dmesg-ubifs-mounted <<EOF
UBIFS: mounted UBI device 1, volume 0, name "ubi_config"
EOF

md5sum /dev/ubi0_0 >ubi0_0-kernel
check ubi0_0-kernel <<EOF
eee27de10678f707260f90a3ac35ff0c  /dev/ubi0_0
EOF

md5sum /dev/ubi0_1 >ubi0_1-ubi_rootfs
check ubi0_1-ubi_rootfs <<EOF
c0edea192786289b6d6acc1fb60b3eb2  /dev/ubi0_1
EOF

# rootfs_data is not mountable and is just a single LEB of 0xFFs
# openwrt falls back to a tmpfs overlay
md5sum /dev/ubi0_2 >ubi0_2-rootfs_data
check ubi0_2-rootfs_data <<EOF
f7d566ac0d14fb993db66ed5ea370797  /dev/ubi0_2
EOF

echo
echo "WARNING: Do not proceed installing OpenWrt if any errors were output!"
echo "Save the output and seek help in the forums instead."
echo

