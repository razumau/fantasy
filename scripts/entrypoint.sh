#!/bin/sh

litestream restore -o /data/sqlite.db /data/sqlite.db
echo "Restored database from backup"
npx prisma migrate deploy
litestream replicate
