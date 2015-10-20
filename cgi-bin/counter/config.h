#ifndef _COUNT_CONFIG_H
#define _COUNT_CONFIG_H

/***************---READ---READ---READ---READ---*********************
** Note: ConfigDir, DigitDir, DataDir and LogDir MUST differ
**       I suggest, create a base directory say Counter, then create
**       4 separate directories inside like:
**
**       mkdir /usr/local/etc/Counter
**       cd /usr/local/etc/Counter
**       mkdir conf
**       mkdir digits
**       mkdir data
**       mkdir logs
**       
**       you can use anydirectory instead of /usr/local/etc/Counter, this
**       just to give you an example.
**       now,
**       for ConfiDir, use "/usr/local/etc/Counter/conf"
**       for DigitDir, use "/usr/local/etc/Counter/digits"
**       for DataDir, use "/usr/local/etc/Counter/data"
**       for LogDir, use "/usr/local/etc/Counter/logs"
**
** a script will be provided to automate the whole process in the next release
*********************************************************************/


/*
** base directory of the configuration file.
** do not end the string with /
*/
#define ConfigDir   "/home/web/a/aircareonline.com/cgi-bin/counter/conf"
/*
** name of the configuration file
** look at the example file "count.conf" for the format of this file
*/
#define ConfigFile "count.conf"

/*------------------------------------*/

/*
** Base directory where the sub-directories of the digits are located.
** PLEASE NOTE CAREFULLY: this directory does not contain the digit GIF
** images, it contains the sub-directories which contain the GIF images.
** For example, I keep the directories A, B, C,
** inside directory /usr/local/etc/Counter/digits
** These sub-directories has digits with different styles. The name of the
** sub-directory is supplied when the program is called from the web page.
** Please read the instructions on the Counter page for details.
**
** DO NOT end the string with a /, it will be added later
*/
#define DigitDir   "/home/web/a/aircareonline.com/cgi-bin/counter/digits"

/*------------------------------------*/

/*
** name of the base directory where the counter data files will reside
** this is done to force the location of the datafile
** thanks to carsten@group.com (07/27/95)
** DO NOT end the string with a /, it will be added later
** no need to define datafile name, it will be given while calling
*/
/*------------------------------------*/
#define DataDir   "/home/web/a/aircareonline.com/cgi-bin/counter/data"

/*
** base directory of the log file
*/
#define LogDir   "/home/web/a/aircareonline.com/cgi-bin/counter/logs"
/*
** name of log file. Error and log messages will be written to this
*/
#define LogFile "Count15.log"

#endif /* _COUNT_CONFIG_H*/
