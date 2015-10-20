#!/usr/bin/perl
################################################################
# File name :	chat.pl
# Description :	Chat engine script.
# Author :	Nardone Vittorio (nards@iol.it)
################################################################
#########################################################################
# 	DON'T EDIT SCRIPT CODE ! COPYRIGHT 1997 VITTORIO NARDONE        #
# 		YOU CAN ONLY EDIT "INCLUDE.PL" FILE !                   #
# 			ALL RIGHTS RESERVED                             #
#########################################################################

# Per includere le impostazioni utente 
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
$VERSION = 'First 98';	# Versione dello script
$LOCKFILE = '2';	# IOCTL - Lockfile
$UNLOCKFILE = '8';	# IOCTL - Unlockfile
$lockLimit = '60';	# Seconds before lock skip
################################################################
######################  CODE START HERE  #######################
################################################################

&readRoomFile;

&startDaemon;

&getData;

# Controllo della presenza di tutti i campi del form
if ( (! $cgiVals{'nick'}) || (! $cgiVals{'passwd'}) || 
     (! $cgiVals{'tmpl'}) || (! $cgiVals{'room'}) ) 
{	
	&error ("Invalid message form.");
	exit(0); 
};

# Verifica correttezza password 
if ( -e "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}" ) {
	$passwd = &readPasswd("$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}"); 
	if ($cgiVals{'passwd'} ne $passwd) {
	       &error ("Password errata.");
		exit(0);
	};
} else {
	&error ("Your are not logged. Please try login again.");
	exit(0);
};

# Lettura informazioni utente
&readUsrData("$chatdir$userdir$cgiVals{'nick'}");

# Creazione file lastaction (utilizzata dal demone chatd per la 
# determinazione degli utenti idle)
&openUsrFile("> $chatdir$laction$cgiVals{'nick'}");
print(USERFILE "$time");
&closeUsrFile;

# Spedizione o logout ?
if ( $cgiVals{'cmd'} eq 'send' ) {
	&sendMessage;
} elsif ( $cgiVals{'cmd'} eq 'exit' ) { 
	&logout;
	exit(0);
} elsif ( $cgiVals{'cmd'} eq 'chgRoom') {
	&changeRoom;
};

# Nome template ?
if ( grep ( $_ eq $cgiVals{'nick'}, @admName ) ) {
	$chatfile = "$admchatpre$cgiVals{'tmpl'}.tmpl";	
} else {
	$chatfile = "$chatpre$cgiVals{'tmpl'}.tmpl";	
};

# Visualizzazione template e messaggi
&readMessage;

exit(0);

################################################################
# Procedura di logout dalla chat 
################################################################
sub logout {
	unlink "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}";
	unlink "$chatdir$mesgdir$cgiVals{'nick'}";
	unlink "$chatdir$laction$cgiVals{'nick'}";
	&sendLog("$logoutmsg","$cgiVals{'room'}");
	&viewExit;
};

sub viewExit {
	if ( ! open(EXITTMPL,"$chatdir$tmpldir$exitfile") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$exitfile not found]"); 
	} else { 
		while (! eof (EXITTMPL) ) {
			$line = <EXITTMPL>;
			$line = &parseExit($line);
			print ($line);
		};			
		close(EXITTMPL); 
	};
};

