#!/bin/bash
# Name: cwf.sh - part of the crudeWWWutils suite
# GitHub: https://github.com/AlexGidarakos/crudeWWWutils
# Author: Alexandros Gidarakos - linkedin.com/in/alexandrosgidarakos
#
# Description:
# This script contains some common functions used by the other scripts that
# make up the crudeWWWutils suite.

# Function cwcSyntax: prints the correct syntax for the cwc.sh script
function cwcSyntax() {
    echo -e "Error: wrong syntax!\nThe correct syntax is:"\
        "\n\t./cwc.sh PATH_TO_WEBSITE DBNAME"
}

# Function dirNotExist: returns 0 if directory passed as argument doesn't exist
function dirNotExist() {
    if [[ -n $1 && -d $1 ]]; then
        return 1
    fi

    return 0
}

# Function wwwAlive: returns 0 if a known web server is found running
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

# Function phpAlive: returns 0 if a PHP service is found running
function phpAlive() {
    for pidFile in $(ls /var/run/); do
        if [[ $pidFile == *php* ]]; then
            return 0
        fi
    done

    return 1
}

# Function mysqlNotAlive: returns 0 if a MySQL service is not found running
function mysqlNotAlive() {
    for pidFile in $(ls /var/run/mysqld.); do
        if [[ $pidFile == *mysql* ]]; then
            return 1
        fi
    done

    return 0
}
