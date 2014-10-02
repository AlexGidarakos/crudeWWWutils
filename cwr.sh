#!/bin/bash
# Name: cwr.sh - part of the crudeWWWutils suite
# GitHub: https://github.com/AlexGidarakos/crudeWWWutils
# Author: Alexandros Gidarakos - linkedin.com/in/alexandrosgidarakos
#
# Description:
# This is a crude bash script to perform a full (both files and database)
# on-demand restore of your website. It can be used in conjuction with the
# cwb.sh script and it is useful when you want to restore a snapshot of your
# website previously taken with cwb.sh. The script accepts 3 required
# arguments: a target directory which will be emptied first and then the
# website files will be extracted inside, the name of a preexisting MySQL
# database that will be emptied first and then recreated from the DB backup and
# finally, a prefix for a pair of backup files (one for the website files and
# one for the DB) from which the restore will be performed. When starting up,
# the script will also ask the user for proper MySQL credentials.
#
# Compatibility:
# The script has been developed and tested on VPSes running Debian Wheezy x86
# and x86_64, nginx, and MariaDB as a MySQL replacement. It also assumes that
# it will be running under an account with write permissions for the target
# directory and that the MySQL credentials provided will have CREATE TABLE
# permissions for the database in question.
#
# Requirements:
# The script needs the xz-utils package installed, since it uses the xz format,
# the new de-facto standard for maximum compression efficiency in Linux.
#
# General syntax:
#     ./cwr.sh TARGET_DIRECTORY DBNAME BACKUP_PREFIX
#
# Example syntax:
#     ./cwr.sh /mysite/public_html/ mysitedb /mysite/backup/20141001-1538
# This will expect to locate two existing files to restore from:
#     /mysite/backup/20141001-1538-db.sql.gz
#     /mysite/backup/20141001-1538-files.tar.xz

# Include common functions
source cwf.sh

# Check help argument
if [[ $1 == --help || $1 == -h ]]; then
    cwrSyntax
    exit 0
fi

# Check arguments number
if [[ $# -lt 3 ]]; then
    cwrSyntax
    exit 9
fi

# Check if target directory exists
checkDirExist $1

# Check if a backup file pair exists
checkBackupPair $3

# Check if a MySQL server is running
if mysqlNotAlive; then
    echo "Error: Could not detect a MySQL server running! Aborting..."
    exit 10
fi

# Check if web or PHP servers are running
if wwwAlive || phpAlive; then
    webPhpWarning
fi

# Ask for and check MySQL credentials
getDbCredentials

# Check database existence
checkDbExist $2

# Drop all tables in target database
emptyDb $2

# Recursively delete all contents of target directory
emptyDir $1

# Restore website database
restoreDb $2 $3

# Restore website files
restoreFiles $1 $3

# Done!
echo "Done!"
exit 0
