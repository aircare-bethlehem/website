#!/usr/bin/perl
################################################################
# File name :	include.pl
# Description :	Configuration file.
# Author :	Nardone Vittorio (nards@iol.it)
################################################################
#########################################################################
# 	DON'T EDIT SCRIPT CODE ! COPYRIGHT 1997 VITTORIO NARDONE        #
# 		YOU CAN ONLY EDIT "INCLUDE.PL" (THIS) FILE !            #
# 			ALL RIGHTS RESERVED                             #
#########################################################################

############################# REQUIRED SETTINGS ###########################

# ChatMachine main directory (cgi-bin)
$chatdir = '/home/web/g/garcia.packetpushers.com/cgi-bin/chatm/';

# Complete URL to chat scripts (without script names)
# WARNING : remember to NOT use final "/" !
#
# An example : 
#	$scriptUrl = "http://www.myserver.com/cgi-bin";
# ..then ChatMachine "login.pl" script URL is :
#	"http://www.myserver.com/cgi-bin/login.pl"
#
# This setting is used to replace "#script_url" command in templates.
$scriptUrl = "http://garcia.packetpushers.com/cgi-bin/chatm";
  
# Complete URL to HTML resources of ChatMachine package (images).
# WARNING : remember to NOT use final "/" !
#
# This setting is used to replace "#html_url" command in templates.
$htmlUrl = "http://garcia.packetpushers.com/images/chatm";


############################### DIRECTORY ###################################


# User information directory
$userdir = 'users/';

# Logged users
$logdir = 'logged/';

# Message directory
$mesgdir = 'mesg/';

# Template directory
$tmpldir = 'template/';

# Last action directory 
$laction = 'laction/';

############################### TEMPLATE #################################


# Login form template (used by login.pl script if called without commands)
$loginform = 'loginform.tmpl';

# Adm Login form template (used by adm.pl script if called without commands)
$admloginform = 'admlogin.tmpl';

# Error template
$errfile = 'errfile.tmpl';

# User list template for Welcome page (replace #userlist command)
$listfile = 'listfile.tmpl';

# User list templates for chatting pages (replace #loglistNN commands)
# These templates are usefull to list logged users. 
# Template filename prefix :
$logpre = 'loglist';

# User chat template prefix
# An example :
#		If "tmpl" CGI value is '02' and $chatpre is 'chat_user', "chat_user02.tmpl" 
#		template file is used to display chat page.
$chatpre = 'chat_user';

# Staff chat template prefix
# Like "$chatpre", but for staff members.
$admchatpre = 'chat_staff';

# Welcome template
$welfile = 'welfile.tmpl';
# Exit template
$exitfile = 'exitfile.tmpl';

# Public message template
$tmplPublic = 'mesgpublic.tmpl';
# Private message template 
$tmplPrivate = 'mesgprivate.tmpl';
# "From me" message template 
$tmplFromMe = 'mesgfromme.tmpl';
# System message template 
$tmplSystem = 'mesgsystem.tmpl'; 

# Old Public message template 
$tmplPublicOld = 'mesgpub_old.tmpl';
# Old Private message template 
$tmplPrivateOld = 'mesgpri_old.tmpl'; 
# Old "From me" message template 
$tmplFromMeOld = 'mesgfro_old.tmpl'; 
# Old System message template 
$tmplSystemOld = 'mesgsys_old.tmpl'; 


########################################################################################
# ROOM SETTINGS
########################################################################################

# Room list template prefix
$roompre = 'roomlst';

# Room configuration directory 
$roomdir = 'system/room/'; 

# When a user change room, the $leaveroom message template is sent to all user of old room
# and $enterroom message template is sent to all user of new room.
$leaveroom = 'leaveroom.tmpl';
$enterroom = 'enterroom.tmpl';

#########################################################################################
# CHATMACHINE CONTROL CENTER SETTINGS 
#########################################################################################

# Chat administrators (staff members)
@admName = ('admin');

# Administrator template prefix
$admpre = 'admtmpl';

# Logged user list template prefix 
# Example : 
# 	if $admlogpre is 'dummy', command #loglist05 is replaced with logged user list
#	using template "dummy05.tmpl". Default is 'admlog'.
$admlogpre = 'admlog';


# Account list template prefix
# Example : 
# 	if $admuserpre is 'dummy', command #userlist05 is replaced with complete account
#       list using template "dummy05.tmpl". Default is 'admacc'.
$admuserpre = 'admacc';


# Banned list template prefix ...
# Example : 
# 	if $admhostpre is 'dummy', command #bh_list05 is replaced with banned host list
#       using template "dummy05.tmpl". Default is 'admbhost'.

