#!/bin/bash

S3ROOT="/var/www/troyandgay.com/s3/"

./list > $S3ROOT/index.xml
xmlstarlet sel -t -m "//bucket_list/bucket" -v name -n $S3ROOT/index.xml \
	| sed -e '/^\s*$/d' \
	| while read BUCKET; do

	# echo "Getting contents of $BUCKET";
	# ./list $BUCKET > $S3ROOT/$BUCKET.xml
	
	NUMFILES=`xmlstarlet sel -t -v "count(//contents/key)"     $S3ROOT/$BUCKET.xml`
	SIZE=`xmlstarlet sel -t -v "sum(//contents/key/@size)" $S3ROOT/$BUCKET.xml`
	
	# echo "Before:$SIZE";
	SIZE=`echo "$SIZE / (1024*1024)" | sed -e 's/e[+-]\([0-9][0-9]*\)/*10^\1/g' | bc`;
	# echo "After:$SIZE";
	
	xmlstarlet ed -d "//bucket_list/bucket[name='$BUCKET']/@files" $S3ROOT/index.xml \
		| xmlstarlet ed -d "//bucket_list/bucket[name='$BUCKET']/@size" \
		| xmlstarlet ed -i "//bucket_list/bucket[name='$BUCKET']" -t attr -n files -v $NUMFILES \
		| xmlstarlet ed -i "//bucket_list/bucket[name='$BUCKET']" -t attr -n size -v $SIZE \
		> $S3ROOT/index.xml

done
