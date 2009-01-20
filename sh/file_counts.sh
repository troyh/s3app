#!/bin/bash

BUCKET="$1";
FILEPATH="$2";
DIRNAME="$3";

S3ROOT=".."
BUCKETS_DIR="$S3ROOT/buckets"
XMLDIR="$S3ROOT/xml"
XML_FILE="$S3ROOT/buckets/$BUCKET/${DIRNAME}index.xml";

let ITER=1

if [ ! -s "$XML_FILE" ]; then
	echo "Empty XML file: $XML_FILE";
	exit;
fi

cat "$XML_FILE" \
	| xmlstarlet sel -t -m "//dir/name" -v . -n \
	| sed -e '/^\s*$/d' \
	| while read FOO; do

	# FILEPATH=`echo "$FILEPATH" | perl -MHTML::Entities -ne 'print encode_entities($_);'`;
	FOO=`echo "$FOO" | perl -MHTML::Entities -ne 'print encode_entities($_);' | sed -e 's/&igrave;/\&#236;/gi'`;

	NUMFILES=`xmlstarlet sel -t -v "count(//contents/key[starts-with(name,&quot;$FILEPATH$FOO&quot;)])" $XMLDIR/$BUCKET.xml`
	SIZE=`xmlstarlet sel -t -v "sum(//contents/key[starts-with(name,&quot;$FILEPATH$FOO&quot;)]/@size)" $XMLDIR/$BUCKET.xml`

	SIZE=`echo "$SIZE" | sed -e 's/e[+-]\([0-9][0-9]*\)/*10^\1/g' | bc`;
	
	# echo "$FILEPATH$FOO @files=$NUMFILES @size=$SIZE";

	# Update the @files and @size in the XML file
	cat "$XML_FILE" \
		| xmlstarlet ed -d "//dir[$ITER]/@files" \
		| xmlstarlet ed -d "//dir[$ITER]/@size" \
		| xmlstarlet ed -i "//dir[$ITER]" -t attr -n files -v $NUMFILES \
		| xmlstarlet ed -i "//dir[$ITER]" -t attr -n size -v $SIZE \
		> "$XML_FILE"
	
	let ITER=$((ITER+1));

done
