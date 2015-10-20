#!/usr/bin/perl
# NO CONFIGURATION NEEDED!!!!!
# NO CONFIGURATION NEEDED!!!!!

$homepath = "$ENV{'DOCUMENT_ROOT'}/../cgi-bin";

$file = "$homepath/ssicount/data/$user.txt";
                  # blank text file, related to the scriptlocation
                  # if you want, let say, 5 digit counter start it with 00001
$ext = '.gif';                          # graphic files extension
$path = '/ssicount/digits/';   # graphic files location

print "Content-type: text/html\n\n"; 
  open(COUNT, $file); $count = <COUNT>; close(COUNT); ++$count; 
  @nums = split(//, $count); 

# Enable one of the following lines to have image or text counter
# Let them as is to have a hidden counter and check 'count.txt' to see the numbers

foreach $num (@nums) {$display = "<img src=$path$num$ext>"; print $display; }   # image
#foreach $num (@nums) {$display = "$num"; print $display; }                      # text

open(NCOUNT, ">$file"); 
print NCOUNT $count; 
close NCOUNT;
