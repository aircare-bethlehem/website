#!/usr/bin/perl
# tmail.cgi (Templated Mailer CGI)
# Created: 2/22/1998 v0.9a
# By: Kenn Wagenheim (kennwag@hostme.com)
#
# Modified 3/10/1999 v1.2
# Modified 4/16/1999 v1.3
# By: Kenn Wagenheim (kennwag@hostme.com)
# Added Logging!
#
# Use of this script is FREE so long as you do not
# modify it in any way.  Modification of any type
# must be approved in e-mail by support@iuinc.com
#
# Edit These Variables To Work With Your System

# Path to your CGI directory
# Example:  /home/WWW/hostme.com/cgi-bin
$CgiPath = "$ENV{'DOCUMENT_ROOT'}/../cgi-bin";

# Path to sendmail binary (and switches)
# Example: /usr/sbin/sendmail -t
$SendMailPath = "/usr/sbin/sendmail -t";

$logpath = "$CgiPath/tmail/logs/";

#####################################
# DO NOT EDIT BELOW THIS COMMENT!!!!!
#####################################

require "$CgiPath/cgi-lib.pl" || die ("Couldn't find $CgiPath/cgi-lib.pl ... sorry.\n"); 

#####################################

&ReadParse;

#Maybe later
#&Init;

&Process;

&Response;

#####################################

sub Init {

     #####################################
     # WARNING!  Editing the preset $mail variable 
     # settings is a violation of the free-use 
     # agreement and is a copyright infringement.
     #####################################
  
     $mail = "";

     $missing = 0;
     $NoTemplate = 0;

     if ($in{'_OCLOSE'} eq "")
       {  $oclose = "["; }
     else
       {  $oclose = "$in{'_OCLOSE'}"; }

     if ($in{'_OCLOSE'} eq "")
       {  $oclose = "]"; }
     else
       {  $eclose = "$in{'_ECLOSE'}"; }

   }

#####################################

sub Process {

     $template = $in{'_TEMPLATE'};

     if ($template eq "")
       {
	 # Template Not Set.
         $NoTemplate = 2;
       }
     elsif (!(-e "$CgiPath/tmail/Templates/$template"))
       {
	 # Template Set But Not Found.
         $NoTemplate = 1;
         $mail = $mail . 
                "WARNING! TEMPLATE FILE DOES NOT EXIST ($template)\n";
 	 &TMailLog ("TEMPLATE FILE DOES NOT EXIST ($template) <RFR: $ENV{'HTTP_REFERER'}>");
       }

     # Open Template.
     open (TEMP, "$CgiPath/tmail/Templates/$template");
     @template = <TEMP>;
     close TEMP;

     if ($NoTemplate > 0)
       {
	# No Template Found, Figure Out Spacing Needs
	$biggest = 0;
	foreach $loop (sort keys (%in))
	  {
	    # Picking / Tracking Longst Variable
	    if (length($loop) > $biggest)
		{ $biggest = length($loop); }
	  }

	# Sort and Display Variables and Results.
        foreach $loop (sort keys (%in))
	  {
	    $space = "";
	    foreach $spaceit (length($loop) .. $biggest)
		{  $space = $space . " "; }

	    $mail = $mail . 
		    $space . 
		    $loop . 
		    " : " .
		    $oclose .
		    $in{$loop} .
		    $eclose .
		    "\n";
	  }
       }
     else # Template WAS Found.
       {
        foreach (@template)
         {
          $current = $_;
          ($first, $second) = split (/\[/, $current, 2);
          ($variable, $third) = split (/\]/, $second, 2);
          if (substr ($variable, 0, 1) eq '*')
            {
              $variable =~ s/^\*//g;
              if ($in{$variable} eq "")
                {   
                  $missing ++;
                  $missing{$variable} = 1;
                }
            }
          
          # Replace Template Vars For Output.  1st norm;  2nd required vars
          $current =~ s/\[$variable\]/$oclose$in{$variable}$eclose/g;
          $current =~ s/\[\*$variable\]/$oclose$in{$variable}$eclose/g;
         
          # Append to Mailer.
          $mail = $mail . $current;
         }
       } 

     &SendMail if ($missing < 1);

   }

#####################################

sub SendMail {

     $in{'_SUBJECT'} =~ s/[\x00-\x1F\x60\x7F-\xFF]//g;
     $in{'_MAILTO'} =~ s/[\x00-\x1F\x60\x7F-\xFF]//g;
     $in{'_MAILCC'} =~ s/[\x00-\x1F\x60\x7F-\xFF]//g;
     $in{'_FROMEMAIL'} =~ s/[\x00-\x1F\x60\x7F-\xFF]//g;

     if ($in{'_SUBJECT'} eq "")
       {
          $in{'_SUBJECT'} = "Form Mail";     
       }
  
     if ($in{'_FROMEMAIL'} ne "")
	{  
	  $from = $in{'_FROMEMAIL'};
	}
     else
	{
	  $from = $in{'_MAILTO'};
	}

     &TMailLog ("  ** Mail Sent ** \n" . 
		"           To:  $in{'_MAILTO'}\n" . 
		"           CC:  $in{'_MAILCC'}\n" .
	        "         From:  $from\n" .
	        "         Subj:  $in{'_SUBJECT'}\n" . 
	        "          RFR:  $ENV{'HTTP_REFERER'}");
  
     $mail = $mail .
	   "\n\n---------------------------------------\n" .
	       "  Form Mail Generate By: \n" . 
	       "  TMail v1.3 (http://www.hostme.com/)\n" .
	       "---------------------------------------\n";

     open (MAIL, "| $SendMailPath");
     print MAIL<<OUT;
To: $in{'_MAILTO'}
CC: $in{'_MAILCC'}
From: $from
Subject: $in{'_SUBJECT'}

$mail
OUT
     close MAIL;

   }

#####################################

sub Response {

    if ($missing > 0)
      {
	 # If missed required, tell them!
	 if ($in{'_MISSING'} ne "")
	   { $Response = $in{'_MISSING'}; }
	 else
	   { $Response = "/tmail/tmail-missing.html"; }
	 &TMailLog ("Required Field Empty <RFR: $ENV{'HTTP_REFERER'}>");
      }
    else
      {
	# All went well, thank them.
	if ($in{'_THANKS'} ne "")
	  { $Response = $in{'_THANKS'}; }
	else
	 { $Response = "/tmail/tmail-thanks.html"; }
      }

    print "Location: $Response\n\n";
  }

#####################################

sub TMailLog {
     
     local ($entry) = @_;

     return if (!($in{'_LOG'} == 1));

     $time = time;
     $showtime = localtime ($time);

     $newlog = 0;
     $newlog = 1 if (!(-e "$logpath/tmail_log"));

     open (LOG, ">>$logpath/tmail_log");
     print LOG "[$showtime] $entry\n";
     close LOG;
 
     `chmod 777 $logpath/tmail_log` if $newlog == 1;
}

#####################################

