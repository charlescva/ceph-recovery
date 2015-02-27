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
			ssh -q node-$i find $y -type f -name *$WILDCARD* >> node-$i.$x.data.files.tmp
			done
		cat node-$i.$x.data.files.tmp | cut -d "/" -f 8,9 >> node-$i.$x.data.files
		rm node-$i.$x.data.files.tmp
		done
	done

for x in $(for i in $(ls *.files); do echo $i; done); do ./consolidate-stuff.sh $x; done
rm *.files
cat result.csv | sort -t "," -k2 -u > sorted.results
rm result.csv
scp-obs.sh
cd test
for i in $(ls); do dd if=$i of=test.raw bs=1024 conv=notrunc oflag=append; done
