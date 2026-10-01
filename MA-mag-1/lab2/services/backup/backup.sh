#!/bin/sh
set -eu

# sanity checks
: "${POSTGRES_HOST:?POSTGRES_HOST is required}"
: "${POSTGRES_PORT:?POSTGRES_PORT is required}"
: "${POSTGRES_USER:?POSTGRES_USER is required}"
: "${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}"
: "${POSTGRES_DB:?POSTGRES_DB is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"

STAMP=$(date -u +%Y%m%dT%H%M%SZ)
TARGET="$BACKUP_DIR/${POSTGRES_DB}-${STAMP}.dump"

TMP="$TARGET.partial"
trap 'rm -f "$TMP"' EXIT

# do not expose password to docker ps
export PGPASSWORD="$POSTGRES_PASSWORD"
pg_dump \
    --host="$POSTGRES_HOST" \
    --port="$POSTGRES_PORT" \
    --username="$POSTGRES_USER" \
    --dbname="$POSTGRES_DB" \
    --format=custom \
    --no-owner \
    --no-privileges \
    --file="$TMP"

# is it possible to restore it?
pg_restore --list "$TMP" > /dev/null

# if true, then copy it to the target destination, delete partial
install -D -m 644 "$TMP" "$TARGET"
rm "$TMP"
trap - EXIT

echo "backup done: $TARGET"
