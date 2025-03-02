#!/bin/bash

# Directory where backups are stored
DRIVE_MOUNT="/mnt/ssd1" #edit this to the location of mounted drive path only
BACKUP_DIR="/mnt/ssd1/raspberryPiBackUps/img"
LOG_FILE="$BACKUP_DIR/backup_log.txt"

# Ensure the log directory exists
mkdir -p "$BACKUP_DIR"

# Check if the backup directory is mounted
if ! mount | grep -q "$DRIVE_MOUNT"; then
    echo "ERROR: Backup destination drive $DRIVE_MOUNT is not mounted!" | tee -a "$LOG_FILE"
    exit 1
fi

# Log mount points for debugging
mount | tee -a "$LOG_FILE"

# Get the   

# Define the backup filename with the current date
BACKUP_FILE="$BACKUP_DIR/pi_backup_$DATE.img.gz"

# Check if enough space is available on the destination disk
AVAILABLE_SPACE=$(df --output=avail "$BACKUP_DIR" | tail -n 1)

# Check if there's enough space for a 10GB backup
if [ "$AVAILABLE_SPACE" -lt 10000000 ]; then
    echo "ERROR: Not enough space on the backup disk!" | tee -a "$LOG_FILE"
    exit 1
fi

# Start timer
START_TIME=$(date +%s)

# Perform the backup
echo "Starting backup..." | tee -a "$LOG_FILE"
sudo dd if=/dev/mmcblk0 bs=4M status=progress | gzip > "$BACKUP_FILE" #change the disk name using lsblk command

# Check for any errors during the backup
if [ $? -eq 0 ]; then
    echo "Backup completed: $BACKUP_FILE" | tee -a "$LOG_FILE"
else
    echo "ERROR: Backup failed!" | tee -a "$LOG_FILE"
    exit 1
fi

# End timer and calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Log the time taken for the backup
echo "$(date +'%Y-%m-%d %H:%M:%S') - Backup completed: $BACKUP_FILE - Time Taken: ${DURATION}s" >> "$LOG_FILE"

# Delete backups older than 7 days
echo "Deleting backups older than 7 days..." | tee -a "$LOG_FILE"
find "$BACKUP_DIR" -type f -name "pi_backup_*.img.gz" -mtime +7 -exec rm -f {} \;

# Log old backup deletion
echo "$(date +'%Y-%m-%d %H:%M:%S') - Old backups deleted." >> "$LOG_FILE"

echo "Backup and cleanup completed."
