#!/bin/bash
#set -e #(considered bad practice?)
#trap 'exit' ERR
#read -p "HeaderWildcard: " WILDCARD
if [ -z $1 ];
then 
   echo "No Wildcard parameter provided"
   exit 1
fi
declare -a nodes=( "39" "40" "42" "43" )
WILDCARD=$1
TOTALSIZE=$((0))
echo "" > file-locations.tmp
for i in  "${nodes[@]}"
        do
        #echo "****NODE$i****"
                #echo "****$x****"
                #        echo "ssh node-$i locate /var/lib/ceph/osd/$x/current/*udata*$WILDCARD*_head*"
                        ssh -n -q node-$i "rm ./*.temporary"
                        ssh -n -q node-$i "locate /var/lib/ceph/osd/*/current/*udata*$WILDCARD*_head* > ./matches.temporary"
                        ssh -n -q node-$i 'while read -r line; do du $line >> ./matcheswsize.temporary; done < ./matches.temporary'
                        scp -q node-$i:./matcheswsize.temporary ./matcheswsize.tmp
                        #wc -l < matcheswsize.tmp
                        echo "" > node-$i.data.files.tmp
        
                        while read -r size line; do 
                           #echo "Line: $line"
                           #echo "Size: $size"
                           if [ "$size" -gt "0" ];
                             then
                                 #echo "condition met!"
                                 TOTALSIZE=$(($TOTALSIZE + $size))
                                 echo "node-$i  $line" >> file-locations.tmp
                           fi
                        done < matcheswsize.tmp
done
sort -t "\\" -k2 -u < file-locations.tmp > locate-$WILDCARD.results
#rm *.tmp
echo Found $( wc -l < locate-$WILDCARD.results ) file segments totalling $((TOTALSIZE/1024)) megabytes
rm node*.tmp
while read -r node file; do
    if [ ! -z "$file" ];
    then
       echo $file >> $node.tmp
    fi
done < locate-$WILDCARD.results
for i in  "${nodes[@]}";
do
   if [ -e node-$i.tmp ];
   then
      scp -q node-$i.tmp node-$i:./$WILDCARD.temporary 
   fi
done
if [ "$2" == "DOWNLOAD" ];
then
       echo Downloading  "$3" $WILDCARD files
       mkdir $WILDCARD
   for i in  "${nodes[@]}";
   do
   if [ -e node-$i.tmp ];
   then
        downloadsstarted=0
        downloadstodo=$(wc -l < node-$i.tmp)
        while read -r item;
        do
          downloadsstarted=$((downloadsstarted + 1))
          #echo "scp -q node-$i:$item ./$WILDCARD"
          ( scp -q "node-$i:$item" ./$WILDCARD ) &
          if (( $downloadsstarted % $(nproc) == 0 )); then wait; echo "Finished $downloadsstarted of $downloadstodo for node-$i";  fi 
        done < <(sed 's/rbd\\udata/rbd\\\\\\udata/g' < node-$i.tmp)
        wait
   fi
   done
fi
if [ "$2" == "SEARCH" ];
then
   echo Searching for "$3" in hexdumps of $WILDCARD files
   
      echo "#!/bin/bash" > search.sh
      echo "donelines=0" >> search.sh
      echo "totalcores=$(nproc)" >> search.sh
      echo "while read -r line; do" >> search.sh
      echo ' donelines=$((donelines+1)) ' >> search.sh
      echo ' (hexdump -C $line | grep -i ' $3 '  >> $donelines.'$WILDCARD.search.temporary ') &'>> search.sh
      echo '  if (( $donelines % $(nproc) == 0 )); then wait; fi' >> search.sh
      echo "done < ./$WILDCARD.temporary" >> search.sh
      echo " wait " >> search.sh
      echo " cat *.$WILDCARD.search.temporary > results.temporary" >> search.sh
      echo ' if [ -s results.temporary ]; then mv results.temporary success.temporary; fi ' >> search.sh
      echo " rm *.$WILDCARD.search.temporary results.temporary" >> search.sh




   for i in  "${nodes[@]}";
   do
   if [ -e node-$i.tmp ];
   then


      (
      ssh -q node-$i 'bash -s' < search.sh 
      scp -q node-$i:./success.temporary ./$WILDCARD.node-$i.success.tmp
      ) &

   fi
   done
  
  wait
 
  if [ $(ls ./$WILDCARD.node-*.success.tmp | wc -l ) -gt 0 ];
  then
     echo Found matches for $3 in $WILDCARD, see result files for details
  else
      echo No matches found for $3 in $WILDCARD
  fi

fi  
wait

#for i in  "${nodes[@]}";
#   do
#   if [ -e node-$i.tmp ];
#   then
#
#     scp -q node-$i:./success.temporary ./$WILDCARD.node-$i.success.tmp
#   fi
#   done
