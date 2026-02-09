#!/bin/bash
set -e

# Entrypoint script for Phoenix app with litestream
# 1. Restore database from S3 backup (if exists)
# 2. Run Ecto migrations
# 3. Start litestream replication (which execs Phoenix server)

echo "Starting entrypoint script..."

# Restore database from litestream backup if it exists in S3
# -if-replica-exists: only restore if a backup exists, otherwise start fresh
echo "Restoring database from litestream backup..."
litestream restore -if-replica-exists -if-db-not-exists -config /etc/litestream.yml /data/sqlite.db

# Run Ecto migrations
# The release includes a migrate script via rel/overlays
echo "Running database migrations..."
/app/bin/fantasy eval "Fantasy.Release.migrate()"

# Start litestream replication with Phoenix server
# Litestream will exec the command specified in litestream.yml
echo "Starting litestream replication and Phoenix server..."
exec litestream replicate -config /etc/litestream.yml
