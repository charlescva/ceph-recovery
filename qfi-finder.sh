#!/bin/bash
set -e
read -p "HeaderWildcard: " WILDCARD
for i in "39" "40" "42" "43";
	do
	#echo ****NODE$i**** 
	for x in $(ssh -q node-$i ls /var/lib/ceph/osd);
		do
		#echo ****$x****
		for y in $(ssh -q node-$i find /var/lib/ceph/osd/$x/current -type d -size +1b | grep _head);
			do
			ssh -q node-$i find $y -type f -name *$WILDCARD.0000000000000000* >> node-$i.$x.data.files.tmp
			done
		cat node-$i.$x.data.files.tmp | cut -d "/" -f 8,9 >> node-$i.$x.data.files
		rm node-$i.$x.data.files.tmp
		done
	done

for x in $(for i in $(ls *.files); do echo $i; done); do ./consolidate-stuff.sh $x; done
rm *.files
cat result.csv | sort -t "," -k2 -u > sorted.results
rm result.csv

while read p; do
  NODE=$(echo $p | cut -d "," -f 1 | cut -d "." -f 1)
  CEPH_OSD=$(echo $p | cut -d "," -f 1 | cut -d "." -f 2)
  OB=$(echo $p | cut -d "," -f 2 | sed 's/rbdudata/rbd\\\\\\udata/g')
  scp -q "$NODE:/var/lib/ceph/osd/$CEPH_OSD/current/$OB" "first-block"
done <sorted.results
echo Dumping first Byte of Object ID: $WILDCARD
hexdump -C -n 4 -s 0 first-block
