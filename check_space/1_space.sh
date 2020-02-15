#!/bin/bash

# Script to check space utilization of all the filesystems
# And convert the result in table and send mail in html format

LOC=`dirname $0`
#echo "$LOC"

echo "<!DOCTYPE html>" > mail.html
echo "<html>" >> mail.html

echo "<head>" >> mail.html
echo "<style>" >> mail.html
echo "table, th, td {" >> mail.html
echo "  border: 1px solid black;" >> mail.html
echo "  border-collapse: collapse;" >> mail.html
echo "}" >> mail.html
echo "</style>" >> mail.html
echo "</head>" >> mail.html

echo "<body>" >> mail.html
echo "<table style="width:60%">" >> mail.html
echo "<h2>Space utilization for the filesystem is as below</h2>" >>mail.html
#echo "<tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted</th></tr>" >> mail.html








#rm output.html
#df -h | awk -F" " '{ print $1,$2,$3,$4,$5,$6 }' | sed -e 's/ /|/g' | sed '1d' | sed -n 1'p' | tr '|' '\n' | while read -r line
#do
#	echo -ne "<th$line</th>" >> output.html
#done
#echo "" >> output.html

echo "<table>" >> mail.html
echo "    <tr>" >> mail.html
echo "      <th>Filesystem</th>" >> mail.html
echo "      <th>Type</th>" >> mail.html
echo "      <th>Size</th>" >> mail.html
echo "      <th>Used</th>" >> mail.html
echo "      <th>Avail</th>" >> mail.html
echo "      <th>Use%</th>" >> mail.html
echo "      <th>Mounted on</th>" >> mail.html
echo "    </tr>" >> mail.html

df -PTh | \
sed '1d' | \
sort -nr -k6 | \
awk '
{
	printf "\n\t<tr>";
	for (n = 1; n < 7; ++n)
	printf("\n\t<td>%s</td>",$n);
	printf "\n\t<td>";
	for(;n <= NF; ++n)
	printf("%s ",$n);
	printf "</td>\n\t</tr>"
}
' >> mail.html


FS=`df -h | awk '{print $1}' | awk '{print "<tr>"$0"</tr>"}'`
MOUNTED_ON=`df -h | awk '{print $6}' | awk '{print "<tr>"$0"</tr>"}'`
TOTAL_SPACE=`df -h | awk '{print $2}' | awk '{print "<tr>"$0"</tr>"}'`
USED_SPACE=`df -h | awk '{print $3}' | awk '{print "<tr>"$0"</tr>"}'`
AVAIL_SPACE=`df -h | awk '{print $4}' | awk '{print "<tr>"$0"</tr>"}'`
USED_PERC=`df -h | awk '{print $5}' | awk '{print "<tr>"$0"</tr>"}'`


echo "$FS" > ${LOC}/test.html

















echo "</table>" >> mail.html
echo "</body>" >> mail.html
echo "</html>" >> mail.html
