#!/bin/bash
systemctl stop mariadb
rm -f /var/lib/mysql/aria_log_control
rm -f /run/mysqld/mysqld.pid
rm -f /var/lib/mysql/mysql.sock
chown -R mysql:mysql /var/lib/mysql /var/run/mysqld
chmod -R 0755 /var/lib/mysql /var/run/mysqld
mysqld_safe --skip-grant-tables --skip-networking &
sleep 10
mysqlcheck -A --repair --use-frm
kill $(cat /var/run/mysqld/mysqld.pid)
sleep 5
systemctl start mariadb
