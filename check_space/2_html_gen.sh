#!/bin/bash
#This is to generate script for space check result

echo "<!DOCTYPE html>" > mail.html
echo "<html>" >> mail.html

echo "<head>" >> mail.html
echo "<style>" >> mail.html
echo "table, th, td {" >> mail.html
echo "  border: 1px solid black;" >> mail.html
echo "}" >> mail.html
echo "</style>" >> mail.html
echo "</head>" >> mail.html

echo "<body>" >> mail.html
echo "<table style="width:100%">" >> mail.html
echo "<h2>Space utilization for the filesystem is as below</h>" >>mail.html
echo "<tr><th>Filesystem</th><th>Size</th><th>Used</th><th>Avail</th><th>Use%</th><th>Mounted</th></tr>" >> mail.html

echo "</table>" >> mail.html
echo "</body>" >> mail.html
echo "</html>" >> mail.html
