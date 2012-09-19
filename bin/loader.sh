#!/bin/bash

function usage ()
{
	echo
	echo "Usage: [-d] -D directory_with_list_files"
	echo
	exit 1
}

DEBUG=false
DEBUG_OPT=""
while getopts "dD:" opt; do
	case $opt in
		d)
			DEBUG=true
			DEBUG_OPT="-d"
			;;
		D)
			DIR=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			usage
			;;
	esac
done

if [ -z "$DIR" ]; then
	usage
fi

# Determine script path and load common variables
SCRIPT_PATH=$(dirname $(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}"))
. $SCRIPT_PATH/vars.sh


if [ $DEBUG == true ]; then
	FILE_TEMP=./data/
else
	FILE_TEMP=/private/tmp/$(basename $0).$RANDOM.$$.
fi

if [ ! -e "$DIR/movies.list.gz" ]; then
	echo "FATAL:  Can't locate $DIR/movies.list.gz"
	exit 1
fi

export LC_ALL='C' # Needed for sort to work properly with unicode

if [ -e $DIR/movies.list.gz ]; then
	echo "Decompressing $DIR/movies.list.gz..."
	$BIN_GUNZIP -f < $DIR/movies.list.gz > $DIR/movies.list
fi

echo "Extracting movies from $DIR/movies.list..."

$SCRIPT_PATH/movies.list.rb -c -f $DIR/movies.list 1>&1 | $BIN_SORT > ${FILE_TEMP}movies.list.txt
ERROR=$?
if [ $ERROR != 0 ]; then
	msg="ERROR running movies.list.rb -f"
	$BIN_EMAIL -t "$EMAIL_TO" -f "$USER@$FQDN" -s "$msg" -T "$msg"
	exit 1
fi

ORIG_COUNT=`$BIN_WC -l ${FILE_TEMP}movies.list.txt | $BIN_AWK '{ print $1 }'`

echo "Original: $ORIG_COUNT"
echo


OTHER_FILES="actors.list actresses.list countries.list directors.list genres.list language.list locations.list mpaa-ratings-reasons.list plot.list release-dates.list running-times.list"
for file in $OTHER_FILES
do
	if [ -e $DIR/$file.gz ]; then
		echo "Decompressing $DIR/$file.gz..."
		$BIN_GUNZIP -f < $DIR/$file.gz > $DIR/$file
	fi

	echo "Extracting data from $DIR/$file..."
	$SCRIPT_PATH/list_cleaner.rb -c -f $DIR/$file 1>&1 | $BIN_SORT > ${FILE_TEMP}$file.txt
	ERROR=$?
	if [ $ERROR != 0 ]; then
		msg="ERROR running list_cleaner.rb -f $DIR/$file"
		$BIN_EMAIL -t "$EMAIL_TO" -f "$USER@$FQDN" -s "$msg" -T "$msg"
		exit 1
	fi
	
	ORIG_COUNT=`$BIN_WC -l ${FILE_TEMP}$file.txt | $BIN_AWK '{ print $1 }'`

	echo "Original: $ORIG_COUNT"
	echo

done

