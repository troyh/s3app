#!/bin/bash

S3ROOT="/var/www/troyandgay.com/s3/"
XMLDIR="$S3ROOT/xml"
TMPDIR="$S3ROOT/tmp"
SHDIR="$S3ROOT/sh"
CGIBINDIR="$S3ROOT/cgi-bin"

rm -f $TMPDIR/new_changelogs

xmlstarlet sel -t -m "//bucket_list/bucket" -v name -n $S3ROOT/index.xml \
	| sed -e '/^\s*$/d' \
	| while read BUCKET; do

	# Create the ChangeLog
	$SHDIR/bucket_diff.sh "$BUCKET" > $TMPDIR/$BUCKET.changelog
	
	echo "<changelog>" > $XMLDIR/$BUCKET.changelog.xml
	if [ -s $TMPDIR/$BUCKET.changelog ]; then
		cat $TMPDIR/$BUCKET.changelog >> $XMLDIR/$BUCKET.changelog.xml
	fi
	echo "</changelog>" >> $XMLDIR/$BUCKET.changelog.xml
	
	rm -f $TMPDIR/$BUCKET.changelog

	xmlstarlet sel -t -m "//changelog" -e bucket -a name -o $BUCKET -b -c child::* $XMLDIR/$BUCKET.changelog.xml >> $TMPDIR/new_changelogs
	
done

if [ -s $S3ROOT/changelog.xml ]; then
	cat $S3ROOT/changelog.xml | xmlstarlet sel -t -m "//changelog" -c child::* > $TMPDIR/old_changelogs
fi

echo "<changelog>" > $TMPDIR/changelog;
if [ -s $TMPDIR/new_changelogs ]; then
	cat $TMPDIR/new_changelogs >> $TMPDIR/changelog;
fi
if [ -s $TMPDIR/old_changelogs ]; then
	cat $TMPDIR/old_changelogs >> $TMPDIR/changelog;
fi
echo "</changelog>" >> $TMPDIR/changelog;

cat $TMPDIR/changelog | xmlstarlet ed -d "//bucket[count(child::*)=0]" > $S3ROOT/changelog.xml

# Remove duplicates
cat $S3ROOT/changelog.xml \
	| xmlstarlet sel -t -m "//changelog/bucket" -v @name -o '&#09;' -v key -o '&#09;' -v key/@datetime -o '&#09;' -v key/@change -n \
	| sed -e '/^\s*$/d' \
	| sort \
	| uniq -c \
	| sed -e '/^  *1  */d' \
	| sed -e 's/^ *[0-9][0-9]*  *//' \
	| while read LN; do

		B=`echo "$LN" | cut -f 1`;
		K=`echo "$LN" | cut -f 2`;
		T=`echo "$LN" | cut -f 3`;
		C=`echo "$LN" | cut -f 4`;
		
		cat $S3ROOT/changelog.xml | xmlstarlet ed -d "//changelog/bucket[@name='$B' and key='$K' and key/@datetime='$T' and key/@change='$C'][position()>1]" > $TMPDIR/changelog.xml.new
		mv $TMPDIR/changelog.xml.new $S3ROOT/changelog.xml
			
done

rm -f $TMPDIR/new_changelogs $TMPDIR/old_changelogs $TMPDIR/changelog
