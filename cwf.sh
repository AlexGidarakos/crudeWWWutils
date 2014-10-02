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

# Function dirExist: returns 0 if directory passed as argument exists
function dirExist() {
    if [[ -n $1 && -d $1 ]]; then
        return 0
    fi

    return 1
}

# Function dirNotExist: returns 0 if directory passed as argument doesn't exist
function dirNotExist() {
    if [[ -n $1 && -d $1 ]]; then
        return 1
    fi

    return 0
}
