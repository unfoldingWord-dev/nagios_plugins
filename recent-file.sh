#!/bin/bash
#
#  Copyright (c) 2014 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Jeff Petitt <jcpetitt1@gmail.com>

# https://github.com/unfoldingWord-dev/sysadmin/issues/23

########################################
### functions...  usage, etc.
########################################
usage() {
        echo "
        Checks the directory passed in on the cli to see if files have changed in the amount of time specified. 

        USAGE: 
                e.g. `basename $0` -d /tmp -t 3

                -d      specific directory to search (required)
                -t      specific number of days to report (required)

        "
        exit 1
}

ok() {
    echo "Recent changes were found in $dir"
    exit 0
}

notok() {
    echo "NO Recent changes were found in $dir"
    exit 2
}

########################################
### validate options/arguments
########################################
while getopts d:t: flag   # the colon after the option means it requires an argument
do
        case $flag in
                d) dir=$OPTARG ;;
                t) days=$OPTARG ;;
                *) usage  ;;
        esac
done 

test "$dir"  || usage
test "$days" || usage

########################################
### process arguments and output
########################################
find $dir -mtime -$days -type f -ls  >$0.$$.out 2>$0.$$.err 

trap "rm -f $0.$$.*" EXIT HUP INT QUIT TERM

test -s $0.$$.err && 
{
        cat $0.$$.err 
        exit 99 
}

test -s $0.$$.out && ok
test -s $0.$$.out || notok

