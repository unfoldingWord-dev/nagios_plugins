#!/usr/bin/env bash
# -*- coding: utf8 -*-
#
#  Copyright (c) 2017 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Jesse Griffin <jesse@unfoldingword.org>

# Temp directory
TMPDIR=/tmp/gogs_test

get_tmp() {
    # Setup temporary environment
    rm -rf "$TMPDIR"
    mkdir -p "$TMPDIR"
    cd "$TMPDIR"
}

help() {
    echo "Runs acceptance tests against our Door43 Content Service"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "    -h       Host to run against, default is localhost:3000"
    echo "    -t       Token for testing API"
    echo "    -p       Password for acceptance_test user"
    echo "    -?       Displays this messsage"
}

while test $# -gt 0; do
    case "$1" in
        -h|--host) shift; HOST=$1;;
        -t|--token) shift; TOKEN=$1;;
        -p|--pass) shift; PASS=":$1";;
        -?|--help) help && exit 1;;
    esac
    shift;
done

# Setup variable defaults in case flags were not set
: ${HOST='localhost:3000'}
: ${TOKEN=false}
: ${PASS=""}

echo
echo "Running against $HOST..."
echo

# Show commands being executed and exit upon any error
set -xe

# Create repo, add file, create tag, release, token?

# Test for Google Analytics ID
wget -q -O - https://$HOST \
  | grep -q "UA-6010"

# API Tests
# Get list of repos
wget -q -O - \
  https://$HOST/api/v1/repos/search \
  | grep -q watchers_count

# Get list of repos for user
wget -q -O - \
  --header="Authorization: token $TOKEN" \
  https://$HOST/api/v1/user/repos \
  | grep -q "test.git"

# Test download of code from repo
## zip ball
### master
get_tmp
wget -q https://$HOST/acceptance_test/test/archive/master.zip
unzip master.zip
[ -f test/README.md ]

### release
get_tmp
wget -q https://$HOST/acceptance_test/test/archive/v1.zip
unzip v1.zip
[ -f test/README.md ]

# tar ball
## master
get_tmp
wget -q https://$HOST/acceptance_test/test/archive/master.tar.gz
tar -xvzf master.tar.gz
[ -f test/README.md ]

### release
get_tmp
wget -q https://$HOST/acceptance_test/test/archive/v1.tar.gz
tar -xvzf v1.tar.gz
[ -f test/README.md ]

# Test repo clone-add-commit-push
# HTTPS
DATEFILE=`date +%Y-%m-%d-%H-%M-%S`
get_tmp
git clone https://acceptance_test$PASS@$HOST/acceptance_test/test.git
cd test
date > "$DATEFILE"
[ -f "$DATEFILE" ]
git add "$DATEFILE"
git commit "$DATEFILE" -m 'Adding HTTPS test file'
git push origin master
wget -q -O /dev/null https://$HOST/acceptance_test/test/raw/master/$DATEFILE
rm $DATEFILE
git commit "$DATEFILE" -m 'Removing HTTPS test file'
git push origin master

# SSH
DATEFILE=`date +%Y-%m-%d-%H-%M-%S`
get_tmp
git clone git@$HOST:acceptance_test/test.git
cd test
date > "$DATEFILE"
[ -f "$DATEFILE" ]
git add "$DATEFILE"
git commit "$DATEFILE" -m 'Adding SSH test file'
git push origin master
wget -q -O /dev/null https://$HOST/acceptance_test/test/raw/master/$DATEFILE
rm $DATEFILE
git commit "$DATEFILE" -m 'Removing SSH test file'
git push origin master

# Final cleanup
rm -rf "$TMPDIR"
