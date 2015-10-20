#!/usr/bin/perl
################################################################
# File name :	adm.pl
# Description : Administration script.
# Author :	Nardone Vittorio (nards@iol.it)
################################################################
#########################################################################
# 	DON'T EDIT SCRIPT CODE ! COPYRIGHT 1997 VITTORIO NARDONE        #
# 		YOU CAN ONLY EDIT "INCLUDE.PL" FILE !                   #
# 			ALL RIGHTS RESERVED                             #
#########################################################################

print("Content-type: text/html\n\n");
if (! do 'include.pl' ) {
	print('<HTML><BODY>');
	print ("\'include.pl\' file execution failed ! <BR> Check \'include.pl\' file for syntax errors (try : perl -d include.pl).");
	print('</BODY></HTML>');
	exit(0);
};

################################################################
######################  GLOBAL VAR HERE ########################
################################################################
$ERRORMSG = '';		# Corrente o ultimo messaggio di errore.
$VERSION = 'First 98';  # Versione dello script
$LOCKFILE = '2';	# IOCTL - Lock file
$UNLOCKFILE = '8';	# IOCTL - Unlock file
$lockLimit = '60';	# Time before lock skip
################################################################
######################  CODE START HERE  #######################
################################################################

&readRoomFile;

&startDaemon;

&getData;

# Controllo della presenza di tutti i campi del form
if ( (! $cgiVals{"nick"}) || (! $cgiVals{"passwd"}) || 
     (! $cgiVals{"cmd"}) || (! $cgiVals{"tmpl"}) ) {	
	&error ("Invalid data form.");
	exit(0); 
};

# Verifica che l'utente sia un amministratore di chat
if (! (grep ( $_ eq $cgiVals{'nick'}, @admName)) ) {
	&error ("You must be a Staff member to use this script.");
	exit(0);
};

# Verifica l'esistenza del proprio user-file e leggilo
if ( -e "$chatdir$userdir$cgiVals{'nick'}" ) {
	&readUsrData("$chatdir$userdir$cgiVals{'nick'}");
} else {
	&error ("Staff members must be chat users. Login in chat and try again.");
	exit(0);
};

# Verifica correttezza password 
$cgiVals{'room'} = &getRoom("$cgiVals{'nick'}");
if ( -e "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}" ) {
	$mesgpasswd = &readPasswd("$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}"); 
} else { $mesgpasswd = ''; };
$logpasswd = $fileData{'passwd'};

if ($cgiVals{'passwd'} eq $mesgpasswd) { $passwd = $mesgpasswd; }
   elsif ($cgiVals{'passwd'} eq $logpasswd) {
	if ($mesgpasswd ne '') { $passwd = $mesgpasswd; }
	else { $passwd = $logpasswd; };
   } else { &error ("Wrong password."); exit(0); };

# Creazione file lastaction (utilizzata dal demone chatd per la 
# determinazione degli utenti idle)
if ( -e "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}" ) {
	&openUsrFile("> $chatdir$laction$cgiVals{'nick'}");
	print(USERFILE "$time");
	&closeUsrFile;
};

# Esecuzione comando indicato
if ($cgiVals{'cmd'} eq 'kick') { &kick; } elsif
   ($cgiVals{'cmd'} eq 'banIP') { &ban("$banip",'ipadd','IP-address'); } elsif
   ($cgiVals{'cmd'} eq 'banNick') { &ban("$bannick",'nick','Nickname'); } elsif
   ($cgiVals{'cmd'} eq 'banHost') { &ban("$banhost",'hostname','Hostname'); } elsif
   ($cgiVals{'cmd'} eq 'banDomain') { &banDomain; } elsif
   ($cgiVals{'cmd'} eq 'ubanHost') { &uban("$banhost",'Hostname'); } elsif 
   ($cgiVals{'cmd'} eq 'ubanNick') { &uban("$bannick",'Nickname'); } elsif 
   ($cgiVals{'cmd'} eq 'ubanIP') { &uban("$banip",'IP-address'); } elsif 
   ($cgiVals{'cmd'} eq 'ubanDomain') { &uban("$bandom",'Domain'); } elsif
   ($cgiVals{'cmd'} eq 'sendMsg') { &sendsysmsg; } elsif
   ($cgiVals{'cmd'} eq 'newUser') { &newuser; } elsif
   ($cgiVals{'cmd'} eq 'delUser') { &deluser; } elsif
   ($cgiVals{'cmd'} eq 'newRoom') { &newroom; } elsif
   ($cgiVals{'cmd'} eq 'delRoom') { &delroom; } elsif
   ($cgiVals{'cmd'} eq 'setLogin') { &setlogin; } elsif
   ($cgiVals{'cmd'} eq 'setDaemon') { &setdaemon; } elsif
   ($cgiVals{'cmd'} eq 'kickAll') { &kickall; };


&menu;

exit(0);

####################################################################
# Procedura di visualizzazione del menu
####################################################################
sub menu {
	if ( ! open(MENUTMPL,"$chatdir$tmpldir$admpre$cgiVals{'tmpl'}.tmpl") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$admpre$cgiVals{'tmpl'}.tmpl file not found]"); 
	} else { 
		while (! eof (MENUTMPL) ) {
			$line = <MENUTMPL>;
			$line = &parseMenu($line);
			print ($line);
		};			
		close(MENUTMPL); 
	};
};

