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

rm -f $TMPDIR/new_changelogs $TMPDIR/old_changelogs $TMPDIR/changelog
