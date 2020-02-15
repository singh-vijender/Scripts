#!/bin/bash
set +x
df -h | awk -F" " '{ print $1,$2,$3,$4,$5,$6 }' | sed -e 's/ /|/g' | sed '1d' | while read -r line
do
	while read output
	do
		echo "$output" | sed -n 1'p' | tr '|' '\n' >> testing
	done
done
