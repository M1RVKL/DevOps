#!/bin/bash
cd /opt/mywebapp || exit 1

export HOME=/tmp

echo "Starting database migration..."

if ./node_modules/.bin/prisma migrate deploy; then
    echo "Migration completed successfully"
    exit 0
else
    echo "Migration failed"
    exit 1
fi