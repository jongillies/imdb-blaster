#!/bin/bash

#<COMMENT>
#
# # Determine script path and load common variables
# SCRIPT_PATH=$(dirname $(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}"))
# . $SCRIPT_PATH/vars.sh
#
# STATUS: utility
# USED: cron-jobs
#</COMMENT>

# Normally the SCRIPT_PATH is set by the parent, but if not set it here
if [ -z "$SCRIPT_PATH" ]; then
	# Determine script path and load common variables
	SCRIPT_PATH=$(dirname $(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}"))
fi

ABSPATH="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
TOOLS_PATH=$SCRIPT_PATH/../../tools/bin

if [[ "$OSTYPE" == "cygwin" ]]; then
	FQDN=`ipconfig /all | grep "Primary Dns Suffix" | sed 's/^.*: //'`
	HOSTNMAE=`hostname`
	FQDN=`echo $HOSTNAME.$FQDN`
	USER=$USERNAME
else
	HOSTNAME=`hostname -s`
	FQDN=`hostname -f`
fi

CONFIG_FILE=$SCRIPT_PATH/config-$HOSTNAME.sh

#
# External scripts/binaries
#
BIN_EMAIL="/usr/local/site/bin/email.rb"
BIN_MV=/bin/mv
BIN_SH=/bin/sh
BIN_RM=/bin/rm
BIN_MKDIR=/bin/mkdir
BIN_RMDIR=/bin/rmdir
BIN_FIND=/usr/bin/find
BIN_AWK='/bin/awk'
BIN_MYSQL='/usr/bin/mysql'
BIN_WC='/usr/bin/wc'
BIN_GREP='/bin/grep'
BIN_NC='/usr/bin/nc'
BIN_LS='/bin/ls'
BIN_DOS2UNIX='/usr/bin/dos2unix'
BIN_PGREP='/usr/local/bin/pgrep.py'
BIN_SED='/bin/sed'
BIN_BASENAME='/bin/basename'
BIN_SORT='/bin/sort'
BIN_TAIL='/usr/bin/tail'
BIN_CAT='/bin/cat'
BIN_HEAD='/usr/bin/head'
BIN_GUNZIP='/usr/bin/gunzip'

#
# Parse out the second word of $0 to get the object type
#
OLD_IFS="$IFS"
IFS="_"
bar=( $0 )
IFS="$OLD_IFS"
OBJECT_TYPE=${bar[1]}

#
# Time/date stamp variables
#
TIME_STAMP=`/bin/date +%Y%m%d%H%M%S`
DATE_STAMP=`/bin/date +%Y%m%d`

# Email to list, just in case
EMAIL_TO="deltad@apollogrp.edu"

# Load the config file if it exists
if [ -e $CONFIG_FILE ]; then
	. $CONFIG_FILE
fi

#
# Get The Needed Configuration Variable(s) or set Defaults for Development Environment
#
if [ -z "$DISCOVERY_FOLDER" ]; then
	DISCOVERY_FOLDER="../../archive/discovery"
fi

#
# Get database parameters from config/database.yml for the RAILS_ENV
#
DB_NAME=`$SCRIPT_PATH/db_get.rb -k database`
DB_SERVER=`$SCRIPT_PATH/db_get.rb -k host`
DB_USER=`$SCRIPT_PATH/db_get.rb -k username`
DB_PASSWORD=`$SCRIPT_PATH/db_get.rb -k password`
DB_PORT=`$SCRIPT_PATH/db_get.rb -k port`

#
# Functions
#

MAX_JOBS=30

function run_job ()
{
	echo "Running Process $1 1> $2 2> $3"
	$1 1> $2 2> $3
	ERROR=$?
	if [ $ERROR != 0 ]; then
		msg="CRITICAL: (Error: $ERROR) Unable to run $1"
		$BIN_EMAIL -t "$EMAIL_TO" -f "$USER@$FQDN" -s "$msg" -T "$msg" -a "$2,$3"
	fi

}
