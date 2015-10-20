#!/usr/bin/perl
##############################################################################
# Free For All Link Page        Version 2.2                                  # 
# Copyright 1996 Matt Wright    mattw@worldwidemart.com                      #
# Created 5/14/95               Last Modified 7/17/96                        #
# Scripts Archive at:           http://www.worldwidemart.com/scripts/        #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# Free For All Links may be used and modified free of charge by anyone so    #
# long as this copyright notice and the comments above remain intact.  By    #
# using this this code you agree to indemnify Matthew M. Wright from any     #
# liability that might arise from it's use.                                  #  
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.	In all cases copyright and header must remain intact.#
##############################################################################
# Define Variables

$filename = "$ENV{'DOCUMENT_ROOT'}/links/links.html";
$linksurl = "/links/links.html";
$linkscgi = "/cgi-bin/links/links.cgi";
$linkstitle = "Free For All Links";
$database = "$ENV{'DOCUMENT_ROOT'}/links/database.txt";

# Done
##############################################################################

# Get the input
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});

# Split the name-value pairs
@pairs = split(/&/, $buffer);

foreach $pair (@pairs) {
   ($name, $value) = split(/=/, $pair);

   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
   $value =~ s/<([^>]|\n)*>//g;
   $value =~ s/<//g;
   $value =~ s/>//g;
   $FORM{$name} = $value;
}

if ($FORM{'url'} eq 'http://' || $FORM{'url'} !~ /^(f|ht)tp:\/\/\w+\.\w+/) { 
   &no_url; 
} 
if (!($FORM{'title'})) {
   &no_title;
}

# Enter our tags and sections into an associative array

%sections = ("busi","Business","comp","Computers","educ","Education",
	     "ente","Entertainment","gove","Government",
	     "pers","Personal","misc","Miscellaneous");

# Suck previous link file into one big string
open(FILE,"$filename");
@lines = <FILE>;
close(FILE);

$i=1;
foreach $line (@lines) {    
    if ($line =~ /\<li\>\<a href\=\"([^\"]+)\">([^<]+)<\/a>/) {
        if ($FORM{'url'} eq $1) {
            &repeat_url;
        }
        $i++;
    }
}

# Open Link File to Output
open (FILE,">$filename");

foreach $line (@lines) { # For every line in our data

   if ($line =~ /<!--time-->/) {
      @months = ('January','February','March','April','May','June',
		 'July','August','September','October','November','December');

      @days = ('Sunday','Monday','Tuesday','Wednesday','Thursday',
	       'Friday','Saturday');

      ($sec,$min,$hour,$mday,$mon,$years,$wday) = (localtime(time))[0,1,2,3,4,5,6];
      if ($sec < 10) { $sec = "0$sec"; }
      if ($min < 10) { $min = "0$min"; }
      if ($hour < 10) { $hour = "0$hour"; }
      if ($mday < 10) { $mday = "0$mday"; }
	$year = 1900 + years;
      $date = "on $days[$wday], $months[$mon] $mday, $year at $hour:$min:$sec";
      print FILE "<!--time--><b>Last link was added $date</b><hr>\n";
   }
   elsif ($line =~ /<!--number-->/) {
      print FILE "<!--number--><b>There are <i>$i</i> links on this ";
      print FILE "page.</b><br>\n";
   }
   else {
       print FILE $line;
   }

   foreach $tag ( keys %sections) { # For every tag 
      if ( ($FORM{'section'} eq $sections{$tag}) && 
         ($line =~ /<!--$tag-->/) ) {

         print FILE "<li><a href=\"$FORM{'url'}\">$FORM{'title'}</a>\n"; 
      }
   }
}

close (FILE);

# Return Link File
print "Location: $linksurl\n\n";

if ($database ne '') {
    open (DATABASE,">>$database");
    print DATABASE "$FORM{'url'}\n";
    close(DATABASE);
}

sub no_url {
   print "Content-type: text/html\n\n";
   print "<html><head><title>ERROR: No URL</title></head>\n";
   print "<body bgcolor=#FFFFFF text=#000000><center>";
   print "<h1>No URL</h1></center>\n";
   print "You forgot to enter a url you wanted added to the Free for ";  
   print "all link page.  Another possible problem was that your link ";
   print "was invalid.<p>\n";
   print "<form method=POST action=\"$linkscgi\">\n";
   print "<input type=hidden name=\"title\" value=\"$FORM{'title'}\">\n";
   print "<input type=hidden name=\"section\""; 
   print "value=\"$FORM{'section'}\">\n";
   print "URL: <input type=text name=\"url\" size=50><p>\n";
   print "<input type=submit> * <input type=reset>\n";
   print "<hr>\n";
   print "<a href=\"$linksurl\">$linkstitle</a>\n";
   print "</form></body></html>\n";

   exit;
}

sub no_title {
   print "Content-type: text/html\n\n";
   print "<html><head><title>ERROR: No Title</title></head>\n";
   print "<body bgcolor=#FFFFFF text=#000000><center>";
   print "<h1>No Title</h1></center>\n";
   print "You forgot to enter a title you wanted added to the Free for ";
   print "all link page.  Another possible problem is that you title ";
   print "contained illegal characters.<p>\n";
   print "<form method=POST action=\"$linkscgi\">\n";
   print "<input type=hidden name=\"url\" value=\"$FORM{'url'}\">\n"; 
   print "<input type=hidden name=\"section\"";
   print "value=\"$FORM{'section'}\">\n";
   print "TITLE: <input type=text name=\"title\" size=50><p>\n";
   print "<input type=submit> * <input type=reset>\n";
   print "<hr>\n";
   print "<a href=\"$linksurl\">$linkstitle</a>\n";
   print "</form></body></html>\n";

   exit;
}

sub repeat_url {
   print "Content-type: text/html\n\n";
   print "<html><head><title>ERROR: Repeat URL</title></head>\n";
   print "<body bgcolor=#FFFFFF text=#000000><center><h1>Repeat URL</h1></center>\n";
   print "Sorry, this URL is already in the Free For All Link Page.\n";
   print "You cannot add this URL to it again.  Sorry.<p>\n";
   print "<a href=\"$linksurl\">$linkstitle</a>";
   print "</body></html>\n";

   exit;
}
