#!/bin/bash
cd /var/www/mywebapp || exit 1

export HOME=/tmp

export DATABASE_URL="mysql://vlad:qwerty@localhost:3306/inventory_db"

echo "Starting database migration..."

if ./node_modules/.bin/prisma migrate deploy; then
    echo "Migration completed successfully"
    exit 0
else
    echo "Migration failed"
    exit 1
fi