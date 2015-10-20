#!/usr/bin/perl
################################################################
# File name :	test.pl
# Description :	Configuration test script.
# Author :	Nardone Vittorio (nards@iol.it)
# Version :	First 98
################################################################
#########################################################################
# 	DON'T EDIT SCRIPT CODE ! COPYRIGHT 1997 VITTORIO NARDONE        #
# 		YOU CAN ONLY EDIT "INCLUDE.PL" FILE !                   #
# 			ALL RIGHTS RESERVED                             #
#########################################################################

print ("\nChatMachine configuration test. Version 98.\n\n");
print ("This script tests \'include.pl\' file to check ChatMachine settings.\n");
print ("Can I start check procedure ? [Y/n] ");
if (! &waitKey('Y','N')) { 
	print ("ChatMachine configuration test aborted.\n");
	exit(0);
};
print ("\nScript search ...\n");
foreach $filename ('include.pl','chat.pl','login.pl','adm.pl') 
{
  &fileExist("$filename",'Yes',"No\n$filename file must be in the same directory of this script !\n");
  &scriptTest("$filename");
};

if (! do 'include.pl' ) {
	print ("\n\n\'include.pl\' file execution failed ! \nCheck include.pl file for syntax errors ( try : perl -d include.pl ).\n");
	print("WARNING: \'\$endfile\' setting must be last setting in \'include.pl\' file.\n");
	print("         \'\$endfile\' must be equal to \'1\'.\n"); 
	exit(0);
};
print ("\n\nAre all ChatMachine settings defined ? ...");

foreach $setname
('$chatdir','$scriptUrl','$htmlUrl','$userdir','$logdir','$mesgdir','$tmpldir','$laction',
'$loginform','$admloginform','$errfile','$listfile',
'$logpre','$chatpre','$admchatpre',
'$welfile','$exitfile',
'$tmplPublic','$tmplPrivate','$tmplFromMe','$tmplSystem',
'$tmplPublicOld','$tmplPrivateOld','$tmplFromMeOld','$tmplSystemOld',
'$roompre','$roomdir','$leaveroom','$enterroom',
'@admName','$admpre','$admlogpre','$admuserpre','$admhostpre','$admippre','$admdompre','$admnickpre',
'$admdat','$banip','$banhost','$bannick','$bandom','$admret',
'$logoutmsg','$loginmsg',
'$daemonCfg','$userLimit',
'@fieldList','$applyDefault',
'$sysName','$allStr','@months','$noHTML',
'$autoclose','@allowHTML',
'$nickLen','$messLen','$mesgLimit','$oldLimit','$mesgOrder',
'$autoPrivate','$flockMode',
'$timeAdjust','$applyTControl','@timeControl','$timeclose',
'$mldir','$logindex','$mlpre','$mltop','$mlsystem','$mltime',
'$endfile')

{
$dummy = eval ("$setname");
if ( "$dummy" eq '' ) {
 	print ("\n\'$setname\' setting not defined. Check your include.pl file.\nWarning : all settings are case sensitive.\n");
	exit(0);
	}; 
};

print ("Yes\n\nDirectory check ...\n");

foreach $dirname
("$chatdir","$chatdir$userdir","$chatdir$logdir","$chatdir$mesgdir",
"$chatdir$tmpldir","$chatdir$laction","$chatdir$banip","$chatdir$banhost",
"$chatdir$bannick","$chatdir$bandom","$chatdir$mldir","$chatdir$roomdir")
{
  &dirExist("$dirname",'Yes',"No\n$dirname directory does not exist !\n");
};

print ("\n\nTemplate file check ...\n");
foreach $filename
(
"$chatdir$tmpldir$loginform",
"$chatdir$tmpldir$admloginform",
"$chatdir$tmpldir$errfile","$chatdir$tmpldir$listfile",
"$chatdir$tmpldir$welfile","$chatdir$tmpldir$exitfile",
"$chatdir$tmpldir$tmplPublic","$chatdir$tmpldir$tmplPrivate",
"$chatdir$tmpldir$tmplFromMe","$chatdir$tmpldir$tmplSystem",
"$chatdir$tmpldir$tmplPublicOld","$chatdir$tmpldir$tmplPrivateOld",
"$chatdir$tmpldir$tmplFromMeOld","$chatdir$tmpldir$tmplSystemOld",
"$chatdir$tmpldir$leaveroom",
"$chatdir$tmpldir$enterroom",
"$chatdir$tmpldir$admret",
"$chatdir$tmpldir$logoutmsg","$chatdir$tmpldir$loginmsg",
"$chatdir$tmpldir$timeclose",
)
{
  &fileExist("$filename",'Yes',"No\n$filename template file does not exist. Check include.pl file for template settings or create a new template.\n");
};

