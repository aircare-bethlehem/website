#!/usr/bin/perl

######################################################################
#  BEFORE TRYING TO EDIT THIS SCRIPT, READ THE README FILE
###################################################################### 
#
#     Dream Catchers CGI Scripts               Feel free to modify 
#     Advertiser                               this script to your 
#     Created by Seth Leonard                  needs, but please
#     for Dream Catchers Technologies, Inc.    keep this portion so
#                                              that I get credit.  
#     http://dreamcatchersweb.com/scripts      The same goes for 
#                                              distribution.
#
#     (c)1996/1997 Dream Catchers Technologies, Inc.,
#     All Rights Reserved
#
######################################################################
# ONLY EDIT THIS PART OF THE SCRIPT!!

$adcount = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/adcount.txt";
$ads_dir = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/ads";

$passwordfile = "/home/web/g/garcia.packetpushers.com/cgi-bin/advertiser/adpassword.txt";

$admincgi = "http://garcia.packetpushers.com/cgi-bin/advertiser/admin.cgi";

# DON'T EDIT BELOW THIS LINE!!
######################################################################

read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
@pairs = split(/&/, $buffer);
foreach $pair (@pairs) {
	($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	$INPUT{$name} = $value;
}

if ($INPUT{'edit'}) {
	&edit;
}
if ($INPUT{'add'}) {
	&add;
}
if ($INPUT{'del'}) {
	&del;
}
if ($INPUT{'pass'}) {
	&pass;
}
if ($INPUT{'editfinal'}) {
	&editfinal;
}
if ($INPUT{'addfinal'}) {
	&addfinal;
}
if ($INPUT{'delfinal'}) {
	&delfinal;
}

print ("Content-type: text/html\n\n");

print <<"html";

<HTML>
<HEAD>
<TITLE>Advertiser</TITLE>
</HEAD>
<BODY bgcolor=ffffff>
<form method=post action=$admincgi>
<b>Password:</b> <input type=text name=password size=8><br>
<hr>
<font size=4 color=blue>You currently have the following ads running:</font><br><br>
<table border=0 width=100%>

html

open (COUNT, "$adcount");
@lines = <COUNT>;
close (COUNT);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

$max = @lines - 1;

@advertisements = @lines[1..$max];

print <<"top";
<tr>
<td><b>Name</b></td><td><b>Exposures Purchased</b></td>
<td><b>Exposures</b></td><td><b>Visits</b></td><td><b>Ratio</b></td>
</tr>
top

foreach $advertiser (@advertisements) {

open (DISPLAY, "$ads_dir/$advertiser.txt");
@lines = <DISPLAY>;
close (DISPLAY);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

($maxshow, $shown, $visits, $image, $url, $wording, $size) = @lines;

if ($visits == 0) {
	$perc = 0;
} else {
	$perc = int (100 * ($visits / $shown));
}

print <<"advertiser";

<tr>
<td>$advertiser</td><td>$maxshow</td>
<td>$shown</td><td>$visits</td><td>$perc%</td>
</tr>

advertiser

}

print <<"html2";

</table>
<br>
<font size=4 color=blue>You have the following options:</font><br><br>
<input type=text name=editad value="type advertiser name here" size=25> <input type=submit name=edit value="Edit an Advertiser"><br><br>
<input type=text name=addad value="type advertiser name here" size=25> <input type=submit name=add value="Add an Advertiser"><br><br>
<input type=text name=delad value="type advertiser name here" size=25> 
<input type=submit name=del value="Delete an Advertiser"><br><br>
<input type=text name=passad value="type new password here" size=25> <input type=submit name=pass value="Change Admin Password">
<br><br>
</BODY>
</HTML>

html2

exit;

sub edit {

&checkpassword;

open (DISPLAY, "$ads_dir/$INPUT{'editad'}.txt");
@lines = <DISPLAY>;
close (DISPLAY);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

($maxshow, $shown, $visits, $image, $url, $wording, $size) = @lines;

print ("Content-type: text/html\n\n");

print <<"html";

<HTML>
<HEAD>
<TITLE>Advertiser</TITLE>
</HEAD>
<BODY bgcolor=ffffff>
<form method=post action=$admincgi>
<font size=4 color=blue>Current Info for $INPUT{'editad'} advertisement:</font><br><br>
<table border=0 cellspacing=10>
<tr><td><b>Name:</b></td><td>$INPUT{'editad'}</td></tr>
<tr><td><b>Exposures Purchased:</b></td><td><input type=text name=purch value="$maxshow" size=5></td></tr>
<tr><td><b>URL:</b></td><td><input type=text name=url value="$url" size=40></td></tr>
<tr><td><b>Image URL:</b></td><td><input type=text name=image value="$image" size=40></td></tr>
<tr><td><b>Below Banner:</b></td><td><input type=text name=wording value="$wording" size=40></td></tr>
<tr><td><b>Font Size:</b></td><td><input type=text name=size value="$size" 
size=3></td></tr> </table>
<br>
<input type=hidden name=editad value="$INPUT{'editad'}">
<input type=submit name=editfinal value="Make Changes">
</BODY>
</HTML>

html

exit;

}

sub add {

&checkpassword;

print ("Content-type: text/html\n\n");

print <<"html";

<HTML>
<HEAD>
<TITLE>Advertiser</TITLE>
</HEAD>
<BODY bgcolor=ffffff>
<form method=post action=$admincgi>
<font size=4 color=blue>Create Info for $INPUT{'addad'} advertisement:</font><br><br>
<table border=0 cellspacing=10>
<tr><td><b>Name:</b></td><td><input type=text name=addad value="$INPUT{'addad'}" size=15></td></tr>
<tr><td><b>Exposures Purchased:</b></td><td><input type=text name=purch size=5></td></tr>
<tr><td><b>URL:</b></td><td><input type=text name=url size=40></td></tr>
<tr><td><b>Image URL:</b></td><td><input type=text name=image size=40></td></tr>
<tr><td><b>Below Banner:</b></td><td><input type=text name=wording value="Please Visit our Sponsor" size=40></td></tr>
<tr><td><b>Font Size:</b></td><td><input type=text name=size value="2" 
size=3></td></tr> </table>
<br>
<input type=submit name=addfinal value="Create Advertisement">
</BODY>
</HTML>

html

exit;

}

sub del {

&checkpassword;

print ("Content-type: text/html\n\n");

print <<"html";

<HTML>
<HEAD>
<TITLE>Advertiser</TITLE>
</HEAD>
<BODY bgcolor=ffffff>
<form method=post action=$admincgi>
<center><font size=4 color=blue>Are you sure you want to delete your 
$INPUT{'delad'} advertisement?</font><br><br>
<input type=hidden name=delad value=$INPUT{'delad'}>
<input type=submit name=delfinal value="Yes"></center>
</BODY>
</HTML>

html

exit;

}

sub pass {

&checkpassword;

$newpassword = crypt($INPUT{'passad'}, aa);

open (PASSWORD, ">$passwordfile");
print PASSWORD ("$newpassword");
close (PASSWORD);

print ("Content-type: text/html\n\n");

print <<"html";

<HTML>
<HEAD>
<TITLE>Advertiser</TITLE>
</HEAD>
<BODY bgcolor=ffffff>
<center><font size=4 color=blue>Your New Admin Password Is:<br><br>$INPUT{'passad'}</font><br><br>
</BODY>
</HTML>

html

exit;

}

sub editfinal {

$editad = $INPUT{'editad'};

open (DISPLAY, "$ads_dir/$editad.txt");
@lines = <DISPLAY>;
close (DISPLAY);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

($maxshow, $shown, $visits, $image, $url, $wording, $size) = @lines;

$maxshow = $INPUT{'purch'};
$url = $INPUT{'url'};
$image = $INPUT{'image'};
$wording = $INPUT{'wording'};
$size = $INPUT{'size'};

open (DISPLAY, ">$ads_dir/$editad.txt");
print DISPLAY ("$maxshow\n");
print DISPLAY ("$shown\n");
print DISPLAY ("$visits\n");
print DISPLAY ("$image\n");
print DISPLAY ("$url\n");
print DISPLAY ("$wording\n");
print DISPLAY ("$size\n");
close DISPLAY;

print ("Location: $admincgi\n\n");

exit;

}

sub addfinal {

$addad = $INPUT{'addad'};

$maxshow = $INPUT{'purch'};
$url = $INPUT{'url'};
$image = $INPUT{'image'};
$wording = $INPUT{'wording'};
$size = $INPUT{'size'};

open (DISPLAY, ">$ads_dir/$addad.txt");
print DISPLAY ("$maxshow\n");
print DISPLAY ("0\n");
print DISPLAY ("0\n");
print DISPLAY ("$image\n");
print DISPLAY ("$url\n");
print DISPLAY ("$wording\n");
print DISPLAY ("$size\n");
close (DISPLAY);

open (COUNT, "$adcount");
@lines = <COUNT>;
close (COUNT);

unless ($lines[@lines - 1] =~ /$addad/) {

	open (COUNT, ">>$adcount");
	print COUNT ("$addad\n");
	close (COUNT);

}

}

sub delfinal {

$delad = $INPUT{'delad'};

unlink ("$ads_dir/$delad.txt");

open (COUNT, "$adcount");
@lines = <COUNT>;
close (COUNT);

foreach $line (@lines) {
	chop ($line) if ($line =~ /\n$/);
}

open (COUNT, ">$adcount");
foreach $line (@lines) {
	unless ($line eq $delad) {
		print COUNT ("$line\n");
	}
}
close (COUNT);

print ("Location: $admincgi\n\n");

exit;

}

sub checkpassword {

open (PASSWORD, "$passwordfile");
$password = <PASSWORD>;
close (PASSWORD);

chop ($password) if ($password =~ /\n$/);

$newpassword = crypt($INPUT{'password'}, aa);

unless ($newpassword eq $password) {
	print ("Location: $admincgi\n\n");
	exit;
}

}
