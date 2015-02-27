#!/bin/bash
for i in "39" "40" "42" "43";
	do
	echo ****NODE$i**** 
	for x in $(ssh -q node-$i ls /var/lib/ceph/osd);
		do
		echo ****$x****
		ssh -q node-$i find /var/lib/ceph/osd/$x/current -type f -name "*header*"
		done
	done
