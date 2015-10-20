/*
 *  Header file for Count
 *
 *  RCS:
 *      $Revision: 1.3 $
 *      $Date: 1995/07/16 17:02:55 $
 *
 *  Security:
 *      Unclassified
 *
 *  Description:
 *      text
 *
 *  Input Parameters:
 *      type    identifier  description
 *
 *      text
 *
 *  Output Parameters:
 *      type    identifier  description
 *
 *      text
 *
 *  Return Values:
 *      value   description
 *
 *  Side Effects:
 *      text
 *
 *  Limitations and Comments:
 *      text
 *
 *  Development History:
 *      who                 when        why
 *      muquit@semcor.com   05-Jun-95   first cut
 */

#ifndef _COUNT_H
#define _COUNT_H

#include <stdio.h>

#if __STDC__
#include <stdlib.h>
#include <ctype.h>
#endif

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <sys/param.h>
#include <unistd.h>
#include <fcntl.h>
#include <malloc.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <pwd.h>

#include <string.h>

#include <time.h>

#include "combine.h"

#ifndef True
#define True 1
#endif

#ifndef False
#define False 0
#endif

#define LF  10


#if __STDC__ || defined(sgi) || defined(_AIX)
#define _Declare(formal_parameters) formal_parameters
#else
#define _Declare(formal_parameters) ()
#endif

#ifdef Extern
#undef Extern
#endif

#ifndef __Main__
#define Extern extern
#else
#define Extern
#endif

#define Version "1.5"
#define Author          "muquit@semcor.com"
#define Url             "http://www.semcor.com/~muquit/Count.html"


/*
** montage will write a image of type GIF at stdout
** look at montage man page for details. If the web browser supports JPEG
** inlined image, the type can be "JPEG:-". If you want X bitmap, the type
** can be "XBM:-"
** Note: GIF type will produce the fastest output for the type of digital
** image I used, so I suggest leave it alone.
*/
#define GIFfile "GIF:-"

#define MaxTextLength 2048

/*
** Maximum number of sites to ignore
*/
#define MaxSites    100

/*
** ErrorCodes
*/
#define ConfigOpenFailed        100
#define NoIgnoreHostsBlock      101
#define UnpexpectedEof          102
#define NoRefhBlock              103
#define NoAccessList            104
#define IncompleteAccessList    105

#define NoLoginName             200
#define NoDatafile              201

/*
** global variables
*/

    Extern char 
        *GrefererHost[MaxSites+1],
        *GignoreSite[MaxSites+1];

    Extern int
        Grhost,
        Gsite;
    Extern unsigned int
        Gdebug;
/*
** maxumim line length in authorization file
*/
#define MaxLineLength 2048


typedef struct _DigitInfo
{
    int
        maxdigits;

    unsigned int
        leftpad;

    unsigned int
        Frame;

    unsigned int
        alpha,
        width,
        height;

    unsigned char
        alpha_red,
        alpha_green,
        alpha_blue;

    char
        ddhead[100];

    char
        datafile[MaxTextLength];
    
    unsigned int
        st;        

    unsigned int
        show;

} DigitInfo;

void
    DisplayCounter _Declare ((void));

int
    checkfilename _Declare ((char *));

int
    CheckFile _Declare ((char *));

void
    SendErrorImage _Declare ((unsigned char *, int));

char
    *mystrdup _Declare ((char *));

int
    GetLine _Declare ((FILE *, char *));

void
    RemoveTrailingSp _Declare ((char *));

int
    ParseAuthorizationList _Declare ((void));

int
    CheckOwner _Declare ((char *, char *));

int
    ParseQueryString _Declare ((char *, DigitInfo *, FrameInfo *));

void
    Warning _Declare ((char *));

char
    *GetTime _Declare ((void));

void
    PrintHeader _Declare ((void));

void
    WriteCounterImage _Declare ((char *,DigitInfo *, FrameInfo *));

void
    GetRemoteReferer _Declare ((char *, char *));

#ifdef USE_LOCK
void
    SetLock _Declare ((int));

void
    UnsetLock _Declare ((int));

#endif

int
    CheckDirs _Declare ((void));

void
    StringImage _Declare ((char *));

unsigned int
    CheckRemoteIP _Declare ((char *, char *));

#endif /* _COUNT_H */
