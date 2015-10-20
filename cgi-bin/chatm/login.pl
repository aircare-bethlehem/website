#!/usr/bin/perl
################################################################
# File name :	login.pl
# Description :	Chat login script.
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
$LOCKFILE = '2'; 	# IOCTL - Lock file
$UNLOCKFILE = '8';	# IOCTL - Unlock file
$lockLimit = '60';	# Time before lock skip
################################################################
######################  CODE START HERE  #######################
################################################################

if ($applyTControl) { &checkTime; };

&readRoomFile;

&startDaemon;

&getData;

# Controllo del nickname & della password
if (! $cgiVals{"nick"} ) { 
	&error ("Nickname required !");
	exit(0); 
};
if (! $cgiVals{"passwd"} ) { 
	&error ("Password required !");
	exit(0); 
};
if (! $cgiVals{"room"} ) { 
	&error ("Room selection required !");
	exit(0); 
};

foreach $field (@required) {
	if ($cgiVals{"$field"} eq '') {
		&error ("Field $field required !");
		exit(0); 
	};
};
		
# Pulizia del NickName
&nickClean;

# Verifica correttezza password e modalita' di login
$login1 = 'logintype1';
$login2 = 'logintype2';
if ( -e "$chatdir$admdat$login2" ) {
	&error ("Chat is closed");
	exit(0);
};
if ( -e "$chatdir$userdir$cgiVals{'nick'}" ) {
	&readUsrData("$chatdir$userdir$cgiVals{'nick'}"); 
	if ($cgiVals{'passwd'} ne $fileData{'passwd'}) {
		&error ("Nickname already exists and password is not correct.");
		exit(0);
	};
} elsif ( -e "$chatdir$admdat$login1" ) {
	&error ("Chat is reserved to registered users.");
	exit(0);
};


if ( -e "$chatdir$bannick$cgiVals{'nick'}") {
	&error ("Your nickname is banned.");
	exit(0);
};
if ( -e "$chatdir$banip$ENV{'REMOTE_ADDR'}") {
	&error ("Your IP address is banned.");
	exit(0);
};
if ( -e "$chatdir$banhost$ENV{'REMOTE_HOST'}") {
	&error ("Your host is banned.");
	exit(0);
};

opendir(DOMDIR,"$chatdir$bandom");
@domains = readdir(DOMDIR);
closedir(DOMDIR);
@domains = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')), @domains);
@domains = grep ( (!( /~/ )) , @domains);
foreach $banned (@domains) {
	if ($banned) {
		if ( ( "$ENV{'REMOTE_HOST'}" eq "$banned" ) ||	#E' proprio lui 
	     	   ( $ENV{'REMOTE_HOST'} =~ /$\\.$banned/ ) ) {   #Termina con .nomehost
			&error ("Your domain is banned.");
			exit(0);
		};
	}
};

&logUser;
if ($howMany >= $userLimit) {
	&error ("Chat is full. Please try later.");
	exit(0);
};

# Applicazione valori di default
if ($applyDefault) {
	foreach $fieldname (@fieldList) {
		if (! $cgiVals{"$fieldname"}) {
			$cgiVals{"$fieldname"} = $defValue{"$fieldname"};
		};
	};
}

# Aggiornamento di @fileData e @cgiVals.
foreach $fieldname (@fieldList) {
	if ($cgiVals{"$fieldname"}) {
		$fileData{"$fieldname"} = $cgiVals{"$fieldname"};
	};
};

# Aggiornamento dati di @fileData
$fileData{'hostname'} = $ENV{'REMOTE_HOST'};
$fileData{'ipadd'} = $ENV{'REMOTE_ADDR'};

# Salvataggio temporaneo di lastlogin. 
$backLogin = $fileData{'lastlogin'};
$fileData{'lastlogin'} = &vDate($time);

# Scrittura dati su file utente
&writeUsrData("$chatdir$userdir$cgiVals{'nick'}"); 

# Ripristino lastlogin.
$fileData{'lastlogin'} = $backLogin;

