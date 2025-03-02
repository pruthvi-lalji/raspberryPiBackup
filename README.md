# **raspberryPiBackup**

This repo contains script to backup raspberrypi fully or incrementally.

- Full backup contains use of `dd`
- Incremental backup uses `rsync`

Includes backing up raspberrypi incrementally and or full back up image

**Step of restore incremental back up**
This restore would be done on a brand new disk without any partition or data **(data will be erased be careful)**

Plug in the new drive into the machine

Use command lsblk to find the disk location

    lsblk

Identify the drive where backup to be restored to

Format / Create paritions in the disk

    sudo fdisk /dev/sdX

- if any partitions exist then delete them

Create Boot Parition

- press `d` and then `enter` untill all partitions are removed
- press `n` to create parition
- press `p` to create primaray parition
- press enter on first section
- type `+256M` for the last section

Create Root Parititon

- press `n` to create parition
- press `p` to create primaray parition
- press enter on first sector and enter again for last sector
- press `w` to save the paritions

Formatting the partitions

    sudo mkfs.vfat /dev/sdX1  # Boot partition
    sudo mkfs.ext4 /dev/sdX2  # Root filesystem

Mount the new drive

    sudo mount /dev/sdX2 /mnt/new_drive  # Root partition
    sudo mkdir /mnt/new_drive/boot
    sudo mount /dev/sdX1 /mnt/new_drive/boot  # Boot partition

Check that the backup is lastest (if restoring from lastest backup)

    ls -l /mnt/ssd1/backup/incremental_backups/latest

if restoring from old back up and it is compress

    ls /mnt/ssd1/backup/incremental_backups/*.tar.gz
    sudo tar -xzf /mnt/ssd1/backup/i ncremental_backups/backup_<DATE>.tar.gz -C /mnt/new_drive/

Once restore verify boot

    ls /mnt/new_drive/boot

After restoring, the boot partition (typically `/boot`) should contain the following critical files and directories:

- `bootcode.bin`
- `start.elf`
- `config.txt`
- `cmdline.txt`
- Kernel files (e.g., `kernel7.img`, `kernel8.img`).

If these are missing download them from

    git clone --depth=1 https://github.com/raspberrypi/firmware.git

Move boot files to `/boot`

    sudo cp -r firmware/boot/* /mnt/boot/
    or
    mv mnt /firmware/* /mnt/new_drive/boot

Once these has been done we need to manually edit the configs

Get the drive `PARTUUID`

    $ sudo blkid

    /dev/mmcblk0p1: LABEL_FATBOOT="bootfs" LABEL="bootfs" UUID="4EF5-6F55" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="ce3182db-01"
    /dev/mmcblk0p2: LABEL="rootfs" UUID="ce208fd3-38a8-424a-87a2-cd44114eb820" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="ce3182db-02"
    /dev/sdb2: UUID="c801fdeb-31fd-4e1a-8015-b32326ca7e09" BLOCK_SIZE="4096" TYPE="ext4" PARTUUID="0d05476d-02"
    /dev/sdb1: UUID="267A-C195" BLOCK_SIZE="512" TYPE="vfat" PARTUUID="0d05476d-01"

Firstly edit `cmdline.txt`

    sudo nano /mnt/new_drive/boot/cmdline.txt

And replace root={PARTUUI}

    root=PARTUUID={DRIVE_UUID}-02 rootfstype=ext4 rootwait

Edit `fstab` config

    sudo nano /mnt/new_drive/etc/fstab

replace the boot/firmware and / partuuid with the drive

    proc            /proc           proc    defaults          0       0
    PARTUUID={DRIVE_UUID}-01  /boot/firmware  vfat    defaults          0       2
    PARTUUID={DRIVE_UUID}-02  /               ext4    defaults,noatime  0       1

Sync all the changes are saved

    sudo sync

Unmount the drive

    sudo umount /mnt/new_drive/boot
    sudo umount /mnt/new_drive

And remove and plug into into raspberry pi
