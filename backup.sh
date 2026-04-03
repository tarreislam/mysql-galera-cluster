#!/bin/bash
BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M")

# Default retention to 7 days if not set
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"

# Remove files older than retention period
find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +"$BACKUP_RETENTION_DAYS" -exec rm -f {} \;

# Backup each database
for db in $(mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "Database|information_schema|performance_schema|mysql|sys"); do
    FILE="${db}_${TIMESTAMP}.sql"
    TARFILE="${db}_${TIMESTAMP}.tar.gz"

    mariadb-dump -uroot -p"$MYSQL_ROOT_PASSWORD" "$db" > "$BACKUP_DIR/$FILE"
    tar -czf "$BACKUP_DIR/$TARFILE" -C "$BACKUP_DIR" "$FILE"
    rm "$BACKUP_DIR/$FILE"
done