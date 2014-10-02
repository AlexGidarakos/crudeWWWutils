#!/bin/bash
# Name: cwf.sh - part of the crudeWWWutils suite
# GitHub: https://github.com/AlexGidarakos/crudeWWWutils
# Author: Alexandros Gidarakos - linkedin.com/in/alexandrosgidarakos
#
# Description:
# This script contains some common functions used by the other scripts that
# make up the crudeWWWutils suite.

# Function cwcSyntax: Prints the correct syntax for the cwc.sh script
function cwcSyntax() {
    echo -e "\n\tcwc.sh syntax is:\n\n\t./cwc.sh PATH_TO_WEBSITE DBNAME\n"
}

# Function checkDirExist: Checks for specified directory existence
function checkDirExist() {
    if [[ ! -d $1 ]]; then
        echo -e "Error: Specified directory $1 doesn't exist! Aborting..."
        exit 1
    fi
}

# Function mysqlNotAlive: Returns 0 if a MySQL service is not found running
function mysqlNotAlive() {
    for pidFile in $(ls /var/run/mysqld/); do
        if [[ $pidFile == *mysql* ]]; then
            return 1
        fi
    done

    return 0
}

# Function wwwAlive: Returns 0 if a known web server is found running
function wwwAlive() {
    WWWLIST=(nginx apache httpd lighttpd)

    for pidFile in $(ls /var/run/); do
        for i in "${WWWLIST[@]}"; do
            if [[ $pidFile == *$i* ]]; then
                return 0
            fi
        done
    done

    return 1
}

# Function phpAlive: Returns 0 if a PHP service is found running
function phpAlive() {
    for pidFile in $(ls /var/run/); do
        if [[ $pidFile == *php* ]]; then
            return 0
        fi
    done

    return 1
}

# Function askAbort: Asks and aborts depending on user reply
function askAbort() {
    read -p "Abort? (Y/n): " reply

    if [[ $reply == y || $reply == Y || $reply == "" ]]; then
        echo "Aborting..."
        exit $1
    fi
}

# Function webPhpWarning: Displays WWW/PHP warning message and offers to abort
function webPhpWarning() {
    echo "Warning: Running Web server or PHP service detected!"
    echo "For data integrity purposes, it is recommended to always stop these"\
        "kinds of services before using this script."
    askAbort 2
}

# Function getDbCredentials: Asks for and checks MySQL user name and password
function getDbCredentials() {
    read -p "Please enter MySQL username: " DBUSER
    read -s -p "Please enter password for MySQL user $DBUSER: " DBPASS
    echo
    mysqladmin -u "$DBUSER" -p"$DBPASS" ping 2> /dev/null | grep alive &> \
        /dev/null

    if [[ $? -ne 0 ]]; then
        echo "Error: Wrong MySQL username or password! Aborting..."
        exit 3
    fi
}

# Function checkDbExist: Checks database existence
function checkDbExist() {
    mysql -u "$DBUSER" -p"$DBPASS" -e "USE $1" &> /dev/null

    if [[ $? -ne 0 ]]; then
        echo "Error: Specified database $1 doesn't exist! Aborting..."
        exit 4
    fi
}

# Function askProceed: Asks and proceeds depending on user reply
function askProceed() {
    read -p "Proceed? (Y/n): " REPLY

    if [[ $REPLY != y && $REPLY != Y && $REPLY != "" ]]; then
        echo "Aborting..."
        exit $1
    fi
}

# Function emptyDir: Tries to recursively empty all target directory content
function emptyDir() {
    echo "Warning: Directory $1 will be emptied of all content!"
    askProceed 5
    echo "Deleting all contents of directory $1, please wait..."
    rm -rf $1/*

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while emptying directory $1!"
        askAbort 6
    fi
}

# Function emptyDb: Tries to drop all tables from target database
function emptyDb() {
    echo "Warning: All tables in database $1 will be dropped!"
    askProceed 7
    echo "Dropping all tables in database $1, please wait..."
    mysql -u "$DBUSER" -p"$DBPASS" -Nse "SHOW TABLES" $1 | while read TABLE; do
        mysql -u "$DBUSER" -p"$DBPASS" -e "DROP TABLE $TABLE" $1
    done

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while emptying database $1!"
        askAbort 8
    fi
}
