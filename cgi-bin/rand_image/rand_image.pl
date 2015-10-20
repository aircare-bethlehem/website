#!/usr/bin/perl
##############################################################################
# Basic Random Image Displayer  Version 1.2                                  # 
# Copyright 1996 Matt Wright    mattw@worldwidemart.com                      #
# Created 7/1/95                Last Modified 7/20/95                        #
# Scripts Archive at:           http://www.worldwidemart.com/scripts/        #
##############################################################################
# COPYRIGHT NOTICE                                                           #
# Copyright 1996 Matthew M. Wright  All Rights Reserved.                     #
#                                                                            #
# Basic Random Image may be used and modified free of charge by anyone so    #
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
# Necessary Variables
  $basedir = "/images/";
  @files = ("first_image.gif","test.gif","random.gif","neat.jpg");

# Options
  $uselog = 0; # 1 = YES; 0 = NO
        $logfile = "$ENV{'DOCUMENT_ROOT'}/cgi-bin/rand_image/piclog";

# Done
##############################################################################

srand(time ^ $$);
$num = rand(@files); # Pick a Random Number

# Print Out Header With Random Filename and Base Directory
print "Location: $basedir$files[$num]\n\n";

# Log Image
if ($uselog eq '1') {
    open (LOG, ">>$logfile");
    print LOG "$files[$num]\n";
    close (LOG);
}
