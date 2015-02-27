#!/bin/bash
mkdir test
while read p; do
  NODE=$(echo $p | cut -d "," -f 1 | cut -d "." -f 1)
  CEPH_OSD=$(echo $p | cut -d "," -f 1 | cut -d "." -f 2)
  OB=$(echo $p | cut -d "," -f 2 | sed 's/rbdudata/rbd\\\\\\udata/g')
  TARGET_OB=$(echo $OB | cut -d "/" -f 2)
  scp -q "$NODE:/var/lib/ceph/osd/$CEPH_OSD/current/$OB" "./test/$TARGET_OB"
done <sorted.results
