#!/bin/bash

# Script to check space utilization of all the filesystems
# And convert the result in table and send mail in html format

LOC=`dirname $0`
#echo "$LOC"

df -h | awk -F" " '{ print $1,$2,$3,$4,$5,$6 }' | sed -e 's/ /|/g' | sed '1d' > utilization.txt

#echo "<tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted</th></tr>" >> mail.html

FS=`df -h | awk '{print $1}' | awk '{print "<tr>"$0"</tr>"}'`
MOUNTED_ON=`df -h | awk '{print $6}' | awk '{print "<tr>"$0"</tr>"}'`
TOTAL_SPACE=`df -h | awk '{print $2}' | awk '{print "<tr>"$0"</tr>"}'`
USED_SPACE=`df -h | awk '{print $3}' | awk '{print "<tr>"$0"</tr>"}'`
AVAIL_SPACE=`df -h | awk '{print $4}' | awk '{print "<tr>"$0"</tr>"}'`
USED_PERC=`df -h | awk '{print $5}' | awk '{print "<tr>"$0"</tr>"}'`


echo "$FS" > ${LOC}/test.html

