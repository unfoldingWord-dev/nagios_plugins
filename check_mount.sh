#!/usr/bin/env sh
# -*- coding: utf8 -*-
#
#  Copyright (c) 2014 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Jesse Griffin <jesse@distantshores.org>

help() {
    echo
    echo "Verifies that given mount exists.  Optionally, verifies that given"
    echo "directory exists on mount (relative to mount path)."
    echo
    echo "Usage:"
    echo "   $PROGNAME -m <mountpath> [-d <directory>]"
    echo "   $PROGNAME --help"
    echo
    exit 1
}

if [ $# -lt 1 ]; then
    help
fi
while test -n "$1"; do
    case "$1" in
        --help|-h)
            help
            ;;
        --mount|-m)
            MNT="$2"
            shift
            ;;
        --dir|-d)
            DIR="$2"
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            help
            ;;
    esac
    shift
done

crit() {
    echo "CRITICAL: $1"
    exit 2
}

ok() {
    echo "OK"
    exit 0
}

[ -z "$MNT" ] && help

# Exit Critical if mount not found
mount | grep -q " $MNT "  || crit "$MNT not mounted"

# Exit OK if we don't need to do a directory check
[ -z "$DIR" ] && ok

# Exit OK if $DIR exists on $MNT
[ -d "$MNT/$DIR" ] && ok

# Exit critical since directory was not found
crit "$MNT/$DIR not found"
