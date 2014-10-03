#!/bin/bash
# Name: cwb.sh - part of the crudeWWWutils suite
# GitHub: https://github.com/AlexGidarakos/crudeWWWutils
# Author: Alexandros Gidarakos - linkedin.com/in/alexandrosgidarakos
#
# Description:
# This is a crude bash script to perform a full (both files and database)
# on-demand backup of your website. It can be used in conjuction with the
# cwc.sh script and it is useful either for normal backup or when you want to
# take a snapshot of your website before making some big changes. The script
# accepts 3 required arguments: the path to your website files, the name of the
# MySQL database that holds the website's data and a prefix for the two
# resulting backup files. It also accepts an optional --ps argument that
# activates an exclusion list for known temporary files in PrestaShop 1.6.x.
# and an optional -0...9 argument that selects a compression level (default is
# -3). The script will interactively ask the user for proper MySQL credentials.
#
# Compatibility:
# The script has been developed and tested on VPSes running Debian Wheezy x86
# and x86_64, nginx, and MariaDB as a MySQL replacement. It also assumes that
# it will be running under an account with read permissions for the website
# files and that the MySQL credentials provided will have read permissions for
# the database in question.
#
# Requirements:
# The script needs the xz-utils package installed, since it uses the xz format,
# the new de-facto standard for maximum compression efficiency in Linux.
#
# General syntax:
#     ./cwb.sh PATH_TO_WEBSITE DBNAME BACKUP_PREFIX [--ps] [-0...9]
#
# Example syntax:
#     ./cwb.sh /mysite/public_html/ mysitedb /mysite/backup/20141001-1538
# This will create two files:
#     /mysite/backup/20141001-1538-files.tar.xz
#     /mysite/backup/20141001-1538-db.sql.gz

# Include common functions
source cwf.sh

# Check help argument
if [[ $1 == --help || $1 == -h ]]; then
    cwbSyntax
    exit 0
fi

# Check arguments number
if [[ $# -lt 3 ]]; then
    cwbSyntax
    exit 9
fi

# Check if source directory exists
checkDirExist $1

# Create PrestaShop exclusion list if necessary
XLIST="/tmp/$(basename $0).$RANDOM.txt"
touch $XLIST
if [[ $4 == "--ps" ]]; then
    echo "./cache/cachefs/*" >> $XLIST
    echo "./cache/smarty/cache/*" >> $XLIST
    echo "./cache/smarty/compile/*" >> $XLIST
    echo "./cache/purifier/*" >> $XLIST
    echo "./img/tmp/*" >> $XLIST
fi

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

# Backup website database
backupDb $2 $3

# Backup website files
backupFiles $1 $3 $5

# Done!
echo "Done!"
exit 0