sub parseExit {
	$ret = $_[0];
	foreach $fieldname (@fieldList) { 
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	$ret =~ s/#date/&vDate($time)/ge;
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#now/$time/g;
	return ( "$ret" );
};


########################################################################
# Spedizione del messaggio di logout a tutti gli utenti collegati
########################################################################
sub sendLog {
	$whichRoom = $_[1];
	opendir(LOGDIR,"$chatdir$logdir");
	@dest = readdir(LOGDIR);
	closedir(LOGDIR);
	@dest = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..') && ("$_" ne "$cgiVals{'nick'}")) , @dest);
	@dest = grep ( (!( /~/ )), @dest);
	if (! open(LOGMSG,"$chatdir$tmpldir$_[0]") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$_[0] file not found]"); 
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
		($destNick,$destRoom) = split ('\.',$destFull,2);
		if ($destRoom ne $whichRoom) { next; };
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
	if ($mlsystem) { &mesgLogUpdate("$time","$sysName","$mesgLen","$message","$whichRoom"); };
};

sub parseLogout {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	$ret =~ s/#room/$whichRoom/g;
	return ( $ret );		
};


#################################################################
# Procedure di spedizione messaggi
#################################################################
sub sendMessage {
	# Lettura messaggio
	if ($cgiVals{'message'}) {
		&deHTML;
		if (length($cgiVals{'message'}) > "$messLen")
			{
			  $cgiVals{'message'} = substr("$cgiVals{'message'}",0,"$messLen");
			}
		# Esiste messaggio, determina destinatari
		if ( ($cgiVals{'sendall'} eq 'on') || (grep ( "$_" eq 'sendall', @selectDest )) ) {
			&sendtoAll;
		} else {
			&sendtoSome;
		};
	};		
};

sub deHTML {
	if ($noHTML == 1) {
		$cgiVals{'message'} =~ s/</&lt;/g;
		$cgiVals{'message'} =~ s/>/&gt;/g;
	} elsif ($noHTML == 2) {
		$cgiVals{'message'} =~ s/(<){1}([\/]?)(\w+)([^>]*)(>){1}/&rightHTML("$2","$3","$4")/egi;
		if ($autoclose) {
			foreach $tag (@allowHTML) {
				if ( $HTMLtagCount{"\U$tag\E"} > 0) {
					$cgiVals{'message'} .= "</$tag>";		
				};
			};
		}; 
	};
};

sub rightHTML {
	$tag = $_[1];
	$paramTag = $_[2];
	if (grep ("\U$tag\E" eq "\U$_\E", @allowHTML)) {
		if ($_[0] eq '/') { $HTMLtagCount{"\U$tag\E"}--; }
				else { $HTMLtagCount{"\U$tag\E"}++; };
		return ("<$_[0]$tag$paramTag>");
	} else { 	  
		return ("&lt;$_[0]$tag$paramTag&gt;");
	};
};

sub sendtoAll {
	# Lettura directory mesg
	opendir(LOGDIR,"$chatdir$logdir");
	@dest = readdir(LOGDIR);
	closedir(LOGDIR);
	@dest = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @dest);
	@dest = grep ( (!( /~/ )), @dest);
	$mesgLen = length($cgiVals{'message'}) + '1';
	foreach $destFull (@dest) {
		($destNick,$destRoom) = split ('\.',$destFull,2);
		if ($destRoom ne $cgiVals{'room'}) { next; };
		if ( $flockMode ) {
			&cm_lock("$chatdir$mesgdir$destNick");
		};
		if ( open(MESGFILE,">> $chatdir$mesgdir$destNick") ) {
			print(MESGFILE "$time\n");
			print(MESGFILE "$cgiVals{'nick'}\n");
			print(MESGFILE "$mesgLen\n");
			print(MESGFILE "$cgiVals{'message'}\n");
			close(MESGFILE);
	   	};
		if ( $flockMode ) {
			&cm_unlock("$chatdir$mesgdir$destNick");
		};
	};
	&mesgLogUpdate("$time","$cgiVals{'nick'}","$mesgLen","$cgiVals{'message'}","$cgiVals{'room'}");
};

sub sendtoSome {
	# Lettura directory mesg
	opendir(LOGDIR,"$chatdir$logdir");
	@destList = readdir(LOGDIR);
	closedir(LOGDIR);
	@destList = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @destList);
	@destList = grep ( (!( /~/ )), @destList);
	
	# Si usa il SELECT per selezionare i dest. dei messaggi ?
	if ( $cgiVals{'select'} ) {
		foreach	$destNick (@selectDest) {
			if ( grep ( ( "$_" eq "$destNick.$cgiVals{'room'}" ), @destList) ) {
				push (@dest,"$destNick");
			};
		};

	} else {
		# Eliminazione destinatari non selezionati
		foreach	$destFull (@destList) {
			($destNick,$destRoom) = split ('\.',$destFull,2);
			if ($destRoom ne $cgiVals{'room'}) { next; };
			if ( $cgiVals{"$destNick"} eq 'on' ) {
				push (@dest,"$destNick");
			};
		};
	};
	if ($autoPrivate) {
		if ( ! grep ( ( "$_" eq "$cgiVals{'nick'}" ), @dest) ) {
			push (@dest,"$cgiVals{'nick'}");
		};
	}; 
	# Crea stringa contenente elenco destinatari
	$destination = join('%',@dest); 
	$mesgLen = length($cgiVals{'message'}) + '1';
	foreach $destNick (@dest) {
		if ( $flockMode ) {
			&cm_lock("$chatdir$mesgdir$destNick");
		};
		if ( open(MESGFILE,">> $chatdir$mesgdir$destNick") ) {
			print(MESGFILE "$time\n");
			print(MESGFILE "$cgiVals{'nick'}",'%%',"$destination\n");
			print(MESGFILE "$mesgLen\n");
			print(MESGFILE "$cgiVals{'message'}\n");
			close(MESGFILE);
	   	};
		if ( $flockMode ) {
			&cm_unlock("$chatdir$mesgdir$destNick");
		};
	};
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
			&error ("Non sei presente in chat, ripeti la procedura di login.");
			close(PASSWD);
			exit(0);
		};
		close(PASSWD);
	} else {
		&error ("Non sei presente in chat, ripeti la procedura di login");
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
	if ( $flockMode ) {
		&cm_unlock("$hiddenUsrFile");
	};
	close(USERFILE);
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
			#print("[RUNTIME ERROR : invalid user file]");
			$fileData{"$fieldname"} = ' ';
		};	
	};
	&closeUsrFile;
};


