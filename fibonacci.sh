#!/bin/bash
#This is script to find print fibonacci series
echo "Numbers to digits to print from fibbonacci series : "
read number
x=0
y=1
i=2
echo "Fibonacci Series up to $n terms :"
echo "$x"
echo "$y"
while [ $i -lt $number ]
do
  i=`expr $i + 1 `
  z=`expr $x + $y `
  echo "$z"
  x=$y
  y=$z
done
