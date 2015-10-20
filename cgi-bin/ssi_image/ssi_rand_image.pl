#!/usr/bin/perl
##############################################################################
# SSI Random Image Displayer    Version 1.2                                  # 
# Copyright 1996 Matt Wright    mattw@worldwidemart.com                      #
# Created 7/1/95                Last Modified 11/4/95                        #
# Scripts Archive at:           http://www.worldwidemart.com/scripts/        #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# SSI Random Image may be used and modified free of charge by anyone so      #
# long as this copyright notice and the comments above remain intact.  By    #
# using this this code you agree to indemnify Matthew M. Wright from any     #
# liability that might arise from it's use.                                  #  
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.  In all cases copyright and header must remain intact.#
##############################################################################
# Define Variables

$basedir = "/images/";

@images = ("first_image.gif","second_image.jpg","third_image.gif");

@urls = ("http://url_linked/to/first_image",
         "http://url_linked/to/second_image",
         "http://url_linked/to/third_image");

@alt = ("First WWW Page","Second WWW Page","Third WWW Page");

##############################################################################
# Options
$uselog = "1";            # 1 = YES; 0 = NO
   $logfile = "/path/to/log/file";
   $date = `/usr/bin/date`; chop($date);

$link_image = "1";        # 1 = YES; 0 = NO
$align = "left";
$border = "2";

# Done
##############################################################################

srand(time ^ $$);
$num = rand(@images); # Pick a Random Number

# Print Out Header With Random Filename and Base Directory
print "Content-type: text/html\n\n";
if ($link_image eq '1' && $urls[$num] ne "") {
   print "<a href=\"$urls[$num]\">";
}

print "<img src=\"$basedir$images[$num]\"";
if ($border ne "") {
   print " border=$border";
}
if ($align ne "") {
   print " align=$align";
}
if ($alt[$num] ne "") {
   print " alt=\"$alt[$num]\"";
}
print ">";

if ($link_image eq '1' && $urls[$num] ne "") {
   print "</a>";
}

print "\n";

# If You want a log, we add to it here.
if ($uselog eq '1') {
   open(LOG, ">>$logfile");
   print LOG "$images[$num] - $date - $ENV{'REMOTE_HOST'}\n";
   close(LOG);
}
