## OpenWrt installation instructions for Arris TR4400 v2 / RAC2V1A

### Requirements

- A linux box (Windows and macOS should also work but have not been tested).
- Serial port access to the router (more info [here](https://openwrt.org/inbox/toh/arris/tr4400_v2#serial)).
- Ethernet connection to the router (Wi-Fi connection should also work but has not been tested).
- Serial port terminal software (eg: gtkterm).
- SSH and SCP client software with configued keys.

**Note:** While issuing the SCP commands detailed bellow, you might encounter errors related to option `-O` not being recongnized. In such a case, simply leave out the `-O` option from all SCP commnands.
This happens if you are using an SCP version older than 8.7 (use `ssh -V` to check your version). The option is required on recent SCP versions due to deprecation of the old SCP/RCP protocol. 
More details [here](https://github.com/Lanchon/openwrt-rt4230w-rev6/pull/3#issuecomment-1472474007).

### Preparation

1. Clone this repository.
2. [Download](https://firmware-selector.openwrt.org/?version=23.05.5&target=ipq806x%2Fgeneric&id=arris_tr4400-v2)
   OpenWrt initramfs (kernel) and squashfs (sysupgrade) images for this router to the checkout directory.
   **Important:** The initramfs (kernel) image will be used as an emergency recovery OS, so it is vital that it works when needed.
   Do not use the latest release or a snapshot as a recovery image for the sake of it, use a *known-good image* tested to work for this role.
   At the time of this writing, the images previously linked are the newest known-good images.
   In contrast, the squashfs (sysupgrade) image will be used as the main OS, so you could choose any version you want.
   But it is still recommended to flash a known-good image first to test the installation, and upgrade to
   the [latest available image](https://firmware-selector.openwrt.org/?target=ipq806x%2Fgeneric&id=arris_tr4400-v2) afterwards.
3. Edit `enable-ssh-template.txt` and paste your public RSA SSH key where indicated in the file.
4. Connect the serial cable, open the terminal, and boot up the router.
5. When booting is finished, press `ENTER` to access a root console.
6. Paste the contents of `enable-ssh-template.txt` into the console to enable SSH access.
7. Connect to the router via Ethernet or Wi-Fi using manual IP 192.168.1.2 or DHCP.
8. Pop up a terminal in the checkout directory and verify SSH access by typing:
```
ssh root@192.168.1.1 "cat /proc/version"
```
- Output should be similar to:
```
Linux version 3.14.43 (mark@sercomm-QCA-Server) (gcc version 4.8.3 (OpenWrt/Linaro GCC 4.8-2014.01 r1121) ) #1 SMP PREEMPT Thu Mar 1 14:52:59 CST 2018
```
9. Run a check of the state of your router:
```
ssh root@192.168.1.1 sh <check-svn1418.sh
```
- Output should be similar to:
```
This script checks the current state of your router in depth.
If all checks pass, you are good to go on installing OpenWrt.
The router USB port should be empty when running this script.

checking /proc/cmdline
checking /etc/svn.info
checking /etc/openwrt_release
checking /proc/version
checking /proc/mtd
checking /proc/mounts
checking /proc/bus/pci/devices
checking fw_printenv
checking dmesg-ubi-attached
checking dmesg-ubifs-mounted
checking ubi0_0-kernel
checking ubi0_1-ubi_rootfs
checking ubi0_2-rootfs_data

WARNING: Do not proceed installing OpenWrt if any errors were output!
Save the output and seek help in the forums instead.
```
- Do not proceed if errors are shown in the ouput!

### Backup the stock firmware

1. Create and transfer backups of all MTD partitions:
```
ssh root@192.168.1.1 sh <mtd-backup.sh
scp -O root@192.168.1.1:/tmp/lanchon/mtd-backup.tar .
ssh root@192.168.1.1 "rm /tmp/lanchon/mtd-backup.tar"
```
2. Create and transfer backups of all UBI volumes:
```
ssh root@192.168.1.1 sh <ubi-backup.sh
scp -O root@192.168.1.1:/tmp/lanchon/ubi-backup.tar .
ssh root@192.168.1.1 "rm /tmp/lanchon/ubi-backup.tar"
```
- You might need these backups down the road, so store them.

### Install OpenWrt

Make sure you have backups of the stock firmware (see previous section); each device is different.

1. Install the initramfs recovery image:
```
scp -O openwrt-[...]-arris_tr4400-v2-initramfs-uImage root@192.168.1.1:/tmp/recovery.bin
ssh root@192.168.1.1 sh <install-recovery.sh
```
2. Sysupgrade to the squashfs image:
- Reboot router and connect to http://192.168.1.1/cgi-bin/luci/admin/system/flash.
- Click on `Flash image...` and choose the squashfs image.
3. Reconnect to http://192.168.1.1/ and profit!

### Update the recovery image

This section is only provided for completeness. There is no reason to upgrade the recovery image.
The recovery image should work when needed, so it should be a tested known-good image for this role, not the latest one.
Also, if a return-to-stock if ever attempted on this router, it *must* be done while running a 23.05.x series recovery, which is yet another reason to not upgrade it.

1. Make sure that you have serial access to the device to test the recovery OS that you are about to flash.
2. Make sure that the router has a working main OS, and that it is currently running it (ie, it is not running the recovery OS).
3. [Download](https://firmware-selector.openwrt.org/?target=ipq806x%2Fgeneric&id=arris_tr4400-v2) the OpenWrt initramfs (kernel) image for this router.
4. Pop up a terminal and write the recovery image (replace 192.168.1.1 with the address of your router):
```
scp -O openwrt-[...]-arris_tr4400-v2-initramfs-uImage root@192.168.1.1:/tmp/recovery.bin
ssh root@192.168.1.1 'ubiupdatevol /dev/ubi0_9 /tmp/recovery.bin && rm /tmp/recovery.bin'
```
5. Interrupt the boot process to get a U-Boot prompt and type `run boot_recovery` to test the new image.