#################################################################
# Procedura per il cambio di stanza
#################################################################
sub changeRoom {
	if ( $cgiVals{'newroom'} ) {
		unlink "$chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}";
		open (LOGFILE, "> $chatdir$logdir$cgiVals{'nick'}.$cgiVals{'newroom'}");
		print (LOGFILE "$cgiVals{'passwd'}");
		close (LOGFILE);	
		&sendLog ("$leaveroom","$cgiVals{'room'}");
		&sendLog ("$enterroom","$cgiVals{'newroom'}");
		$cgiVals{'room'} = $cgiVals{'newroom'};
	};
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

	foreach $pair ( @cgiPairs ) {
                ($var,$val) = split("=",$pair);
                $val =~ s/\+/ /g;
                $val =~ s/%(..)/pack("c",hex($1))/ge;
		if ($cgiVals{"$var"} eq '') {
			$cgiVals{"$var"} = "$val";
		} else { 
			$cgiVals{"$var"} .= ",$val";
		};
        }


	# Imposta array elenco destinatari messaggi
	@selectDest = split (',',$cgiVals{'select'});

	# Imposta ora attuale
	$time = time;

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


#####################################################################
# Get Room list
#####################################################################
sub readRoomFile {
	if ( opendir (ROOMLIST,"$chatdir$roomdir") ) {
		@rooms = readdir (ROOMLIST);
		closedir (ROOMLIST);
		@rooms = grep ( ("$_" ne '.htaccess') && ($_ ne '.') && ($_ ne '..') && (!( /~/ )), @rooms);
		@rooms = sort @rooms;
		$howManyRoom = scalar @rooms;
	} else { 
		&error("[CONFIG ERROR: Can not find $chatdir$roomdir directory.]"); 
		exit(0);
	};
};

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
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;	
	return ( "$ret" );
};

#################################################################
# Subroutine di visualizzazione dei messaggi
#################################################################

sub readMessage {
	if ( ! open(CHATTMPL,"$chatdir$tmpldir$chatfile") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$chatfile file not found]"); 
	} else { 
		while (! eof (CHATTMPL) ) {
			$line = <CHATTMPL>;
			if ( $line =~ /#message/ ) {
				&printMessage;
			} else {
				$line = &parseChat($line);
				print ($line);
			};
		};			
		close(CHATTMPL); 
	};
};

