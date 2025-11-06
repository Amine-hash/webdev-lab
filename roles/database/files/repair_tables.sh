#!/bin/bash

# Stop MariaDB
systemctl stop mariadb

# Clean up any remaining files
rm -f /var/lib/mysql/aria_log_control
rm -f /run/mysqld/mysqld.pid
rm -f /var/lib/mysql/mysql.sock

# Fix permissions
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
chmod -R 0755 /var/lib/mysql /var/run/mysqld

# Start MariaDB in safe mode
mysqld_safe --skip-grant-tables --skip-networking &
sleep 10

# Repair tables
mysqlcheck -A --repair --use-frm

# Stop MariaDB safe mode
kill $(cat /var/run/mysqld/mysqld.pid)
sleep 5

# Restart normally
systemctl start mariadb
