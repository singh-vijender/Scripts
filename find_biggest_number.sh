#!/bin/bash
#Scrpit to find out biggest number from array
#set -x

echo "Enter numbers with space : "
read -a ARRAY

BIGGEST=$1

for value in ${ARRAY[@]}
do
  if [[ ${value} -gt ${BIGGEST} ]]
  then
    BIGGEST=${value};
  fi
done

echo "${BIGGEST}"