sub printMessage {
	if ( $flockMode ) {
		&cm_lock("$chatdir$mesgdir$cgiVals{'nick'}");
	};
	if ( ! open (MESGFILE,"$chatdir$mesgdir$cgiVals{'nick'}") ) {
		print("[RUNTIME ERROR : $chatdir$mesgdir$cgiVals{'nick'} file not found]");
	} else {
		$mesgNum = '0';

		while (! eof MESGFILE) {
			
			#File reading
			$mesgNum = $mesgNum + 1;

			$dummy = <MESGFILE>;    
			chop $dummy;
			($storing{"$mesgNum",'time'},$storing{"$mesgNum",'is_old'}) = split ('%%',$dummy,2);    
			$storing{"$mesgNum",'from_to'} = <MESGFILE>; 
			chop $storing{"$mesgNum",'from_to'};
			$storing{"$mesgNum",'length'} = <MESGFILE>;  
			chop $storing{"$mesgNum",'length'};
			read ( MESGFILE, $dummy, $storing{"$mesgNum",'length'} ); 
			chop $dummy;
			$storing{"$mesgNum",'message'} =  $dummy;
		};	
		
		#Set message order
		if ($mesgOrder) {
			$firstMesg=$mesgNum;
			if ($mesgNum > $mesgLimit) {
				$lastMesg = $mesgNum - $mesgLimit + 1;
			} else { $lastMesg = '1'; };
			$mesgInc = '-1';
		} else {
			$lastMesg=$mesgNum;
			if ($mesgNum > $mesgLimit) {
				$firstMesg = $mesgNum - $mesgLimit + 1;	
			} else { $firstMesg = '1'; };
			$mesgInc = '1';
		};

		#Show messages
		while ( ((! $mesgOrder) && ($firstMesg <= $lastMesg)) ||
		        (($mesgOrder) && ($lastMesg <= $firstMesg)) ) {
			
			($mesg{'from'},$mesg{'to'}) = split('%%',$storing{"$firstMesg",'from_to'},2);
			@mesgDest = split ('%',$mesg{'to'});
			if (! scalar @mesgDest) {
				push (@mesgDest,("$allStr"));
			};
			$mesg{'message'} = $storing{"$firstMesg",'message'};
			$mesg{'message'} =~ s/\n/<BR>/g;
			$mesg{'time'} = $storing{"$firstMesg",'time'};
			$mesg{'is_old'} = $storing{"$firstMesg",'is_old'};
			&setCategory;
			&printMesTmpl;
			$firstMesg = $firstMesg + $mesgInc;
		};

		#Now update mesgfile
		if ($mesgNum > $oldLimit) {
			$firstMesg = $mesgNum - $oldLimit + 1;
		} else { $firstMesg = '1'; };
		
		close (MESGFILE);

		open (MESGOUT,"> $chatdir$mesgdir$cgiVals{'nick'}");
		while ( $firstMesg <= $mesgNum ) {
			print (MESGOUT $storing{"$firstMesg",'time'},"%%1\n");
			print (MESGOUT $storing{"$firstMesg",'from_to'},"\n");
			print (MESGOUT $storing{"$firstMesg",'length'},"\n");
			print (MESGOUT $storing{"$firstMesg",'message'},"\n");
			$firstMesg = $firstMesg + 1;
		};
#Now close file for output
		close (MESGOUT);
		if ( $flockMode ) {
			&cm_unlock("$chatdir$mesgdir$cgiVals{'nick'}");
		};
	};
};

sub setCategory {
	if ($mesg{'is_old'}) {
		if ($mesg{'from'} eq $cgiVals{'nick'}) { 
			$tmplName = "$tmplFromMeOld"; 
		} elsif ($mesg{'from'} eq "$sysName") {
			$tmplName = "$tmplSystemOld"; 
		} elsif (! $mesg{'to'} ) {
			$tmplName = "$tmplPublicOld"; 
		} else {
			$tmplName = "$tmplPrivateOld"; 
		};
	} else { 
		if ($mesg{'from'} eq $cgiVals{'nick'}) { 
			$tmplName = "$tmplFromMe"; 
		} elsif ($mesg{'from'} eq "$sysName") {
			$tmplName = "$tmplSystem"; 
		} elsif (! $mesg{'to'} ) {
			$tmplName = "$tmplPublic"; 
		} else {
			$tmplName = "$tmplPrivate"; 
		};
	}; 
};

sub printMesTmpl {
	if ( ! open(MESGTMPL,"$chatdir$tmpldir$tmplName") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$tmplName file not found]"); 
	} else {
		while ( ! eof MESGTMPL ) {
			$tmplLine = <MESGTMPL>;
			$tmplLine = &parseMessage($tmplLine);
			print ($tmplLine);
		};
		close(MESGTMPL);
	};
};	

