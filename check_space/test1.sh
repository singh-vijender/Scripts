df -PTh | \
	sed '1d' | \
	sort -n -k6 | \
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
'
