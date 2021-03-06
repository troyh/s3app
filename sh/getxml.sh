#!/bin/bash

S3ROOT=".."
SHDIR="$S3ROOT/sh"
XMLDIR="$S3ROOT/xml"
TMPDIR="$S3ROOT/tmp"
CGIBINDIR="$S3ROOT/cgi-bin"


function processbucket () {
	BUCKET=$1;
	
	# Rotate previous XML file(s)
	find $XMLDIR/ -type f -regex "$XMLDIR/$BUCKET.xml\.[0-9]+" | sed -e 's/^.*\.\([0-9][0-9]*\)$/\1/' \
		| sort -r -n \
		| while read N; do

		if [ $N -ge 6 ]; then
			rm -f $XMLDIR/$BUCKET.xml.$N;
		else
			mv $XMLDIR/$BUCKET.xml.$N $XMLDIR/$BUCKET.xml.$((N+1))
		fi
		
	done
	# Finally, rotate the existing XML file
	if [ -f $XMLDIR/$BUCKET.xml ]; then
		cp $XMLDIR/$BUCKET.xml $XMLDIR/$BUCKET.xml.0
	fi

	# Get new one
	if [ -z $CRON_RUNNING ]; then echo "Getting contents of $BUCKET"; fi
	s3 lsxml $BUCKET > $XMLDIR/$BUCKET.xml
	
	NUMFILES=`xmlstarlet sel -t -v "count(//contents/key)" $XMLDIR/$BUCKET.xml`
	SIZE=`xmlstarlet sel -t -v "sum(//contents/key/@size)" $XMLDIR/$BUCKET.xml`
	
	# echo "Before:$SIZE";
	SIZE=`echo "$SIZE / (1024*1024)" | sed -e 's/e[+-]\([0-9][0-9]*\)/*10^\1/g' | bc`;
	# echo "After:$SIZE";
	
	xmlstarlet ed -d "//bucket_list/bucket[name='$BUCKET']/@files" $S3ROOT/index.xml \
		| xmlstarlet ed -d "//bucket_list/bucket[name='$BUCKET']/@size" \
		| xmlstarlet ed -i "//bucket_list/bucket[name='$BUCKET']" -t attr -n files -v $NUMFILES \
		| xmlstarlet ed -i "//bucket_list/bucket[name='$BUCKET']" -t attr -n size -v $SIZE \
		> $S3ROOT/index.xml.new

	if [ -s $S3ROOT/index.xml.new ]; then 
		mv $S3ROOT/index.xml.new $S3ROOT/index.xml; 
	fi

}


if [ ! -z "$1" ]; then
	processbucket "$1";
else

	$CGIBINDIR/list > $S3ROOT/index.xml

	xmlstarlet sel -t -m "//bucket_list/bucket" -v name -n $S3ROOT/index.xml \
		| sed -e '/^\s*$/d' \
		| while read BUCKET; do
	
		processbucket $BUCKET;
	
	done

	./combine_changelogs.sh

fi