sub parseMessage {
	$parsed = $_[0];
	$parsed =~ s/#from/$mesg{'from'}/g;
	$parsed =~ s/#to/@mesgDest/g;
	$parsed =~ s/#room/$cgiVals{'room'}/g;
	$parsed =~ s/#message/$mesg{'message'}/g;
	$parsed =~ s/#time/&vTime($mesg{'time'})/ge;
	$parsed =~ s/#date/&vDate($mesg{'time'})/ge;
	$parsed =~ s/#script_url/$scriptUrl/g;	
	$parsed =~ s/#html_url/$htmlUrl/g;	
	return ( "$parsed" );			
};

sub parseChat {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ( $fieldname eq 'passwd' ) { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	$ret =~ s/#%passwd/$cgiVals{'passwd'}/g;	
	$ret =~ s/#date/&vDate($time)/ge;
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#html_url/$htmlUrl/g;	
	if ( $ret =~ /#count/ ) {
		&logUser;
		$ret =~ s/#count/$howMany/g;
	};
	if ( $ret =~ /#rcount/ ) {
		&roomUser("$cgiVals{'room'}");
		$ret =~ s/#rcount/$howRoom/g;
	};
	$ret =~ s/#now/$time/g;
	# Check sendall
	if ($cgiVals{'sendall'}) {
		$ret =~ s/#sendall/CHECKED/g;
	} elsif (grep ( "$_" eq 'sendall', @selectDest )) {
		$ret =~ s/#sendall/SELECTED/g;
	} else {
		$ret =~ s/#sendall//g;
	};
	
	# Check user_lists
	if ( $ret =~ /(#loglist){1}(\d\d){1}/ ) {
		$dummy = &userList("$ret","$&","$chatdir$tmpldir$logpre$2.tmpl");
		$ret = $dummy;
	};
	# Check room_list
	if ( $ret =~ /(#roomlist){1}(\d\d){1}/ ) {
		$dummy = &roomList("$ret","$&","$2");
		$ret = $dummy;
	};
	$ret =~ s/#roomcount/$howManyRoom/g;
	$ret =~ s/#room/$cgiVals{'room'}/g;
	return ( "$ret" );
};

###############################################################################
# Procedura di elenco stanze e utenti presenti
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
		$roomCounter = 0;
		# Creazione lista
		foreach $roomName (@rooms) {
			$roomCounter++;
			@fullTemplate = @backTemplate;
			foreach $tmplLine (@fullTemplate) {
				foreach $fieldname (@fieldList) {
					if ( $fieldname eq 'passwd' ) { next; };
					$tmplLine =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
				};
				$tmplLine =~ s/#%passwd/$cgiVals{'passwd'}/g;	
				$tmplLine =~ s/#now/$time/g;
				$tmplLine =~ s/#counter/$roomCounter/g;
				$tmplLine =~ s/#html_url/$htmlUrl/g;
				$tmplLine =~ s/#script_url/$scriptUrl/g;
				$tmplLine =~ s/#room_name/$roomName/g;
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
	# Attenzione : solo il primo #userlist della linea viene considerato
	($firstPart,$secondPart) = split ("$_[1]","$_[0]",2);
	$middlePart = '';	

	# Lettura Template
	if ( ! open(LISTTMPL,"$_[2]") ) {
		print("[CONFIG ERROR : $_[2] file not found]"); 
	} else {
		@backTemplate = <LISTTMPL>;
		close(LISTTMPL);
		
		$nextFlag = '0';
		&logUser;
		# Creazione lista
		@logged = sort @logged;
USER:		foreach $userFull (@logged) {
			($userNick,$userRoom) = split ('\.',$userFull,2);
			if ($userRoom ne $cgiVals{'room'}) { next; };
			@fullTemplate = @backTemplate;
			&readData("$chatdir$userdir$userNick");
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
				if ($cgiVals{"$userNick"} eq 'on') {
					$tmplLine =~ s/#last/CHECKED/g;
				} elsif ( grep ( ("$_" eq "$userNick"), @selectDest) ) {
					$tmplLine =~ s/#last/SELECTED/g;
				} else {
					$tmplLine =~ s/#last//g;
				};	
				$tmplLine =~ s/#idle/&getIdle("$userNick")/ge;
				$tmplLine =~ s/#html_url/$htmlUrl/g;
				$tmplLine =~ s/#now/$time/g;
				if ($tmplLine =~ /#next/) {
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
			#print("[RUNTIME ERROR : invalid user file]");
			$userData{"$fieldname"} = ' ';
		};	
	};
	&closeUsrFile;
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



