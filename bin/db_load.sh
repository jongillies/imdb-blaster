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

export LC_ALL='C' # Needed for sort to work properly with unicode

# Load the movies
#
echo "truncate table movies;" > $FILE_TEMP.sql
echo "load data local infile \"${FILE_TEMP}.movies.txt\" into table movies fields terminated by '\t' lines terminated by '\n' (sha1,movie_name,movie_type_id,year,epsiode_title,season_number,episode_number,country,language,length,mpaa_rating,mpaa_reason,plot,location);" >> $FILE_TEMP.sql


echo "Loading to MySQL..."

#$BIN_MYSQL --port=$DB_PORT --host=$DB_SERVER --user=root $DB_NAME < $FILE_TEMP.sql
$BIN_MYSQL --port=$DB_PORT --host=$DB_SERVER --user=$DB_USER --password=$DB_PASSWORD $DB_NAME < $FILE_TEMP.sql


exit