# Determinazione passwd messaggi (la passwd utilizzata per visualizzare/spedire
# i propri messaggi). Dipende dalla password dell'utente e dall'ora corrente.
$mesgPasswd = crypt($cgiVals{'passwd'},$sec);

# Creazione file di logged-in ed eliminazione eventuali omonimi presenti
&logUser;
foreach $whowhere (@logged) {
	($who,$where) = split ('\.',"$whowhere",2);
	if ($who eq $cgiVals{'nick'}) { 
		unlink "$chatdir$logdir$whowhere";
	};
}; 
&openUsrFile("> $chatdir$logdir$cgiVals{'nick'}.$cgiVals{'room'}");
print(USERFILE "$mesgPasswd");
&closeUsrFile;

# Creazione file dei messaggi 
&mesgFileCreation;

# Creazione file lastaction 
&openUsrFile("> $chatdir$laction$cgiVals{'nick'}");
print(USERFILE "$time");
&closeUsrFile;

# Spedizione messaggio di login.
&sendLogin;

# Visualizzazione del template di Welcome.
&welcome;

exit(0);


########################################################################
# Spedizione del messaggio di login a tutti gli utenti collegati
########################################################################
sub sendLogin {
	opendir(LOGDIR,"$chatdir$logdir");
	@dest = readdir(LOGDIR);
	closedir(LOGDIR);
	@dest = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @dest);
	@dest = grep ( (!( /~/ )) , @dest);
	if (! open(LOGMSG,"$chatdir$tmpldir$loginmsg") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$loginmsg file not found]"); 
		exit(0);
	};
	@mesg = <LOGMSG>;
	close(LOGMSG);
	$message = '';
	foreach $mesgLine (@mesg) {
		$mesgLine = &parseLogin($mesgLine);
		$message = "$message$mesgLine";
	};	
	$mesgLen = length($message) + '1';
	foreach $destFull (@dest) {
		($destNick,$destRoom) = split ('\.',$destFull,2);
		if ($destRoom ne $cgiVals{'room'}) { next; };
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
	if ($mlsystem) { &mesgLogUpdate("$time","$sysName","$mesgLen","$message","$cgiVals{'room'}"); };
};

sub parseLogin {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	return ( $ret );		
};


###############################################################
# Creazione file dei messaggi
###############################################################
sub mesgFileCreation {

if ($flockMode) { &cm_lock("$chatdir$mldir$logindex.$cgiVals{'room'}"); };
if ( open (LOGINDEX, "$chatdir$mldir$logindex.$cgiVals{'room'}") ) {
		$tail = <LOGINDEX>;
		close(LOGINDEX);
   } else { 
	print ("[CONFIG ERROR: $chatdir$mldir$logindex.$cgiVals{'room'} file opening error");
	exit(0);
};

&openUsrFile("> $chatdir$mesgdir$cgiVals{'nick'}");

for ( $i = 1; $i <= $mltop; $i++ ) {
	if ($flockMode) { &cm_lock("$chatdir$mldir$mlpre$tail.$cgiVals{'room'}"); };
	if ( open (TAILFILE, "$chatdir$mldir$mlpre$tail.$cgiVals{'room'}") ) {
		until ( eof (TAILFILE) ) {
			$Adummy = <TAILFILE>;
			$Bdummy = <TAILFILE>;
			$Cdummy = <TAILFILE>;
			$Ddummy = <TAILFILE>;
			if (($Adummy+($mltime*60)) > $time) { 
				print (USERFILE $Adummy);
				print (USERFILE $Bdummy);
				print (USERFILE $Cdummy);
				print (USERFILE $Ddummy);
			};
		};			
		close(TAILFILE);
	};
	if ($flockMode) { &cm_unlock("$chatdir$mldir$mlpre$tail.$cgiVals{'room'}"); };
	if ($tail == $mltop) { $tail = 1; } else  { $tail++; }; 
};
	 
if ($flockMode) { &cm_unlock("$chatdir$mldir$logindex.$cgiVals{'room'}"); };
&closeUsrFile;

};



