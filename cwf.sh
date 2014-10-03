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

# Function timerStart: Starts a timer
function timerStart() {
    TIMESTART="$(date +%s)"
}

# Function timerStop: Stops the timer and stores result in seconds in $TIMER
function timerStop() {
    TIMESTOP="$(date +%s)"
    TIMER=$((TIMESTOP-TIMESTART))
}

# Function emptyDir: Tries to recursively empty all target directory content
function emptyDir() {
    echo "Warning: Directory $1 will be emptied of all content!"
    askProceed 5
    echo "Deleting all contents of directory $1, please wait..."
    timerStart
    rm -rf $1/*

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while emptying directory $1!"
        askAbort 6
    else
        timerStop
        echo "Directory $1 emptied in $TIMER sec"
    fi
}

# Function emptyDb: Tries to drop all tables from target database
function emptyDb() {
    echo "Warning: All tables in database $1 will be dropped!"
    askProceed 7
    echo "Dropping all tables in database $1, please wait..."
    timerStart
    mysql -u "$DBUSER" -p"$DBPASS" -Nse "SHOW TABLES" $1 | while read TABLE; do
        mysql -u "$DBUSER" -p"$DBPASS" -e "DROP TABLE $TABLE" $1
    done

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while emptying database $1!"
        askAbort 8
    else
        timerStop
        echo "Database $1 emptied in $TIMER sec"
    fi
}

# Function cwbSyntax: Prints the correct syntax for the cwb.sh script
function cwbSyntax() {
    echo -e "\n\tcwb.sh syntax is:\n"
    echo -e "\t./cwb.sh PATH_TO_WEBSITE DBNAME BACKUP_PREFIX [--ps] [-0...9]\n"
}

# Function backupDb: Tries to dump and compress target database
function backupDb() {
    echo "Dumping and compressing contents of database $1, please wait..."
    timerStart
    mysqldump -u "$DBUSER" -p"$DBPASS" $1 | gzip -8 > "$2"-db.sql.gz

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while dumping database $1!"
        askAbort 11
    else
        timerStop
        echo "Database $1 compressed to file $2-db.sql.gz in $TIMER sec"
        askProceed 12
    fi
}

# Function backupFiles: Tries to compress target directory contents
function backupFiles() {
    echo "Compressing contents of directory $1, please wait..."

    if [[ -n $3  ]]; then
        COMPLEVEL=$3
    else
        COMPLEVEL=-3
    fi

    timerStart
    XZ_OPT=$COMPLEVEL tar cvJpf "$2"-files.tar.xz -X $XLIST -C "$1" .

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while compressing contents of directory $1!"
        askAbort 13
    else
        timerStop
        echo "Directory $1 compressed to file $2-files.tar.xz in $TIMER sec"
    fi
}

# Function cwrSyntax: Prints the correct syntax for the cwr.sh script
function cwrSyntax() {
    echo -e "\n\tcwr.sh syntax is:"
    echo -e "\n\t./cwr.sh TARGET_DIRECTORY DBNAME BACKUP_PREFIX\n"
}

# Function checkBackupPair: Checks existence of backup file pair
function checkBackupPair() {
    if [[ ! -f $1-db.sql.gz || ! -f $1-files.tar.xz ]]; then
        echo "Error: could not locate a backup file pair."
        echo "Please make sure BOTH these two files exist:"
        echo -e "\n\t$1-db-sql.gz\n\t$1-files.tar.xz"
        echo "Aborting..."
        exit 14
    fi
}

# Function restoreDb: Tries to restore target database from backup
function restoreDb() {
    echo "Restoring contents of database $1, please wait..."
    timerStart
    gunzip -c $2-db.sql.gz | mysql -u "$DBUSER" -p"$DBPASS" $1

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while restoring database $1!"
        askAbort 15
    else
        timerStop
        echo "Database $1 restored from file $2-db.sql.gz in $TIMER sec"
        askProceed 16
    fi
}

# Function restoreFiles: Tries to extract website files in the target directory
function restoreFiles() {
    echo "Extracting website files in target directory $1, please wait..."
    timerStart
    tar xvpf $2-files.tar.xz -C $1

    if [[ $? -ne 0 ]]; then
        echo "Warning: Problem while extracting files in target directory $1!"
        askAbort 17
    else
        timerStop
        echo "Directory $1 restored from file $2-files.tar.xz in $TIMER sec"
    fi
}
