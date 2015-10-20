#!/usr/bin/perl
##############################################################################
# Random Link                   Version 1.0                                  #
# Copyright 1996 Matt Wright    mattw@worldwidemart.com                      #
# Created 7/15/95               Last Modified 7/30/95                        #
# Scripts Archive at:           http://www.worldwidemart.com/scripts/        #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# Random Link may be used and modified free of charge by anyone so long as   #
# this copyright notice and the comments above remain intact.  By using this #
# code you agree to indemnify Matthew M. Wright from any liability that      #
# might arise from it's use.                                                 #
#                                                                            #
# Selling the code for this program without prior written consent is         #
# expressly forbidden.  In other words, please ask first before you try and  #
# make money off of my program.                                              #
#                                                                            #
# Obtain permission before redistributing this software over the Internet or #
# in any other medium.  In all cases copyright and header must remain intact.#
##############################################################################
# Define Variables

$linkfile = "$ENV{'DOCUMENT_ROOT'}/cgi-bin/rand_link/database";

# Options
$uselog = 1;            # 1 = YES; 0 = NO
   $logfile = "$ENV{'DOCUMENT_ROOT'}/cgi-bin/rand_link/rand_log";

$date = `date +"%D"`; chop($date);

# Done
##############################################################################

open (LINKS, "$linkfile");

srand();                        # kick rand
$nlines=@file=<LINKS>;          # inhale file & get # of lines
print "Location: $file[int rand $nlines]\n\n";  # print a random line

close (LINKS);

if ($uselog eq '1') {
   open (LOG, ">>$logfile");
   print LOG "$ENV{'REMOTE_HOST'} - [$date]\n";
   close (LOG);
}

exit;
