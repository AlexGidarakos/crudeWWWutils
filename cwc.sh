#!/bin/bash
# Name: cwc.sh - part of the crudeWWWutils suite
# GitHub: https://github.com/AlexGidarakos/crudeWWWutils
# Author: Alexandros Gidarakos - linkedin.com/in/alexandrosgidarakos
#
# Description:
# This is a crude bash script to perform a full cleanup of your website files
# and database. I use it when I want a quick cleanup to start over. The script
# accepts 2 arguments: the path to your website files and the name of the MySQL
# database that is used by the website. When starting up, it also asks the user
# to input proper MySQL credentials.
#
# Compatibility:
# The script has been developed and tested on VPSes running Debian Wheezy x86
# and x86_64, nginx, and MariaDB as a MySQL replacement. It also assumes that
# it will be running under an account with write permissions for the website
# files and that the MySQL credentials provided will have DROP TABLE permission
# for the database in question.
#
# General syntax:
# ./cwc.sh PATH_TO_WEBSITE DBNAME
#
# Example syntax:
# ./cwc.sh /mysite/public_html mysitedb

# Include common functions
source cwf.sh

# Check help argument
if [[ $1 == --help || $1 == -h ]]; then
    cwcSyntax
    exit 0
fi

# Check arguments number
if [[ $# -lt 2 ]]; then
    cwcSyntax
    exit 9
fi

# Check if target directory exists
checkDirExist $1

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

# Recursively delete all contents of target directory
emptyDir $1

# Drop all tables in target database
emptyDb $2

# Done!
echo "Done!"
exit 0
