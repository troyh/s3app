#!/bin/bash

# . /etc/webapps/s3/config.sh

S3ROOT="/var/www/troyandgay.com/s3/"
XMLDIR="$S3ROOT/xml"
TMPDIR="$S3ROOT/tmp"
CGIBINDIR="$S3ROOT/cgi-bin"

BUCKET=$1

CURR="";

find ../xml/ -name "$BUCKET.xml.*" \
	| sed -e 's/.*\([0-9][0-9]*\)$/\1/' \
	| sort -n \
	| while read N; do
	
	if [ -s $XMLDIR/$BUCKET.xml.$N ]; then

		# # For debugging, randomly delete 10 keys from the backup
		# TOTAL=`xmlstarlet sel -t -v "count(//contents/key)" $XMLDIR/$BUCKET.xml.0`;
		# cat $XMLDIR/$BUCKET.xml.0 \
		# 	| xmlstarlet ed -d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 					-u "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]/@size" -v "`perl -e 'print int(rand()*100000);'`" \
		# 	> $XMLDIR/$BUCKET.xml.new
		# mv $XMLDIR/$BUCKET.xml.new $XMLDIR/$BUCKET.xml.0
		# 
		# cat $XMLDIR/$BUCKET.xml \
		# 	| xmlstarlet ed -d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 					-d "//contents/key[`perl -e 'print int(rand()*1000)+1;'`]" \
		# 	> $XMLDIR/$BUCKET.xml.new
		# mv $XMLDIR/$BUCKET.xml.new $XMLDIR/$BUCKET.xml

		# Compare latest XML file to previous one
		cat $XMLDIR/$BUCKET.xml.$N \
			| xmlstarlet sel -t -m "//contents/key" -v name -o '&#09;' -v @size -o '&#09;' -v @eTag -o '&#09;' -v @lastmodified -n > $TMPDIR/$BUCKET.a
		
		cat $XMLDIR/$BUCKET.xml$CURR \
			| xmlstarlet sel -t -m "//contents/key" -v name -o '&#09;' -v @size -o '&#09;' -v @eTag -o '&#09;' -v @lastmodified -n > $TMPDIR/$BUCKET.b
			
		diff -u $TMPDIR/$BUCKET.a $TMPDIR/$BUCKET.b | egrep -v "^[+-]{3,3}"| egrep "^[+-]" | cut -f 1 | egrep "^\+" | sed -e 's/^+//' > $TMPDIR/$BUCKET.adds
		diff -u $TMPDIR/$BUCKET.a $TMPDIR/$BUCKET.b | egrep -v "^[+-]{3,3}"| egrep "^[+-]" | cut -f 1 | egrep "^\-" | sed -e 's/^-//' > $TMPDIR/$BUCKET.dels
		
		DATETIME=`xmlstarlet sel -t -v "//meta/doctime" $XMLDIR/$BUCKET.xml`;
			
		diff -u $TMPDIR/$BUCKET.dels $TMPDIR/$BUCKET.adds | egrep -v "^[+-]{3,3}" | egrep "^-"  | sed -e 's/^-//' -e "s/^/<key change=\"deleted\" datetime=\"$DATETIME\">/" -e 's/$/<\/key>/' # > $TMPDIR/$BUCKET.DEL.xml
		diff -u $TMPDIR/$BUCKET.dels $TMPDIR/$BUCKET.adds | egrep -v "^[+-]{3,3}" | egrep "^\+" | sed -e 's/^+//' -e "s/^/<key change=\"added\"   datetime=\"$DATETIME\">/" -e 's/$/<\/key>/' # > $TMPDIR/$BUCKET.ADD.xml
		diff -u $TMPDIR/$BUCKET.dels $TMPDIR/$BUCKET.adds | egrep "^ "                          | sed -e 's/^ //' -e "s/^/<key change=\"updated\" datetime=\"$DATETIME\">/" -e 's/$/<\/key>/' # > $TMPDIR/$BUCKET.MOD.xml
			
		# cat $TMPDIR/$BUCKET.DEL.xml $TMPDIR/$BUCKET.ADD.xml $TMPDIR/$BUCKET.MOD.xml
			
		rm -f $TMPDIR/$BUCKET.a $TMPDIR/$BUCKET.b $TMPDIR/$BUCKET.adds $TMPDIR/$BUCKET.dels;
		
		CURR=".$N";

	fi

done;
