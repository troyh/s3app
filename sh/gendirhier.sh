#!/bin/bash

S3ROOT=".."
BUCKETS_DIR="$S3ROOT/buckets"
XMLDIR="$S3ROOT/xml"

SINGLE_BUCKET="";
if [ "x$1" != "x" ]; then
	SINGLE_BUCKET=$1;
fi
	

xmlstarlet sel -t -m "//bucket_list/bucket" -v name -n $S3ROOT/index.xml | sed -e '/^\s*$/d' \
	| while read BUCKET; do
	
	if [ -n "$SINGLE_BUCKET" ]; then
		if [ "$SINGLE_BUCKET" != "$BUCKET" ]; then
			continue;
		fi
	fi
		
	echo "Bucket: $BUCKET";
	if [ ! -d $BUCKETS_DIR/$BUCKET ]; then
		mkdir $BUCKETS_DIR/$BUCKET;
	fi
		
	# Get list of directories
	xmlstarlet sel -t -m //contents/key -v name -n $XMLDIR/$BUCKET.xml | sed -e '/^\s*$/d' \
		| sed -e 's:/[^/]*$:/:' \
		| sort -u \
		| perl -ne '@parts=split(/\//);for($i=0;$i<=$#parts;++$i){for($j=0;$j<$i;++$j){print $parts[$j]."/";}print "\n";}'\
		| sort -u \
		| while read DIR; do
	
		# For each directory, create an index.xml in that directory that contains the files and subdirectories

		# Create the directory if it doesn't already exist
		CDIR=`echo "$DIR" | sed -e 's/&amp;/\\&/g'`;
		if [ ! -d "$BUCKETS_DIR/$BUCKET/$CDIR" ]; then
			echo "Creating directory $BUCKETS_DIR/$BUCKET/$CDIR";
			mkdir -p "$BUCKETS_DIR/$BUCKET/$CDIR";
		fi

		echo "Creating $BUCKETS_DIR/$BUCKET/$CDIR/index.xml";

		xmlstarlet sel -t -m "//contents/key[starts-with(name,&quot;$DIR&quot;)]" -v name -o "&#09;" -c . -n "$XMLDIR/$BUCKET.xml" \
			| sed -e '/^\s*$/d' -e "s|$DIR||g" -e 's:/[^\t][^\t]*\t.*$:/:' \
			| sort -u \
			| sed -e 's/^.*\t//' \
			| perl -ne 'chomp;if (/^<key/) {print "$_\n";} else { print "<dir><name>$_</name></dir>\n"; }' \
			| sed -e "1i\
			<?xml-stylesheet type=\"text/xsl\" href=\"/s3/xsl/index.xsl\"?>\
			<contents>\
			<meta>\
				<doctime>`xmlstarlet sel -t -v "//meta/doctime" $XMLDIR/$BUCKET.xml`</doctime>\
				<bucketname>$BUCKET</bucketname>\
				`echo "$DIR" | perl -ne 'chomp;@parts=split(/\//);foreach $p (@parts) {print "<path>$p</path>";}'`\
			</meta>\
			" \
			-e '$a</contents>' \
			> "$BUCKETS_DIR/$BUCKET/$CDIR/index.xml"

		
		xmlstarlet sel -t -m "//dir/name" -v . -n "$BUCKETS_DIR/$BUCKET/$CDIR/index.xml" \
			| sed -e '/^\s*$/d' \
			| while read FOO; do
			
			NUMFILES=`xmlstarlet sel -t -v "count(//contents/key[starts-with(name,'$DIR$FOO')])" $XMLDIR/$BUCKET.xml`
			SIZE=`xmlstarlet sel -t -v "sum(//contents/key[starts-with(name,'$DIR$FOO')]/@size)" $XMLDIR/$BUCKET.xml`

			SIZE=`echo "$SIZE" | sed -e 's/e[+-]\([0-9][0-9]*\)/*10^\1/g' | bc`;
			echo $DIR$FOO size=$SIZE;
			
			cat "$BUCKETS_DIR/$BUCKET/$CDIR/index.xml" \
				| xmlstarlet ed -d "//dir[name='$FOO']/@files" \
				| xmlstarlet ed -d "//dir[name='$FOO']/@size" \
				| xmlstarlet ed -i "//dir[name='$FOO']" -t attr -n files -v $NUMFILES \
				| xmlstarlet ed -i "//dir[name='$FOO']" -t attr -n size -v $SIZE \
				> "$BUCKETS_DIR/$BUCKET/$CDIR/index.xml"
			
		done
	
	done
	
done
