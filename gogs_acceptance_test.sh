#!/usr/bin/env bash
# -*- coding: utf8 -*-
#
#  Copyright (c) 2017 unfoldingWord
#  http://creativecommons.org/licenses/MIT/
#  See LICENSE file for details.
#
#  Contributors:
#  Jesse Griffin <jesse@unfoldingword.org>

# Temp and log location
TMPDIR=/tmp/gogs_test
LOGFILE=/tmp/gogs_acceptance_test.log

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
    echo "    -H       Host to run against, default is localhost:3000"
    echo "    -t       Token for testing API"
    echo "    -p       Password for acceptance_test user"
    echo "    -h       Displays this messsage"
}

while test $# -gt 0; do
    case "$1" in
        -H|--hostname) shift; HOST=$1;;
        -t|--token) shift; TOKEN=$1;;
        -p|--pass) shift; PASS=":$1";;
        -h|--help) help && exit 1;;
    esac
    shift;
done

# Setup variable defaults in case flags were not set
: ${HOST='localhost:3000'}
: ${TOKEN=false}
: ${PASS=""}

echo -n "Testing $HOST"

# Put all output into log
exec >$LOGFILE 2>&1

# Show commands being executed and exit upon any error
set -xe

# Test for Google Analytics ID
wget -q -O - https://$HOST \
  | grep -q "UA-6010"

# API Tests
# Create a repo
wget -q -O - \
  --header="Authorization: token $TOKEN" \
  https://$HOST/api/v1/user/repos \
  | grep -q "acceptance_test/api_test"

# Get list of repos for user
wget -q -O - \
  --header="Authorization: token $TOKEN" \
  https://$HOST/api/v1/user/repos \
  | grep -q "username"

# Get repo we just created
wget -q -O - \
  --header="Authorization: token $TOKEN" \
  https://$HOST/api/v1/repos/acceptance_test/api_test \
  | grep -q "watchers_count"

# Get list of all repos
wget -q -O - \
  https://$HOST/api/v1/repos/search \
  | grep -q watchers_count

# Delete repo we created
curl -X DELETE -H "Authorization: token $TOKEN" \
  https://$HOST/api/v1/repos/acceptance_test/api_test

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
echo "OK"
