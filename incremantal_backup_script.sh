#!/bin/bash

# Configuration variables
SOURCE_DIR="/"                             
DRIVE_MOUNT="/mnt/backupDrive" #edit this to the location of mounted drive path only
BACKUP_DIR="$DRIVE_MOUNT/raspberryPiBackUps/incremental_backups"   #location of the actual path to the backup directory
LOG_FILE="$BACKUP_DIR/log.txt"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")          
BACKUP_NAME="backup_$DATE"                   
MAX_BACKUPS=7                             
LATEST_SYMLINK="$BACKUP_DIR/latest"        

# Exclusions - can be edited to your preference
EXCLUDE_LIST=("--exclude=/dev/*" "--exclude=/proc/*" "--exclude=/sys/*" "--exclude=/tmp/*" "--exclude=/run/*" "--exclude=/mnt/*" "--exclude=/media/*" "--exclude=/lost+found")

# Create the backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Start timer
START_TIME=$(date +%s)

# Perform the incremental backup using rsync
echo "$(date +"%Y-%m-%d %H:%M:%S") - Starting backup: $DATE" >> $LOG_FILE

# Perform incremental backup - check if this is first backup and creates full backup if not create incremental backup based on the link
NEW_BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
if [ -e "$LATEST_SYMLINK" ] && [ -d "$LATEST_SYMLINK" ]; then
    echo "Performing incremental backup..." >> $LOG_FILE
    rsync -aAXv --link-dest="$LATEST_SYMLINK" --delete "${EXCLUDE_LIST[@]}" "$SOURCE_DIR" "$NEW_BACKUP_PATH"
else
    echo "No valid 'latest' backup found. Performing full backup..." >> $LOG_FILE
    rsync -aAXv --delete "${EXCLUDE_LIST[@]}" "$SOURCE_DIR" "$NEW_BACKUP_PATH"
fi

# Update the latest symlink
rm -f "$LATEST_SYMLINK"
ln -s "$NEW_BACKUP_PATH" "$LATEST_SYMLINK"


# (Optional) -  Compress older backups
OLD_BACKUPS=$(find $BACKUP_DIR -mindepth 1 -maxdepth 1 -type d ! -name "latest" -not -samefile "$LATEST_SYMLINK")
for BACKUP in $OLD_BACKUPS; do
    if [ -d "$BACKUP" ]; then
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Compressing backup $BACKUP..." >> $LOG_FILE
        tar -czf "$BACKUP.tar.gz" -C "$BACKUP_DIR" "$(basename $BACKUP)"
        rm -rf "$BACKUP"
    fi
done

# Deduplicate files using rdfind
echo "$(date +"%Y-%m-%d %H:%M:%S") - Running rdfind to deduplicate files..." >> $LOG_FILE
rdfind -makehardlinks true "$BACKUP_DIR" > "$BACKUP_DIR/rdfind.log" 2>&1

# End timer and calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Log the completion of the backup
echo "$(date +"%Y-%m-%d %H:%M:%S") - Backup $BACKUP_NAME completed in ${DURATION}s" >> $LOG_FILE

# (OPTIONAL) - Clean up old backups 
BACKUP_COUNT=$(find $BACKUP_DIR -mindepth 1 -maxdepth 1 \( -type d -name "backup_*" -o -type f -name "backup_*.tar.gz" \) | wc -l)

if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    BACKUPS_TO_DELETE=$(find $BACKUP_DIR -mindepth 1 -maxdepth 1 \( -type d -name "backup_*" -o -type f -name "backup_*.tar.gz" \) -printf "%T@ %p\n" | sort -n | head -n $((BACKUP_COUNT - MAX_BACKUPS)) | cut -d ' ' -f 2-)
    echo "$BACKUPS_TO_DELETE" >> $LOG_FILE

    for OLD_BACKUP in $BACKUPS_TO_DELETE; do
        echo "$(date +"%Y-%m-%d %H:%M:%S") - Deleting old backup: $OLD_BACKUP" >> $LOG_FILE
        rm -rf "$OLD_BACKUP"  # Use rm -rf to handle both files and directories
    done
fi

# Log the completion of the cleanup
echo "$(date +"%Y-%m-%d %H:%M:%S") - Backup and cleanup completed" >> $LOG_FILE
