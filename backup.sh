#!/bin/bash

# -------------------------------
# Smart Automated Backup Script
# -------------------------------

# --- Prevent multiple runs ---
LOCK_FILE="/tmp/backup.lock"
if [ -f "$LOCK_FILE" ]; then
    echo "Another backup is running. Exiting."
    exit 1
fi
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

# --- Load configuration ---
CONFIG_FILE="backup.config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ERROR: $CONFIG_FILE not found!"
    exit 1
fi

# --- Parse dry-run option first ---
DRY_RUN=false
if [ "$1" == "--dry-run" ]; then
    DRY_RUN=true
    shift  # Remove --dry-run so $1 becomes folder path
fi

# --- Check source folder ---
SOURCE_DIR="$1"
if [ -z "$SOURCE_DIR" ]; then
    echo "Usage: $0 [--dry-run] <folder_to_backup>"
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: '$SOURCE_DIR' is not a valid directory."
    exit 1
fi

# --- Prepare log function ---
mkdir -p "$BACKUP_DESTINATION"
LOG_FILE="$BACKUP_DESTINATION/backup.log"
log() {
    LEVEL=$1
    MESSAGE=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $LEVEL: $MESSAGE" | tee -a "$LOG_FILE"
}

log "INFO" "Starting backup of $SOURCE_DIR"

# --- Prepare backup filename ---
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")
BACKUP_FILE="backup-$TIMESTAMP.tar.gz"

# --- Prepare exclude patterns ---
IFS=',' read -r -a EXCLUDES <<< "$EXCLUDE_PATTERNS"
EXCLUDE_ARGS=()
for pattern in "${EXCLUDES[@]}"; do
    EXCLUDE_ARGS+=(--exclude="$pattern")
done

# --- Create backup ---
if [ "$DRY_RUN" = true ]; then
    log "INFO" "Would create backup $BACKUP_FILE"
else
    tar -czf "$BACKUP_FILE" "${EXCLUDE_ARGS[@]}" "$SOURCE_DIR"
    mv "$BACKUP_FILE" "$BACKUP_DESTINATION/"
    log "SUCCESS" "Backup created: $BACKUP_FILE"
fi

# --- Create checksum ---
if [ "$DRY_RUN" = true ]; then
    log "INFO" "Would generate checksum for $BACKUP_FILE"
else
    sha256sum "$BACKUP_DESTINATION/$BACKUP_FILE" > "$BACKUP_DESTINATION/$BACKUP_FILE.sha256"
    log "INFO" "Checksum saved to $BACKUP_FILE.sha256"
fi

# --- Verify backup ---
if [ "$DRY_RUN" = false ]; then
    computed_checksum=$(sha256sum "$BACKUP_DESTINATION/$BACKUP_FILE" | awk '{print $1}')
    saved_checksum=$(cat "$BACKUP_DESTINATION/$BACKUP_FILE.sha256" | awk '{print $1}')

    if [ "$computed_checksum" == "$saved_checksum" ]; then
        log "SUCCESS" "Checksum verification succeeded"
    else
        log "FAILED" "Checksum verification failed"
    fi

    if tar -tzf "$BACKUP_DESTINATION/$BACKUP_FILE" > /dev/null 2>&1; then
        log "SUCCESS" "Archive test succeeded"
    else
        log "FAILED" "Archive test failed"
    fi
fi

# --- Cleanup old backups ---
cleanup_backups() {
    log "INFO" "Cleaning old backups..."

    backups=( $(ls -1t $BACKUP_DESTINATION/backup-*.tar.gz) )

    # --- Daily backups ---
    daily_backups=( "${backups[@]:0:$DAILY_KEEP}" )

    # --- Weekly backups ---
    weekly_backups=( $(ls -1t $BACKUP_DESTINATION/backup-*.tar.gz | awk 'NR % 7 == 1' | head -n $WEEKLY_KEEP) )

    # --- Monthly backups ---
    monthly_backups=( $(ls -1t $BACKUP_DESTINATION/backup-*.tar.gz | awk 'NR % 30 == 1' | head -n $MONTHLY_KEEP) )

    # --- Combine backups to keep ---
    keep_list=( "${daily_backups[@]}" "${weekly_backups[@]}" "${monthly_backups[@]}" )
    keep_list=( $(printf "%s\n" "${keep_list[@]}" | sort -u) )

    # --- Delete old backups not in keep_list ---
    for file in "${backups[@]}"; do
        if [[ ! " ${keep_list[*]} " =~ " $file " ]]; then
            if [ "$DRY_RUN" = true ]; then
                log "INFO" "Would delete old backup: $file"
            else
                rm -f "$file"
                rm -f "$file.sha256"
                log "INFO" "Deleted old backup: $file"
            fi
        fi
    done
    log "INFO" "Cleanup finished."
}

cleanup_backups

log "INFO" "Backup process completed"