sub parseMenu {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ( $fieldname eq 'passwd' ) { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	$ret =~ s/#%passwd/$passwd/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#result/$banResult/g;
	$ret =~ s/#now/$time/g;

	# Tipo di login
	$login1 = 'logintype1'; $log1str = 'Chat is reserved to registered users';
	$login2 = 'logintype2'; $log2str = 'Chat is closed'; $log0str = 'Chat is open';
	if ( -e "$chatdir$admdat$login2" ) { $ret =~ s/#login_type/$log2str/g; }
	elsif ( -e "$chatdir$admdat$login1" ) { $ret =~ s/#login_type/$log1str/g; }
	else { $ret =~ s/#login_type/$log0str/g; };

	# Demone
	if ($autoLogout) { $daemon = 'Enable'; } else { $daemon = 'Disable'; };
	$ret =~ s/#daemon/$daemon/g; 
	$ret =~ s/#timelimit/$timeLimit/g; 
	
	# Check loglist
	if ( $ret =~ /(#loglist){1}(\d\d){1}/ ) {
		$dummy = &userList("$ret","$&","$chatdir$tmpldir$admlogpre$2.tmpl",1);
		$ret = $dummy;
	};
	# Check userlist
	if ( $ret =~ /(#userlist){1}(\d\d){1}/ ) {
		$dummy = &userList("$ret","$&","$chatdir$tmpldir$admuserpre$2.tmpl",0);
		$ret = $dummy;
	};
	if ( $ret =~ /#chat/ ) {
		$dummy = &chatRet("$ret");
		$ret = $dummy;
	};
	if ( $ret =~ /(#bh_list){1}(\d\d){1}/ ) {
		$dummy = &banList("$banhost","$admhostpre$2.tmpl");
		$ret =~ s/(#bh_list){1}(\d\d){1}/$dummy/g;
	};
	if ( $ret =~ /(#bd_list){1}(\d\d){1}/ ) {
		$dummy = &banList("$bandom","$admdompre$2.tmpl");
		$ret =~ s/(#bd_list){1}(\d\d){1}/$dummy/g;
	};
	if ( $ret =~ /(#bi_list){1}(\d\d){1}/ ) {
		$dummy = &banList("$banip","$admippre$2.tmpl");
		$ret =~ s/(#bi_list){1}(\d\d){1}/$dummy/g;
	};
	if ( $ret =~ /(#bn_list){1}(\d\d){1}/ ) {
		$dummy = &banList("$bannick","$admnickpre$2.tmpl");
		$ret =~ s/(#bn_list){1}(\d\d){1}/$dummy/g;
	};
	if ( $ret =~ /#count/ ) {
		&logUser;
		$ret =~ s/#count/$howMany/g;
	};

	if ( $ret =~ /#rcount/ ) {
		&roomUser("$cgiVals{'room'}");
		$ret =~ s/#rcount/$howRoom/g;
	};
	
	# Check room_list
	if ( $ret =~ /(#roomlist){1}(\d\d){1}/ ) {
		$dummy = &roomList("$ret","$&","$2");
		$ret = $dummy;
	};

	return ( "$ret" );
};

sub chatRet {
	$toReturn = $_[0];
	if ( -e "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}" ) {
		if ( open(RETLINK,"$chatdir$tmpldir$admret") ) {
			while ( ! eof RETLINK ) {
				$retLine = <RETLINK>;
				$retLine =~ s/#%nick/$cgiVals{'nick'}/g;
				$retLine =~ s/#%passwd/$passwd/g;
				$retLine =~ s/#room/$cgiVals{'room'}/g;
				$retLine =~ s/#script_url/$scriptUrl/g;
				$retLine =~ s/#html_url/$htmlUrl/g;	
				$retLine =~ s/#now/$time/g;
				$retString = "$retString$retLine";
			};
		 	close(RETLINK);
		} else {
			&error("[CONFIG ERROR : $chatdir$tmpldir$admret file not found.]");
			exit(0);
		};
		$toReturn =~ s/#chat/$retString/g;
	} else {
		$toReturn =~ s/#chat//g;
	};
	return ( "$toReturn" );	
};

####################################################################
# Set Login type
####################################################################
sub setlogin {
	$login1 = 'logintype1';
	$login2 = 'logintype2';
	if ( $cgiVals{'logintype'} eq '0' ) {
		unlink("$chatdir$admdat$login1"); 
		unlink("$chatdir$admdat$login2"); 
	} elsif ( $cgiVals{'logintype'} eq '1' ) {
		unlink("$chatdir$admdat$login2");
		if ( open (LOGINFILE, "> $chatdir$admdat$login1") ) {
			close(LOGINFILE);
		} else { 
			&error("[RUNTIME ERROR : $chatdir$admdat$login1 file creation error.]");
			exit(0);
		};
	} elsif ( $cgiVals{'logintype'} eq '2' ) {
		unlink("$chatdir$admdat$login1");
		if ( open (LOGINFILE, "> $chatdir$admdat$login2") ) {
			close(LOGINFILE);
		} else { 
			&error("[RUNTIME ERROR : $chatdir$admdat$login2 file creation error.]");
			exit(0);
		};
	};
};


######################################################################
# Set Daemon Configuration
######################################################################
sub setdaemon {
	if ((($cgiVals{'active'} eq '0') || ($cgiVals{'active'} eq '1')) &&
		($cgiVals{'time'})) {
		&openUsrFile("> $chatdir$admdat$daemonCfg");
		print (USERFILE "$cgiVals{'active'}\n");	
		print (USERFILE "$cgiVals{'time'}\n");	
		&closeUsrFile;
		$autoLogout = $cgiVals{'active'};
		$timeLimit = $cgiVals{'time'};
	};
};

#####################################################################
# Get Room list
#####################################################################
sub readRoomFile {
	if ( opendir (ROOMLIST,"$chatdir$roomdir") ) {
		@rooms = readdir (ROOMLIST);
		closedir (ROOMLIST);
		@rooms = grep ( ("$_" ne '.htaccess') && ($_ ne '.') && ($_ ne '..') && (!( /~/ )), @rooms);
		@rooms = sort @rooms;
	} else { 
		&error("[CONFIG ERROR: Can not find $chatdir$roomdir directory.]"); 
		exit(0);
	};
};

#####################################################################
# Subroutine di visualizzazione form di login (quando lo script
# viene richiamato senza parametri)
#####################################################################
sub viewLoginForm {
	if ( ! open(ADMLOGINFORM,"$chatdir$tmpldir$admloginform") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$admloginform file not found]"); 
	} else { 
		while (! eof (ADMLOGINFORM) ) {
			$line = <ADMLOGINFORM>;
			$line = &parseLoginForm($line);
			print ($line);
		};			
		close(ADMLOGINFORM);
		exit(0); 
	};
};

sub parseLoginForm {
	$ret = $_[0];
	$ret =~ s/#now/$time/g;
	$ret =~ s/#date/&vDate($time)/ge;	
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;
	return ( "$ret" );
};



####################################################################
# Ban Domain
####################################################################
sub banDomain {
	if ($cgiVals{'domain'}) {
		if ( open (BANFILE,"> $chatdir$bandom$cgiVals{'domain'}") ) {
			close(BANFILE);
			$banResult = "$banResult Domain &quot;$cgiVals{'domain'}&quot; banned.<BR>"; 
		} else {
			&error("[RUNTIME ERROR : $chatdir$bandom$cgiVals{'domain'} file creation error.]");
			exit(0);
		};
	};	
};

####################################################################
# Kick off (except administrator)
####################################################################
sub kick {
	&logUser;
	foreach $whoWhere (@logged) {
		($who,$where) = split ('\.',"$whoWhere",2);
		if ( ( ! grep ($_ eq $who,@admName) ) &&
		     ( $cgiVals{"$who"} eq 'on' ) ) { 
			&readData("$chatdir$userdir$who");
			&logout("$who","$where"); 
		};	
	};
};

########################################################################
# Kickoff all user (except administrator)
#######################################################################
sub kickall {
	&logUser;
	foreach $whoWhere (@logged) {
		($who,$where) = split ('\.',"$whoWhere",2);
		if ( ! grep ($_ eq $who,@admName) ) {
			&readData("$chatdir$userdir$who");
			&logout("$who","$where"); 
		};	
	};
};

########################################################################
# Create a room
########################################################################
sub newroom {
	if ( $cgiVals{'roomname'} ) {
		$cgiVals{'roomname'} =~ s/[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-]//g; 
		if ( ! grep ($_ eq $cgiVals{'roomname'},@rooms) ) {
			   open (ROOMFILE, "> $chatdir$roomdir$cgiVals{'roomname'}");
			   close(ROOMFILE);
			   open (ROOMFILE, "> $chatdir$mldir$logindex.$cgiVals{'roomname'}");
			   print (ROOMFILE 1);
			   close(ROOMFILE);
			   	
			   &readRoomFile;
		};
	};
};

########################################################################
# Delete a room
########################################################################
sub delroom {
	&logUser;
	$noAdm = '1';
	foreach $whoWhere (@logged) {
		($who,$where) = split ('\.',"$whoWhere",2);
		if ( $where eq $cgiVals{'roomname'}) {
			if (grep ($_ eq $who, @admName)) { $noAdm = '0'; } 
			else { push (@tokick, $whoWhere); };
		};
	};
	if ($noAdm) {
		foreach $whoWhere (@tokick) {
		($who,$where) = split ('\.',"$whoWhere",2);
			&readData("$chatdir$userdir$who");
			&logout("$who","$where"); 
		};	 
		unlink "$chatdir$roomdir$cgiVals{'roomname'}";
		unlink "$chatdir$mldir$logindex.$cgiVals{'roomname'}";
		if ( opendir (QUEUELIST,"$chatdir$mldir") ) {
			@queue = readdir (QUEUELIST);
			closedir (QUEUELIST);
			@queue = grep ( /(\w)+\.$cgiVals{'roomname'}/ , @queue);
			foreach $todelete (@queue) { unlink "$chatdir$mldir$todelete"; };
		};
		&readRoomFile;
	};
};


#########################################################################
# Userfile creation
#########################################################################
sub newuser {
	$cgiVals{'_nick'} =~ s/[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-]//g; 
	if ((! $cgiVals{'_nick'}) || (! $cgiVals{'_passwd'})) {
		&error("Nickname and password required to create a new userfile.");
		exit(0);
	} else {
		if (length($cgiVals{'_nick'}) > "$nickLen") 
			{ $cgiVals{'_nick'} = substr("$cgiVals{'_nick'}",0,"$nickLen"); };
		&openUsrFile("> $chatdir$userdir$cgiVals{'_nick'}");
		foreach $fieldname (@fieldList) {
			if (! print(USERFILE $cgiVals{"_$fieldname"},"\n")) {
				print("[RUNTIME ERROR : user file writing error]");
				&closeUsrFile;
				exit(0);
			};
		};
		&closeUsrFile;
	};
};


#########################################################################
# Del user
#########################################################################
sub deluser {
	&kick;
	&accountList;
	foreach $whoWhere (@account) {
		($who,$where) = split ('\.',"$whoWhere",2);
		if ( ( ! grep ($_ eq $who,@admName) ) &&
		     ( $cgiVals{"$who"} eq 'on' ) ) { 
			unlink "$chatdir$userdir$who";
		};	
	};
		
};

########################################################################
# Ban (except administrator)
########################################################################
sub ban {
	&accountList;
	foreach $userFull (@account) {
		($userNick,$userRoom) = split ('\.',"$userFull",2);
		if ( grep ($_ eq $userNick,@admName) ){ next; };
		if ( $cgiVals{"$userNick"} eq 'on' ) {
			&readData("$chatdir$userdir$userNick");
			$dummy = $userData{"$_[1]"};
			if ( open (BANFILE,"> $chatdir$_[0]$dummy") ) {
				close(BANFILE);
				$banResult = "$banResult $_[2] &quot;$dummy&quot; banned.<BR>"; 
			} else {
				&error("[RUNTIME ERROR : $chatdir$_[0]$dummy file creation error.]");
				exit(0);
			};
		};	
	};
};

################################################################
# Procedura di logout dalla chat $_[0]=nick $_[1]=room 
################################################################
sub logout {
	unlink "$chatdir$logdir$_[0].$_[1]";
	unlink "$chatdir$mesgdir$_[0]";
	unlink "$chatdir$laction$_[0]";
	&sendLogout("$_[0]","$_[1]");
	$banResult = "$banResult &quot;$_[0]&quot; is logged out.<BR>"; 
};

########################################################################
# Spedizione del messaggio di logout a tutti gli utenti collegati
# $_[0] nick $_[1] room
########################################################################
sub sendLogout {
	$nickName = $_[0];
	$room = $_[1];
	opendir(LOGDIR,"$chatdir$logdir");
	@dest = readdir(LOGDIR);
	closedir(LOGDIR);
	@dest = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @dest);
	@dest = grep ( (!( /~/ )), @dest);
	if (! open(LOGMSG,"$chatdir$tmpldir$logoutmsg") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$logoutmsg file not found]"); 
		exit(0);
	};
	@mesg = <LOGMSG>;
	close(LOGMSG);
	$message = '';
	foreach $mesgLine (@mesg) {
		$mesgLine = &parseLogout($mesgLine);
		$message = "$message$mesgLine";
	};	
	$mesgLen = length($message) + '1';
	foreach $destFull (@dest) {
		($destNick,$destRoom) = split ('\.',"$destFull",2);
		if ( $destRoom ne $room ) { next; };
		if ( $flockMode ) {
			&cm_lock("$chatdir$mesgdir$destNick");
		};
		if ( open(MESGFILE, ">> $chatdir$mesgdir$destNick") ) {
			print(MESGFILE "$time\n");
			print(MESGFILE "$sysName\n");
			print(MESGFILE "$mesgLen\n");
			print(MESGFILE "$message\n");
			close(MESGFILE);
		};
		if ( $flockMode ) {
			&cm_unlock("$chatdir$mesgdir$destNick");
		};
	};

	if ($mlsystem) { &mesgLogUpdate("$time","$sysName","$mesgLen","$message","$room"); };
};

sub parseLogout {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$userData{"$fieldname"}/g;
	};
	return ( $ret );		
};


###############################################################
# Send system message
###############################################################
sub sendsysmsg {
	if ( ! $cgiVals{'message'} ) {
		&error ("Message text missing.");
	} else {
		opendir(MESGDIR,"$chatdir$mesgdir");
		@dest = readdir(MESGDIR);
		closedir(MESGDIR);
		@dest = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @dest);
		@dest = grep ( (!( /~/ )), @dest);
		$mesgLen = length($cgiVals{'message'}) + '1';
		foreach $destFull (@dest) {
			($destNick,$destRoom) = split ('\.',"$destFull",2);
			if ( $flockMode ) {
				&cm_lock("$chatdir$mesgdir$destNick");
			};
			if ( open(MESGFILE, ">> $chatdir$mesgdir$destNick") ) {
				print(MESGFILE "$time\n");
				print(MESGFILE "$sysName\n");
				print(MESGFILE "$mesgLen\n");
				print(MESGFILE "$cgiVals{'message'}\n");
				close(MESGFILE);
			};
			if ( $flockMode ) {
				&cm_unlock("$chatdir$mesgdir$destNick");
			};
		};
		if ($mlsystem) {
			foreach $whichRoom (@rooms) {
				&mesgLogUpdate("$time","$sysName","$mesgLen","$cgiVals{'message'}","$whichRoom");
			}; 
		};
	};
};

################################################################
# Lettura della passwd messaggi di un utente
################################################################
sub readPasswd {
	if ( $flockMode ) {
		&cm_lock("$_[0]");
	};
	if ( open(PASSWD,"$_[0]") ) {
		if ( ! eof(PASSWD) ) {
			$ret = <PASSWD>;
		} else {
			&error ("You are not logged in chat, try login again.");
			close(PASSWD);
			exit(0);
		};
		close(PASSWD);
	} else {
		&error ("You are not logged in chat, try login again.");
		exit(0);
	};
	if ( $flockMode ) {
		&cm_unlock("$_[0]");
	};
	return ( $ret );
};	

################################################################
# Operazioni (aperture, chiusura, lock) su file (generico)
# Parametri : [ [0] nome file ]
################################################################

sub openUsrFile {  
	$hiddenUsrFile = "$_[0]";
	if ( $flockMode ) {
		&cm_lock("$_[0]");
	};
	if (! open(USERFILE,"$_[0]")) {
		print("[RUNTIME ERROR : $_[0] file opening error.]");
		exit(0);
	};
};

sub closeUsrFile {
	close(USERFILE);
	if ( $flockMode ) {
		&cm_unlock("$hiddenUsrFile");
	};
};


################################################################
# Operazioni sul file utente
# Parametri : [0] nome file
################################################################

sub readUsrData {
	&openUsrFile($_[0]);
	foreach $fieldname (@fieldList) {
		if (! eof (USERFILE)) {
			$fileData{"$fieldname"} = <USERFILE>;
			chop($fileData{"$fieldname"});
		} else {
			print("[RUNTIME ERROR : invalid user file.]");
			$fileData{"$fieldname"} = ' ';
		};	
	};
	&closeUsrFile;
};

################################################################
# Subroutine lettura dati dal browser
# Funziona sia con il metodo GET che con il POST
################################################################

sub getData {     
	if ($ENV{'REQUEST_METHOD'} eq 'GET') {
		@cgiPairs = split("&",$ENV{'QUERY_STRING'});
	} else {
		$querystr = <STDIN>;
		
		# Presunta incompatibilita' fra APACHE e NCSA, sembra che
		# APACHE non metta \r\n al termine della query string con
		# il metodo POST, mentre NCSA si !
	     	if ( $querystr =~ /$\\r\n/ ) {
			chop $querystr;
			chop $querystr;
		};
		@cgiPairs = split("&",$querystr);
	};

	# Imposta ora attuale
	$time = time;

	if (scalar (@cgiPairs) == 0) { &viewLoginForm; };

	foreach $pair ( @cgiPairs ) {
                ($var,$val) = split("=",$pair);
                $val =~ s/\+/ /g;
                $val =~ s/%(..)/pack("c",hex($1))/ge;
                $cgiVals{"$var"} = "$val";
        }

};

#################################################################
# Costruisce la lista degli utenti presenti in chat.
#################################################################
sub logUser {
	opendir(LOGDIR,"$chatdir$logdir");
	@logged = readdir(LOGDIR);
	closedir(LOGDIR);
	@logged = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @logged);
	@logged = grep ( (!( /~/ )), @logged);
	$howMany = scalar(@logged);
};

####################################################################
# Conta gli utenti di una stanza $_[0] -> $howRoom
###################################################################
sub roomUser {
	&logUser;
	$howRoom = 0;
	foreach $whoWhere (@logged) {
		($who,$where) = split ('\.',$whoWhere,2);
		if ($where eq $_[0]) { $howRoom++; };
	}; 
}



#################################################################
# Ritorna la stanza di un utente $_[0] = nick
#################################################################
sub getRoom {
	&logUser;
	foreach $whoWhere (@logged) {
		($who,$where) = split ('\.',$whoWhere,2);
		if ($who ne $_[0]) { next; };
		$target = $where;
	};
	return ( $target );
};

#################################################################
# Costruisce la lista degli utenti della chat (logged compresi).
#################################################################
sub accountList {
	opendir(USERDIR,"$chatdir$userdir");
	@account = readdir(USERDIR);
	closedir(USERDIR);
	@account = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @account);
	@account = grep ( (!( /~/ )), @account);
	$accountNumber = scalar(@account);
}

#################################################################
# Subroutine di segnalazione degli errori
# Parametri : ErrorMsg
#################################################################

sub error {
	$ERRORMSG = $_[0];
	if ( ! open(ERRTMPL,"$chatdir$tmpldir$errfile") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$errfile file not found]"); 
	} else { 
		while (! eof (ERRTMPL) ) {
			$line = <ERRTMPL>;
			$line = &parseErr($line);
			print ($line);
		};			
		close(ERRTMPL); 
	};
};

sub parseErr {
	$ret = $_[0];
	$ret =~ s/#now/$time/g;
	$ret =~ s/#%nick/$cgiVals{'nick'}/g;
	$ret =~ s/#error/$ERRORMSG/g;	
	$ret =~ s/#date/&vDate($time)/ge;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;	
	return ( "$ret" );
};

###############################################################################
# Procedura di elenco stanze e numero utenti presenti
##############################################################################
sub roomList {
	# Attenzione : solo il primo #roomlist della linea viene considerato
	($firstPart,$secondPart) = split ("$_[1]","$_[0]",2);
	$middlePart = '';	

	if ( ! open(ROOMTMPL,"$chatdir$tmpldir$roompre$_[2].tmpl") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$roompre$_[2].tmpl file not found]"); 
	} else { 
		@backTemplate = <ROOMTMPL>;
		close(ROOMTMPL);
	
		# Creazione lista
		foreach $roomName (@rooms) {
			@fullTemplate = @backTemplate;
			foreach $tmplLine (@fullTemplate) {
				$tmplLine =~ s/#adm_nick/$cgiVals{'nick'}/g;
				$tmplLine =~ s/#adm_passwd/$cgiVals{'passwd'}/g;
				$tmplLine =~ s/#html_url/$htmlUrl/g;
				$tmplLine =~ s/#script_url/$scriptUrl/g;
				$tmplLine =~ s/#room_name/$roomName/g;
				$tmplLine =~ s/#now/$time/g;
				if ( $tmplLine =~ /#room_users/ ) {
					&roomUser("$roomName");
					$tmplLine =~ s/#room_users/$howRoom/g;
				};
				$middlePart = "$middlePart$tmplLine";
			};
		};
	};
	return ("$firstPart$middlePart$secondPart");
};
	

################################################################
# Elenca utenti in chat utilizzando un template
# ATTENZIONE: in caso di template sofisticati, le dimensioni e la
# velocita' di sintesi delle pagine possono aumentare drasticamente,
# particolarmente in presenza di numerosi utenti.
# PROBABILE BUG : superamento lunghezza massima stringa ?
################################################################
sub userList {
	# Attenzione : solo il primo #command della linea viene considerato
	($firstPart,$secondPart) = split ("$_[1]","$_[0]",2);
	$middlePart = '';	
	
	if ( ! open(LISTTMPL,"$_[2]") ) {
		print("[CONFIG ERROR : $_[2] file not found]"); 
	} else { 
		@backTemplate = <LISTTMPL>;
		close(LISTTMPL);

		$nextFlag = '0';	
		
		# Utenti presenti o tutti gli utenti ?
		if ($_[3]) {	# Logged user
				&logUser;
				@userArray = @logged;
		} else { 	# Account list
				&accountList;
				@userArray = @account;
		};
	
		# Determinazione domini bannati.
		opendir(DOMDIR,"$chatdir$bandom");
		@domains = readdir(DOMDIR);
		closedir(DOMDIR);
		@domains = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')), @domains);
		@domains = grep ( (!( /~/ )) , @domains);

		# Ordinamento elementi
		@userArray = sort @userArray;
		
		# Creazione lista
USER:		foreach $userFull (@userArray) {
			($userNick,$userRoom) = split ('\.',"$userFull",2);
			&readData("$chatdir$userdir$userNick");

			$bdomstr = ''; 
			$bnickstr = ''; 
			$bipstr = ''; 
			$bhoststr = ''; 
			if ( -e "$chatdir$bannick$userData{'nick'}") 
				{ ( $bnickstr = 'Yes' ); };
			if (( -e "$chatdir$banip$userData{'ipadd'}") && ($userData{'ipadd'} ne '')) 
				{ ( $bipstr = 'Yes' ); };
			if (( -e "$chatdir$banhost$userData{'hostname'}") && ($userData{'hostname'} ne '')) 
				{ ( $bhoststr = 'Yes' ); };
			foreach $banned (@domains) {
				if ($banned) {
					if ( ( "$userData{'hostname'}" eq "$banned" ) ||
	     	   			   ( $userData{'hostname'} =~ /$\\.$banned/ ) ) { 
					     $bdomstr = 'Yes'; 
					};
				};
			};

			@fullTemplate = @backTemplate;
			$lineTotal = '0';
			foreach $tmplLine (@fullTemplate) {
				$lineTotal = $lineTotal + 1;
				if ("$nextFlag") {
					$lineCount = $lineCount - 1;
					if ("$lineCount") { next; };
					$nextFlag = '0';
				};	
				foreach $fieldname (@fieldList) {
					if ($fieldname eq 'passwd') { next; };	
					$tmplLine =~ s/#%$fieldname/$userData{"$fieldname"}/g;
				};
				$tmplLine =~ s/#idle/&getIdle("$userNick")/ge;
				$tmplLine =~ s/#room/&getRoom("$userNick")/ge;
				$tmplLine =~ s/#html_url/$htmlUrl/g;
				$tmplLine =~ s/#script_url/$scriptUrl/g;
				$tmplLine =~ s/#adm_nick/$cgiVals{'nick'}/g;
				$tmplLine =~ s/#adm_passwd/$cgiVals{'passwd'}/g;
				$tmplLine =~ s/#nickban/$bnickstr/g;
				$tmplLine =~ s/#ipban/$bipstr/g;
				$tmplLine =~ s/#hostban/$bhoststr/g;
				$tmplLine =~ s/#domban/$bdomstr/g;
				$tmplLine =~ s/#now/$time/g;

				if ( $tmplLine =~ /#next/ ) {
					$nextFlag = '1';
					$lineCount = $lineTotal + 1;
					next USER;
				};	
				$middlePart="$middlePart$tmplLine";
			};
			$nextFlag = '0';
		};
	};
	return ("$firstPart$middlePart$secondPart");
};

sub readData {
	&openUsrFile($_[0]);
	foreach $fieldname (@fieldList) {
		if (! eof (USERFILE)) {
			$userData{"$fieldname"} = <USERFILE>;
			chop($userData{"$fieldname"});
		} else {
			print("[RUNTIME ERROR : invalid user file.]");
			$userData{"$fieldname"} = ' ';
		};	
	};
	&closeUsrFile;
};
####################################################################
# Banned list $_[0] = tipo(directory) $_[1] = template file
####################################################################
sub banList {
	$toParser = '';
	
	# Lettura template
	if ( ! open (BANTMPL, "$chatdir$tmpldir$_[1]") ) {
			print("[CONFIG ERROR : $chatdir$tmpldir$_[1] file not found]");
	} else {

	@backTmpl = <BANTMPL>;
	close (BANTMPL);

	# Lettura directory
	opendir (BANDIR,"$chatdir$_[0]");
	@listofbanned = readdir(BANDIR);
	close (BANDIR);
	@listofbanned = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @listofbanned);
	@listofbanned = grep ( (!( /~/ )), @listofbanned);
	# Creazione lista
	@listofbanned = sort @listofbanned;
	foreach $item (@listofbanned) {
		@thisTmpl = @backTmpl;
		foreach $tmplLine (@thisTmpl) {
 			$tmplLine =~ s/#item/$item/g;
			$tmplLine =~ s/#html_url/$htmlUrl/g;
			$tmplLine =~ s/#now/$time/g;
			$tmplLine =~ s/#script_url/$scriptUrl/g;
			$tmplLine =~ s/#adm_nick/$cgiVals{'nick'}/g;
			$tmplLine =~ s/#adm_passwd/$cgiVals{'passwd'}/g;
			$toParser = "$toParser$tmplLine";
		};
	};
};
return ( "$toParser" );
};

########################################################################
# UnBanning 
########################################################################
sub uban { # Legge directory
	opendir(UBAN,"$chatdir$_[0]");
	@ublist = readdir(UBAN);
	close(UBAN);
	@ublist = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @ublist);
	@ublist = grep ( (!(  /~/ )), @ublist);
	# Sbanna .. :)
	foreach $which (@ublist) {
		if ( $cgiVals{"$which"} eq 'on' ) {
			unlink("$chatdir$_[0]$which");
			$banResult = "$banResult $_[1] &quot;$which&quot; unbanned.<BR>"; 
		};	 		
	};
};


#####################################################################
# getIdle Determina tempo di idle di un utente ($_[0] nick utente)
# restituisce 0 se l'utente non c'e'.
#####################################################################
sub getIdle {
	$retIdle = '0';
	if ( $flockMode ) {
		&cm_lock("$chatdir$laction$_[0]");
	};
	if (open (LACTION,"$chatdir$laction$_[0]")) {
		$retIdle = <LACTION>;
		close(LACTION);
		$retIdle = $time - $retIdle; 
	};
	if ( $flockMode ) {
		&cm_unlock("$chatdir$laction$_[0]");
	};
	return ( "$retIdle" );
};

#####################################################################
# Procedure di visualizzazione ora e data.
#####################################################################
sub vDate {
	$rightTime = $_[0] + ( 3600 * $timeAdjust );
  	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($rightTime);
   	$month = $months["$mon"];
	return ( "$month $mday, 19$year" );
};

sub vTime {
	$rightTime = $_[0] + ( 3600 * $timeAdjust );
  	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($rightTime);
	if ($hour < 10) { $hour = "0$hour"; };
	if ($min < 10) { $min = "0$min"; };
	if ($sec < 10) { $sec = "0$sec"; };
 	return ( "$hour:$min:$sec" );
};


####################################################################
# File Locking. 
# Procedura di locking dei file, per superare i problemi di compatibilita'
# del flock() del Perl con alcuni sistemi operativi.
# Da testare (Alpha), apparsa nella versione beta 3
####################################################################

sub cm_lock {
	$filetolock = "$_[0]~";
	$loopIndex = '0';
	while ( (-e "$filetolock") && ($loopIndex < $lockLimit) ) 
		{ sleep 1; $loopIndex++; };
	open (LOCKF, "> $filetolock");
	close (LOCKF);
} 

sub cm_unlock {
	$filetolock = "$_[0]~";
	unlink "$filetolock";	
};


#################################################################
# Se viene spedito un messaggio pubblico, questa routine si
# occupa di aggiungerla alla coda circolare di log
################################################################
sub mesgLogUpdate {

	# Lettura file di log
	if ( $flockMode ) {
		&cm_lock("$chatdir$mldir$logindex.$_[4]");
	};
	
	if ( open(MLFILE, "$chatdir$mldir$logindex.$_[4]") ) {
		$tail = <MLFILE>;
		close(MLFILE);
		if ( open(MLFILE, "> $chatdir$mldir$logindex.$_[4]") ) {
			if ( $tail == $mltop ) { print (MLFILE 1); } else { print (MLFILE $tail+1); };
			close(MLFILE);
		} else {
			print("[RUNTIME ERROR : $chatdir$mldir$logindex.$_[4] file opening error.]");
			exit(0);
		};
	} else { 
		print("[CONFIG ERROR : $chatdir$mldir$logindex.$_[4] file opening error.]");
		exit(0);
	};
	
	if ( $flockMode ) {
		&cm_unlock("$chatdir$mldir$logindex.$_[4]");
		&cm_lock("$chatdir$mldir$mlpre$tail.$_[4]");
	};
	if ( open(MLFILE,"> $chatdir$mldir$mlpre$tail.$_[4]") ) {
		print(MLFILE "$_[0]\n");
		print(MLFILE "$_[1]\n");
		print(MLFILE "$_[2]\n");
		print(MLFILE "$_[3]\n");
		close(MLFILE);
	} else {
		print("[RUNTIME ERROR : $chatdir$mldir$mlpre$tail.$_[4] file opening error.]");
		exit(0);
	};
	if ( $flockMode ) {
		&cm_unlock("$chatdir$mldir$mlpre$tail.$_[4]");
	};
};



######################################################################
################### Chat Daemon Code Start Here ! ####################
######################################################################

sub startDaemon {
	&openUsrFile("$chatdir$admdat$daemonCfg");
	$autoLogout = <USERFILE>;
	$timeLimit = <USERFILE>;
	&closeUsrFile;
	chop $autoLogout;
	chop $timeLimit;
	if ($autoLogout) { &chatDaemon; };
};	


sub chatDaemon {
	# Controlla file messaggi
	$time_CD = time;
	$deadTime_CD = $time_CD - $timeLimit;
	opendir(LOGDIR_CD,"$chatdir$logdir");
	@loggedNow_CD = readdir(LOGDIR_CD);
	closedir(LOGDIR_CD);
	@loggedNow_CD = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @loggedNow_CD);
	@loggedNow_CD = grep ( (!( /~/ )) , @loggedNow_CD);
	foreach $userFull_CD (@loggedNow_CD) {
		($userNick_CD,$userRoom_CD) = split ('\.',$userFull_CD,2);
		if ( $flockMode ) {
			&cm_lock("$chatdir$laction$userNick_CD");
		};
		if ( open(MBOX_CD,"$chatdir$laction$userNick_CD") ) {
			if (! eof (MBOX_CD)) {
				$oldest_CD = <MBOX_CD>;
				if ($oldest_CD < $deadTime_CD) {
					# kick off user !
					&readData_CD("$chatdir$userdir$userNick_CD");
					&logout_CD("$userNick_CD","$userRoom_CD"); 
					&sendLogout_CD("$userNick_CD","$userRoom_CD");
				};
			};
			close(MBOX_CD);
		};
		if ( $flockMode ) {
			&cm_unlock("$chatdir$laction$userNick_CD");
		};
	};
};

################################################################
# Logout by daemon 
################################################################
sub logout_CD {
	unlink "$chatdir$logdir$_[0].$_[1]";
	unlink "$chatdir$mesgdir$_[0]";
	unlink "$chatdir$laction$_[0]";
};

########################################################################
# Spedizione del messaggio di logout a tutti gli utenti collegati
# Nessun report di errori
########################################################################
sub sendLogout_CD {
	$nickName_CD = $_[0];
	opendir(LOGDIR_CD,"$chatdir$logdir");
	@dest_CD = readdir(LOGDIR_CD);
	closedir(LOGDIR_CD);
	@dest_CD = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..') && ("$_" ne "$nickName_CD")) , @dest_CD);
	@dest_CD = grep ( (!( /~/ )) , @dest_CD);
	if (! open(LOGMSG_CD,"$chatdir$tmpldir$logoutmsg") ) {
		@mesg_CD =  ('#%nick is logged out.');
	} else { 
		@mesg_CD = <LOGMSG_CD>;
		close(LOGMSG_CD);
	};
	$message_CD = '';
	foreach $mesgLine_CD (@mesg_CD) {
		$mesgLine_CD = &parseLogout_CD($mesgLine_CD);
		$message_CD = "$message_CD$mesgLine_CD";
	};	
	$mesgLen_CD = length($message_CD) + '1';
	foreach $destFull_CD (@dest_CD) {
		($destNick_CD,$destRoom_CD) = split ('\.',$destFull_CD,2);
		if ($destRoom_CD ne $_[1]) { next; };
	        if ( $flockMode ) {
			&cm_lock("$chatdir$mesgdir$destNick_CD");
		};
		if ( open(MESGFILE_CD, ">> $chatdir$mesgdir$destNick_CD") ) {
			print(MESGFILE_CD "$time_CD\n");
			print(MESGFILE_CD "$sysName\n");
			print(MESGFILE_CD "$mesgLen_CD\n");
			print(MESGFILE_CD "$message_CD\n");
			close(MESGFILE_CD);
		};
		if ( $flockMode ) {
			&cm_unlock("$chatdir$mesgdir$destNick_CD");
		};
	};
	if ($mlsystem) { &mesgLogUpdate("$time_CD","$sysName","$mesgLen_CD","$message_CD","$_[1]"); };
};

sub parseLogout_CD {
	$ret_CD = $_[0];
	foreach $fieldname_CD (@fieldList) {
		if ($fieldname_CD eq 'passwd') { next; };
		$ret_CD =~ s/#%$fieldname_CD/$userData_CD{"$fieldname_CD"}/g;
	};
	return ( $ret_CD );		
};

################################################################
# Operazioni (aperture, chiusura, lock) su file (generico)
# Parametri : [ [0] nome file ]
################################################################

sub openUsrFile_CD {  
	$hidden_usrcd = "$_[0]";
	if ( $flockMode ) {
		&cm_lock("$_[0]");
	};
	open(USERFILE_CD,"$_[0]");
};

sub closeUsrFile_CD {
	if ( $flockMode ) {
		&cm_unlock("$hidden_usrcd");
	};
	close(USERFILE_CD);
};

sub readData_CD {
	&openUsrFile_CD($_[0]);
	foreach $fieldname_CD (@fieldList) {
		if (! eof (USERFILE_CD)) {
			$userData_CD{"$fieldname_CD"} = <USERFILE_CD>;
			chop($userData_CD{"$fieldname_CD"});
		} else {
			$userData_CD{"$fieldname_CD"} = ' ';
		}; 
	};
	&closeUsrFile_CD;
};



