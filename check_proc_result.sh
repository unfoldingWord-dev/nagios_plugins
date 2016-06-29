#!/bin/sh
#######################################################################
#
# NAME check_proc_result.sh  -  test result file contents for keywords
#
  USAGE="check_proc_result.sh [-wn] [-cn] <file> <prog> [arg]...
  Where 
    -w   = where n is integer number of failures before warning
    -c   = where n is integer number of failures befor critical
    file = file name that is owned by nagios
      it has 1 record of the form: errorcount:status[:stats]
      where 
        errorcount is number of sequencial fails
        status is one of: Fail, Success, Starting, Preparing, 
                          Progress, Multiple, Setup
        stats are optional space separated key=value pairs
      examples:
        0|Success|copies=10,deleted=5
        1|Fail killed
    prog = program and principal arguments to distinguish in ps
           example 's3cmd sync'
 "
# RETURN exit code and text line one of
#  0, OK - message
#  1, WARNING - message
#  2, CRITICAL - message 
#  3, UNKNOWN - message
#
# DESCRIPTION Programs that run periodically cannot be tested by ps.
#      These need to save exit status that nrpe can evaluate
#
# CONTRIBUTORS
#      Bruce Spidel bruce.spidel@gmail.com
#
#######################################################################

thresh() {
  th=${1:2}

  case "$th" in
    "~:"*|[0-9]:*) echo ${th:2} ;;
    [0-9][0-9]:*)  echo ${th:3} ;;
    *:)            echo ${th:0: -1} ;;
    *)             echo ${th} ;;
  esac
}

GREP=/bin/grep
PS=/usr/bin/ps

verb=
fle=
crit=3
warn=1

while [ $# -gt 0 ] ; do
  case $1 in
    -c*)          crit=$(thresh $1) ;; 
    -w*)          warn=$(thresh $1) ;; 
    -d|--debug)   bug=-d  ;; 
    -v|--verbose) verb=-v ;; 
    -p|--prog*)   shift ; prog="$*"          ; break  ;;
    -f|--file)    fle=$2                     ; shift  ;;
    -h|--help)    echo "Usage: $USAGE"       ; exit 0 ;;
    *)            fle=$1 ; shift ; prog="$*" ; break  ;;
  esac

  shift
done

if [ -z "$fle" ] ; then
    echo "UNKNOWN - Missing argument: file-to-test."
    exit 3
fi

if [ -z "$prog" ] ; then
  echo "UNKNOWN - Missing argument: program name."
  exit 3
fi
 
result=Empty

if [ -f $fle ] ; then
  IFS=':'
  read errorcount status stats < $fle
  unset IFS
  set x $status
  shift
  result=$1
  #read result dummy < $fle
else
  echo "UNKNOWN - file to test: [$fle] not found."
  exit 3
fi

case $result in
  Fail|Keyboard*)
    if [ $errorcount -gt $crit ] ; then
      echo "CRITICAL - Failed $errorcount times.|$stats"
      exit 2
    else
      if [ $errorcount -gt $warn ] ; then
        echo "WARNING - Failed $errorcount times.|$stats"
        exit 1
      fi
    fi

    echo "INFO - $result|$stats"
    exit 3
    ;;

  Success|Starting|Preparing)
    echo "OK - $result $stats|$stats"
    exit 0
    ;;
  
  Progress|Multiple)  
    $PS ax | $GREP -v grep | $GREP -v check_proc_result >/var/run/s3count
    count=$($PS ax | $GREP -v grep | $GREP -v check_proc_result | $GREP -c "$prog")
  
    case $count in
      0)
        echo "OK - Idle $stats|$stats"
        exit 0
        ;;

      1)
        echo "OK - $result $stats|$stats"
        exit 0
        ;;

      *)
        echo "WARNING - Collision $count instances running|$stats"
        exit 1
        ;;
    esac
    ;;
 
  Setup)
    echo "WARNING - Setup not complete."
    exit 1
    ;;
 
  *) echo "WARNING - Unexpected result [$result] from file: [$fle]"
    exit 1
    ;;
esac
 
