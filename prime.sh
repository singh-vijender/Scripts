#!/bin/bash
#This script is to find the prime numbers from 1 to any number
read -p "Enter the maximum numbers to check from : " MAX
i=3
j=$MAX
flag=0
value=2
echo "1"
while [ $i -ne $j ]
do
  temp=`echo $i`
  while [ $temp -ne $value ]
  do
    temp=`expr $temp - 1`
    n=`expr $i % $temp`
    if [ $n -eq 0 -a $flag -eq 0 ]
    then
      flag=1
    fi
  done
  if [ $flag -eq 0 ]
  then
    echo $i
  else
    flag=0
  fi
  i=`expr $i + 1`
done