print ("\n\nCheck user fields ...\n");
foreach $field ('nick','passwd') {
@test1 = grep ("$_" eq "$field",@fieldList); 
if ( ! scalar( @test1 ) ) {
	print("\n\'$field\' field is required in \@fieldList setting.\nCheck you include.pl file.\n");
	exit(0);
};
};

print ("\nCheck dummy files ...\n\n");
$dummy = 'dummyfile';
foreach $dirName ("$chatdir$userdir","$chatdir$logdir","$chatdir$mesgdir",
"$chatdir$laction","$chatdir$banip","$chatdir$banhost","$chatdir$bannick",
"$chatdir$bandom") 
{ print("Did you delete it in $dirName directory ? ");
	if ( -e "$dirName$dummy" ) {
		print ("No !\nYou must delete all \"dummyfile\" files in ChatMachine directories !\n");	
		exit(0);
	}; 
print("Yes\n");
};

print("\nCheck message handler settings...");
if (($mesgLimit > $oldLimit) && ($oldLimit >= 0))
	{ print(" Ok\n"); } else
	{ print(" No ! \n\$mesgLimit setting must be greater than \$oldLimit setting.\n"); 
	  print("\$oldLimit setting must be a positive integer (0 included).\n"); 
	  exit(0);
	};

print("\ninclude.pl file is OK.\nThis script does not check \$scriptUrl and \$htmlUrl settings. \nIf links to images are broken or your browser does not find ChatMachine\nscripts, check these settings.\n"); 
print("\nWARNING:\nChatMachine scripts require to CHMOD to 777 these directories :\n\n");
foreach $dirName ("$chatdir$userdir","$chatdir$logdir","$chatdir$mesgdir",
"$chatdir$laction","$chatdir$admdat","$chatdir$banip","$chatdir$banhost","$chatdir$bannick",
"$chatdir$bandom","$chatdir$roomdir","$chatdir$mldir") 
{ print("$dirName\n"); };
print("\nSet directory permission properly, (you can use \"install.sh\" script) or \nchange running USER/GROUP of your httpd process.\n");
print("To know if you need this, try login in chat. \nIf a \"FILE OPENING\" or a \"FILE LOCKING\" error occurs, you must change something.\n");
exit(0);

########################################################################
# scriptTest $_[0] filename
#########################################################################
sub scriptTest {
	if (! open (FH,"$_[0]") ) {
		print ("\n$_[0] file open failed. Check permission of file.\n");
		exit(0);
	};
	if ( eof(FH) ) {
		print ("\n$_[0] file empty !! Install ChatMachin package again !\n");
		exit(0);
	};
	$firstLine = <FH>;
	close(FH);
	chop $firstLine;
	$perlBin = substr ("$firstLine",2,length("$firstLine"));
	if (! ($firstLine =~ /^\#!/ ) ) {
		print("\n\nFirst line of \'$_[0]\' script is :\n$firstLine\n");
		print("This line is wrong, because it must be something like :\n"); 	 
		print("#!/usr/bin/perl\n");
		print("Remove all blank line before this or edit \'$_[0]\' file properly.\n");
		exit(0);
	};
	if (! -e $perlBin ) {
		print("\n\n\'$perlBin\' file does not exist. Find perl binary file (\'perl\')\n");
		print("and edit first line of \'$_[0]\' script.\n");
		exit(0);
	};

};
#########################################################################
# $_[0] default $_[1] abort
#########################################################################
sub waitKey {

while (1) {	
	$response = <STDIN>;
	chop $response;
	if (( ("\U$response\E") eq $_[0] ) || ( $response eq '')) 
		{  return ( '1' ); }
	elsif ( ("\U$response\E") eq $_[1] ) 
		{  return ( '0' ); };
	print("\nInvalid input, try again please :"); 
};
};		

######################################################################
# fileExist $_[0] nomefile $_[1] ok string $_[2] no string
#####################################################################

sub fileExist {

print ("\n-> Does $_[0] file exist ...");
if ( -e "$_[0]" ) { print ("$_[1]"); }
   else { print ("$_[2]"); exit(0); };

};
######################################################################
# dirExist $_[0] dir $_[1] ok string $_[2] no string
#####################################################################

sub dirExist {

print ("\n-> Does $_[0] directory exist ...");
if ( -d "$_[0]" ) { print ("$_[1]"); }
   else { print ("$_[2]"); exit(0); };

};