# .. for hosts
$admhostpre = 'admbhost';
# .. for IPs
$admippre = 'admbip';
# .. for domains
$admdompre = 'admbdom';
# .. for nicknames
$admnickpre = 'admbnick';

# Administration-Banned directory
$admdat = 'system/';
$banip = 'system/ip/';
$banhost = 'system/host/';
$bannick = 'system/nick/';
$bandom = 'system/domain/';

# Staff ret template 
$admret = 'admret.tmpl';

# Logout message template
$logoutmsg = 'logoutmsg.tmpl';
# Login message template
$loginmsg = 'loginmsg.tmpl';

# Daemon configuration file
$daemonCfg = 'daemon.cfg';

# User number limit
$userLimit = '30';	

############################### MISC ##################################

# User fields.
# WARNING : "nick" and "passwd" fields are required !
#	    "lastlogin" and "hostname" are not required, but used by ChatMachine
#	    scripts.
# IF YOU CHANGE USER FIELDS, DELETE ALL USER INFORMATIONS IN $userdir BECAUSE
# OLD USER FILES WILL NOT BE IN THE SAME FORMAT !
@fieldList =('nick','passwd','name','lastname','email','lastlogin','hostname','ipadd');

# Required field (login)
# You can force a field to be required. "nick" and "passwd" field are already required
# and don't include them in this list
#
# For example : to require email address uncomment next line.
# @required = ('email');

# User field default.
# Apply a default value to a user field, if it's empty (at login)
# WARNING : You can set a default value (null string is ok) for each field
# in @fieldList. Set also $applyDefault below.
$defValue{'name'} = 'default value';
# ...

# Apply defaults ?  1 - Yes,  0 - No
$applyDefault = '0';

# Automatic message sender (nickname)
$sysName = 'CHAT ADMIN';
# Public message destination string
$allStr = 'EVERYBODY';

# Month names.
@months = ("January","February","March","April","May","June","July",
	     "August","September","October","November","December");


##########################################################################
# HTML TAG SETTINGS
##########################################################################

# Allow HTML tags in messages. 
#	$noHTML = '2' # Only tags in @allowHTML setting are allowed
# 	$noHTML = '1' # HTML tags are ignored
# 	$noHTML = '0' # HTML tags are allowed
$noHTML = '2';

# Only if $noHTML setting is '2' :
@allowHTML = ('b','font','i','a','tt');	# Tags to preserve
$autoclose = '1';	# Auto close (</tag>) open tags in messages. '1' is yes, '0' is no.

# Define max length ..
$nickLen = '20';	# ..for nicknames.
$messLen = '500'; 	# ..for messages.

#Message handler settings : 
#	$mesgLimit -> Max number of messages to display 
#                     (old messages included)
#	$oldLimit  -> Max number of readed messages to preserve
#	$mesgOrder -> '1' means NEW messages first
#                     '0' means OLD messages first
$mesgLimit = '16'; 
$oldLimit = '5';
$mesgOrder = '1';

#Auto-Include yourself in private messages : 
#	1, Yes : You can read private messages sent by you, also if you
#		 are not in destination list. 
#	0, No  : If you send a private message and you are not in
#		 destination list, you are not be able to read it. 
$autoPrivate = '1';

#File locking setting (change this if a "file locking" error occurs)
#	$flockMode -> '0' no file locking (DANGEROUS)
#		      '1' ChatMachine built-in file locking
$flockMode = '1';	 

################################################################################
# Time settings
###############################################################################

# Time adjusting (hours) : valid range -12 .. +12 
$timeAdjust = +0;

# Chat open at time : 

$applyTControl = '0'; # Time control enable = '1', disable = '0'

@timeControl = (      # Only if $applyTControl is '1'
		      # First column is 0-1 AM
		      # Last column is 11-12 PM
		      # 1 is Chat Open - 0 is Chat Closed
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, # Sunday
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1, # Monday
			1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, # ..
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, # ..
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, # ..
			0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1, # ..
			1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0  # Saturday
); 

# Chat time closed template :
$timeclose="timeclose.tmpl";


####################################################################################
# Public Message logging settings 
####################################################################################
# This is a beta feature of ChatMachine 98. Please see online FAQ section.
#

$mldir = 'system/mesglog/';	# Message Queue directory 
$logindex = 'index';		# Index filename
$mlpre = 'ml';			# Queue filename prefix

$mltop = 5;			# Queue lenght (number of messages to log) 

$mlsystem = 0;			# Log system messages ( Yes is 1, No is 0) 

$mltime = 5;			# Max time (in minutes) of logged messages (before deleting)  

###################################################################################

#END : "$endfile" must be last setting in 'include.pl' file.
#Don't edit this setting and don't comment it !!
$endfile = '1'; # <- Last setting, don't edit or comment it.
