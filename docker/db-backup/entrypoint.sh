#!/bin/sh
# Automated IPS4 database backup with retention management.
# Runs a backup on startup (catches build/rebuild) then on schedule.
# All settings configurable via environment variables.

set -e

BACKUP_DIR="/backups"
DB_HOST="${DB_HOST:-db}"
DB_USER="${DB_USER:-ips}"
DB_PASS="${DB_PASS:-}"
DB_NAME="${DB_NAME:-ips}"

# Configurable schedule and retention (override via env)
BACKUP_INTERVAL_HOURS="${BACKUP_INTERVAL_HOURS:-1}"  # hours between backups (default: 1)
BACKUP_RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"   # delete backups older than this

# Convert hours to seconds for sleep
BACKUP_INTERVAL_SECS=$(awk "BEGIN{printf \"%d\", $BACKUP_INTERVAL_HOURS * 3600}")

if [ -z "$DB_PASS" ]; then
  echo "db-backup: DB_PASS not set, cannot run backups"
  exit 1
fi

mkdir -p "$BACKUP_DIR"

# Wait for MySQL to be ready
wait_for_db() {
  _i=0
  while [ "$_i" -lt 60 ]; do
    if mysqladmin ping -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" --silent 2>/dev/null; then
      return 0
    fi
    _i=$((_i + 1))
    sleep 2
  done
  echo "db-backup: timed out waiting for database"
  return 1
}

# Check if database has tables worth backing up
has_tables() {
  _count=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='$DB_NAME'" 2>/dev/null)
  [ -n "$_count" ] && [ "$_count" -gt 0 ]
}

# Run a single backup
do_backup() {
  _date=$(date +%Y-%m-%d)
  _time=$(date +%H%M%S)
  _file="${BACKUP_DIR}/${_date}_${_time}.sql.gz"

  # Check database has tables
  if ! has_tables; then
    echo "db-backup: database has no tables, skipping"
    return 0
  fi

  echo "db-backup: creating backup..."
  if mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" \
       --single-transaction --routines --triggers "$DB_NAME" 2>/dev/null \
     | gzip > "$_file"; then
    _size=$(du -h "$_file" | cut -f1)
    echo "db-backup: created ${_date}_${_time}.sql.gz (${_size})"
  else
    echo "db-backup: FAILED"
    rm -f "$_file"
    return 1
  fi

  # Retention cleanup: delete backups older than retention period
  find "$BACKUP_DIR" -name "*.sql.gz" -mtime +"$BACKUP_RETENTION_DAYS" -print -delete 2>/dev/null | while read -r f; do
    echo "db-backup: removed old $(basename "$f")"
  done
}

# Main
echo "db-backup: starting (every=${BACKUP_INTERVAL_HOURS}h, retention=${BACKUP_RETENTION_DAYS}d)"
wait_for_db || exit 1

# Backup on startup (catches build/rebuild)
do_backup

# Then run on schedule
echo "db-backup: next backup in ${BACKUP_INTERVAL_HOURS}h"
while true; do
  sleep "$BACKUP_INTERVAL_SECS"
  do_backup
  echo "db-backup: next backup in ${BACKUP_INTERVAL_HOURS}h"
done
