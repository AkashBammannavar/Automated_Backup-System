# 🛡️ Automated Backup System

A smart, configurable, and reliable **Automated Backup System** built
using **Bash scripting**.\
It supports backup creation, backup verification, automatic cleanup,
exclusion patterns, logging, configuration files, dry run mode, and
prevention of duplicate runs.

## 🚀 Features Overview

### ✔ 1. Create Backups

-   Takes a folder as input\
    Example:

        ./backup.sh /home/user/my_documents

-   Creates a compressed `.tar.gz` backup\

-   Backup name format:

        backup-2024-11-03-1430.tar.gz

-   Generates SHA-256 checksum:

        backup-2024-11-03-1430.tar.gz.sha256

-   Skips unnecessary folders:

    -   `.git`
    -   `node_modules`
    -   `.cache`
    -   Custom exclusions (configured)

### ✔ 2. Automatic Cleanup of Old Backups

Keeps: - 7 daily backups\
- 4 weekly backups\
- 3 monthly backups

### ✔ 3. Backup Verification

-   Recalculates checksum and compares\
-   Tests backup integrity\
-   Prints SUCCESS / FAILED

### ✔ 4. Intelligent Features

-   Configuration file (`backup.config`)\
-   Logging (`backup.log`)\
-   Dry run mode (`--dry-run`)\
-   Lock file to prevent multiple runs

## 📁 Project Structure

    devops-backup-project/
    │
    ├── backup.sh          
    ├── backup.config      
    └── README.md          

## ⚙️ Setup Instructions

### 1️⃣ Make script executable

``` bash
chmod +x backup.sh
```

### 2️⃣ Configure settings

    BACKUP_DESTINATION=/home/backups
    EXCLUDE_PATTERNS=".git,node_modules,.cache"
    DAILY_KEEP=7
    WEEKLY_KEEP=4
    MONTHLY_KEEP=3

## ▶️ How to Run

### Basic Backup

``` bash
./backup.sh /path/to/folder
```

### Dry Run

``` bash
./backup.sh --dry-run /path/to/folder
```

------------------------------------------------------------------------

# 📜 Full Script (backup.sh)

    #!/bin/bash
    # (Content omitted here for brevity – your actual script is preserved separately)

------------------------------------------------------------------------

# End of README
