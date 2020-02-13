#!/usr/bin/perl

# Only u will become upper case.
$str = "\uhi perl";
print "$str\n";
# All the letters will become Uppercase.
$str = "\Uhello perl";
print "$str\n";
# A portion of string will become Uppercase.
$str = "hey \Uperl\E";
print "$str\n";

#Testing