################################################################
# Operazioni (aperture, chiusura, lock) su file (generico)
# Parametri : [ [0] nome file ]
################################################################

sub openUsrFile {
	$hidden_usrfile = "$_[0]"; 
	if ( $flockMode ) {
		&cm_lock("$_[0]");
	};
	if (! open(USERFILE,"$_[0]")) {
		print("[RUNTIME ERROR : $_[0] file opening error]");
		exit(0);
	};
};

sub closeUsrFile {
	if ( $flockMode ) {
		&cm_unlock("$hidden_usrfile");
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
			print("[RUNTIME ERROR : invalid user file]");
			$fileData{"$fieldname"} = ' ';
		};	
	};
	&closeUsrFile;
};

sub writeUsrData {
	&openUsrFile("> $_[0]");
	foreach $fieldname (@fieldList) {
		if (! print(USERFILE $fileData{"$fieldname"},"\n")) {
			print("[RUNTIME ERROR : user file writing error]");
			&closeUsrFile;
			exit(0);
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

	$time = time;
	if (scalar (@cgiPairs) == 0 ) { &viewLoginForm };

	foreach $pair ( @cgiPairs ) {
                ($var,$val) = split("=",$pair);
                $val =~ s/\+/ /g;
                $val =~ s/%(..)/pack("c",hex($1))/ge;
		$cgiVals{"$var"} = "$val";
	}
	#Ripulisce tutti i campi utente dai tag.
	foreach $field ( @fieldList ) {
		$cgiVals{"$field"} =~ s/</&lt;/g; 
		$cgiVals{"$field"} =~ s/>/&gt;/g; 
	};
};

#####################################################################
# Get Room list
#####################################################################
sub readRoomFile {
	if ( opendir (ROOMLIST,"$chatdir$roomdir") ) {
		@rooms = readdir (ROOMLIST);
		closedir (ROOMLIST);
		@rooms = grep (("$_" ne '.htaccess') && ($_ ne '.') && ($_ ne '..') && (!( /~/ )), @rooms);
		@rooms = sort @rooms;
	} else { 
		&error("[CONFIG ERROR: Can not find $chatdir$roomdir directory.]"); 
		exit(0);
	};
};

####################################################################
# Costruisce la lista degli utenti
####################################################################
sub logUser {
	opendir(LOGDIR,"$chatdir$logdir");
	@logged = readdir(LOGDIR);
	closedir(LOGDIR);
	@logged = grep ((("$_" ne '.htaccess') && ("$_" ne '.') && ("$_" ne '..')) , @logged);
	@logged = grep ( (!( /~/ )) , @logged);
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
# Subroutine di visualizzazione form di login (quando lo script
# viene richiamato senza parametri)
#####################################################################
sub viewLoginForm {
	if ( ! open(LOGINFORM,"$chatdir$tmpldir$loginform") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$loginform file not found]"); 
	} else { 
		while (! eof (LOGINFORM) ) {
			$line = <LOGINFORM>;
			$line = &parseLoginForm($line);
			print ($line);
		};			
		close(LOGINFORM);
		exit(0); 
	};
};

sub parseLoginForm {
	$ret = $_[0];
	$ret =~ s/#now/$time/g;
	$ret =~ s/#date/&vDate($time)/ge;	
	$ret =~ s/#time/&vTime($time)/ge;	
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;
	# Check room_list
	if ( $ret =~ /(#roomlist){1}(\d\d){1}/ ) {
		$dummy = &roomList("$ret","$&","$2");
		$ret = $dummy;
	};
	return ( "$ret" );
};


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
	foreach $fieldname (@fieldList) {
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$cgiVals{"$fieldname"}/g;
	};
	$ret =~ s/#error/$ERRORMSG/g;	
	$ret =~ s/#date/&vDate($time)/ge;	
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#now/$time/g;
	return ( "$ret" );
};

#################################################################
# Subroutine di visualizzazione della pagina di Welcome
#################################################################

sub welcome {
	if ( ! open(WELTMPL,"$chatdir$tmpldir$welfile") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$welfile file not found]"); 
	} else { 
		while (! eof (WELTMPL) ) {
			$line = <WELTMPL>;
			$line = &parseWell($line);
			print ($line);
		};			
		close(WELTMPL); 
	};
};

sub parseWell {
	$ret = $_[0];
	foreach $fieldname (@fieldList) {
		if ($fieldname eq 'passwd') { next; };
		$ret =~ s/#%$fieldname/$fileData{"$fieldname"}/g;
	};
	$ret =~ s/#%passwd/$mesgPasswd/g;
	$ret =~ s/#room/$cgiVals{'room'}/g;
	$ret =~ s/#script_url/$scriptUrl/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#date/&vDate($time)/ge;	
	$ret =~ s/#now/$time/g;
	if ( $ret =~ /#count/ ) {
		&logUser;
		$ret =~ s/#count/$howMany/g;
	};
	if ( $ret =~ /#rcount/ ) {
		&roomUser("$cgiVals{'room'}");
		$ret =~ s/#rcount/$howRoom/g;
	};
	# Check user_list
	if ( $ret =~ /#userlist/ ) {
		$ret = &userList("$ret");
	};
	return ( "$ret" );
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
	($firstPart,$secondPart) = split ('#userlist',"$_[0]",2);
	$middlePart = '';	

	if ( ! open(LISTTMPL,"$chatdir$tmpldir$listfile") ) {
		print("[CONFIG ERROR : $chatdir$tmpldir$listfile file not found]"); 
	} else { 
		@backTemplate = <LISTTMPL>;
		close(LISTTMPL);
	
		$nextFlag = '0';
		&logUser;
		@logged = sort @logged;
		# Creazione lista
USER:		foreach $userFull (@logged) {
			($userNick,$userRoom) = split ('\.',$userFull,2);
			if ($userRoom ne $cgiVals{'room'}) { next; };
			&readData("$chatdir$userdir$userNick");
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
				$tmplLine =~ s/#html_url/$htmlUrl/g;
				$tmplLine =~ s/#script_url/$scriptUrl/g;
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
			$userData{"$fieldname"} = ' ';	
		};	
	};
	&closeUsrFile;
};


################################################################
# Pulizia del nickname da caratteri "pericolosi"
################################################################
# E' probabile che si debbano eliminare altri caratteri...
sub nickClean {
	$cgiVals{'nick'} =~ s/[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-]//g; 
	if (length($cgiVals{'nick'}) > "$nickLen") 
		{ 
		 $cgiVals{'nick'} = substr("$cgiVals{'nick'}",0,"$nickLen");
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
# CheckTime - Procedura di controllo dell'ora - data per
# limitare l'accesso alla chat
####################################################################
sub checkTime {
	$rightTime = time + ( 3600 * $timeAdjust );
  	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($rightTime);
	if (! $timeControl[$wday*24+$hour] ) {
		if ( ! open(TIMECLOSE,"$chatdir$tmpldir$timeclose") ) {
		        print("[CONFIG ERROR : $chatdir$tmpldir$timeclose file not found]"); 
		} else { 
		        while (! eof (TIMECLOSE) ) {
				$line = <TIMECLOSE>;
				$line = &parseTimeClose($line);
				print ($line);
			};	
			close(TIMECLOSE);
		};
		exit(0); 
	};
};

sub parseTimeClose {
	$ret = $_[0];
	$ret =~ s/#now/$time/g;
	$ret =~ s/#date/&vDate($rightTime)/ge;	
	$ret =~ s/#time/&vTime($rightTime)/ge;	
	$ret =~ s/#ver/$VERSION/g;
	$ret =~ s/#html_url/$htmlUrl/g;	
	$ret =~ s/#script_url/$scriptUrl/g;	
	$ret =~ s/#script/$ENV{'SCRIPT_NAME'}/g;
	return ( "$ret" );
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



