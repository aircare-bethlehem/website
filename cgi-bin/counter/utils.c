#include "count.h"
#include "config.h"


/*
 *  ParseAuthorizationList() -   parses the authorization list
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

int ParseAuthorizationList ()
{
    FILE
        *fp;

    int
        i;

    char
        buf[MaxLineLength+1];

    i=0;

    *buf='\0';
    (void) sprintf(buf,"%s/%s",ConfigDir,ConfigFile);
    fp = fopen(buf, "r");
    if (fp == (FILE *) NULL)
    {
        return (ConfigOpenFailed);
    }

    *buf='\0';
    (void) GetLine (fp, buf);
    if (strcmp (buf, "{") != 0)
    {
        (void) fclose ((FILE *) fp);
        return (NoIgnoreHostsBlock);
    }

    while (True)
    {
        if (!GetLine (fp, buf))
        {
            (void) fclose ((FILE *) fp);
            return (UnpexpectedEof);
        }

        if (strcmp(buf, "}") == 0)
            break;
        RemoveTrailingSp (buf);
        GignoreSite[Gsite++] = mystrdup (buf);
    }

    if (Gdebug == True)
    {
        if (Gsite > 0)
            (void) fprintf (stderr,"Ignore Hosts:\n");
        else
            (void) fprintf (stderr," Access from any hosts counted!\n");
        for (i=0; i < Gsite; i++)
        {
            (void) fprintf (stderr," %s\n", GignoreSite[i]);
        }
            (void) fprintf (stderr,"\n");
    }

#ifdef ACCESS_AUTH
    (void) GetLine (fp, buf);
    if (strcmp(buf, "{") != 0)
    {
       (void) fclose ((FILE *) fp);
        return (NoRefhBlock);
    }
    while (True)
    {
        if (!GetLine (fp, buf))
        {
            (void) fclose ((FILE *) fp);
            return (UnpexpectedEof);
        }
        if (strcmp (buf, "}") == 0)
            break;
        RemoveTrailingSp (buf);
        GrefererHost[Grhost++]= mystrdup(buf);

    }

    if (Gdebug == True)
    {
        if (Grhost > 0)
            (void) fprintf (stderr,"-Referer Hosts-\n");
        else
            (void) fprintf (stderr,"Grhost:%d\n",Grhost);
        for (i=0; i < Grhost; i++)
        {
            (void) fprintf (stderr," %s\n", GrefererHost[i]);
        }
        (void) fprintf (stderr,"\n");
    }

#endif /* ACCESS_AUTH */
    (void) fclose ((FILE *) fp);
    return (0);
}

#ifdef TEST

void main (argc, argv)
int
    argc;
char
    **argv;
{
    ParseAuthorizationList ();
}
#endif /* TEST */


/*
 *  GetLine () - reads a line from the passed file pointer and puts the
 *               line in the passed array
 *
 *  RCS:
 *      $Revision: 1.3 $
 *      $Date: 1995/07/16 17:02:55 $
 *
 *  Security:
 *      Unclassified
 *
 *  Description:
 *      borrowed from wusage 2.3
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

int GetLine (fp, string)
FILE
    *fp;
char
    *string;
{
    int
        s,
        i;

    int
        length;

    char
        *x;
    while (!feof (fp))
    {
        x = fgets (string, 80, fp);
        if (x == (char *) NULL)
            return (0);

        if (*string == '#') /* a comment */
            continue;

        if (string[(int) strlen(string)-1] == '\n')
            string[(int) strlen(string)-1] = '\0'; /* NULL terminate*/

        length = (int) strlen(string);
        s=0;

        for (i=0; i < length; i++)
        {
            if (isspace (string[i]))
                s++;
            else
                break;
        }

        if (s)
        {
            char buf[81];
            (void) strcpy (buf, string+s);
            (void) strcpy(string,buf);
        }

        length = (int) strlen(string);
        for (i=(length-1); i >= 0; i--)
        {
            if (isspace(string[i]))
                string[i]='\0';
            else
                break;
        }
        return (1);
    }
    return (0);
}

/*
** from wusage 2.3
*/
void RemoveTrailingSp (string)
char
    *string;
{
    while (True)
    {
        int
            l;

        l = (int) strlen (string);
        if (!l)
            return;

        if (string[l-1] == ' ')
            string[l-1] = '\0';
        else
            return;
    }
}

/*
** duplicate a string
*/
char *mystrdup (string)
char
    *string;
{
    char
        *tmp;

    if (string == (char *) NULL)
        return ((char *) NULL);

    tmp = (char *) malloc ((int) strlen(string) + 1);

    if (tmp == (char *) NULL)
        return ((char *) NULL);

    (void) strcpy(tmp, string);
    return (tmp);
}

/*
** check if the data file has correct ownership
*/

/*
** Return values
** 0 - nothing matches (group or owner)
** 1 - owner of the file and the owner found in query string matches
** 2 - memory allocation problem
** 3 - owner of the file and the owner found in query string matches but
**     the group id of the child process of httpd and the group id of the
**     file does not match
*/

#ifdef _USE_ME_PLEASE_
int CheckOwner (owner,file)
char
    *owner;
char
    *file;
{
    char
        *tmp;

    struct stat
        statbuf;

    int
        uid,
        gid;

    struct passwd
        *p;

    tmp = mystrdup(owner);
    if (tmp == (char *) NULL)
        return 2;

    while ((p=getpwent()) != NULL)
    {
        if (strcmp(tmp, p->pw_name) == 0)
        {
            uid = p->pw_uid;                        
            stat(file, &statbuf);
            if (uid == statbuf.st_uid)
            {
                /*
                ** now check the group id of the child process of httpd
                ** and group id of the data file, they must match
                */
                gid = getgid();
                if (gid != statbuf.st_gid)
                {
                    char
                        buf[BUFSIZ];
                    *buf = '\0';
                    (void) sprintf (buf, "Group Id of the counter data file \"%s\" is %d, it should be %d, httpd's child processes run with group id %d",file,statbuf.st_gid,gid,gid);
                Warning(buf);
                (void) free ((char *) tmp);
                    return 3;
                }
                (void) free ((char *) tmp);
                return (1);
            }
            else
            {
                (void) free ((char *) tmp);
                return (0); 
            }
        } 
    }

    (void) free ((char *) tmp);
    return (0);
}
#endif /* _USE_ME_PLEASE */
/*
 *  ParseQueryString() - parses the QUERY_STRING for Count.cgi
 *
 *  RCS:
 *      $Revision$
 *      $Date$
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
 *      char        *qs
 *      DigitInfo   *digit_info
 *      FrameInfo   *frame_info
 *
 *  Output Parameters:
 *      type    identifier  description
 *
 *      DigitInfo   *digit_info
 *      FrameInfo   *frame_info
 *
 *  Return Values:
 *      value   description
 *      0   on success
 *      1   on failure
 *
 *  Side Effects:
 *      text
 *
 *  Limitations and Comments:
 *      text
 *
 *  Development History:
 *      who                 when        why
 *      muquit@semcor.com   22-Aug-95   first cut
 */


int ParseQueryString(qs, digit_info, frame_info)
char
    *qs;
DigitInfo
    *digit_info;
FrameInfo
    *frame_info;
{
    char
        query_string[MaxTextLength],
        buf1[50], 
        buf2[50], 
        buf3[50], 
        buf4[50], 
        buf5[50], 
        buf6[50],
        buf7[50],
        buf8[50],
        buf9[50],
        buf10[50];

    register char
        *p;

    int
        thickness,
        tr,
        width,
        height,
        maxdigits,
        r,
        g,
        b,
        trr,
        tg,
        tb,
        st,
        sh;

    int
        rc=0;

    *query_string='\0';
    *buf1='\0';
    *buf2='\0';
    *buf3='\0';
    *buf4='\0';
    *buf5='\0';
    *buf6='\0';
    *buf7='\0';
    *buf8='\0';
    *buf9='\0',
    *buf10='\0';

    (void) strcpy(query_string,qs);
    for (p=query_string; *p != '\0'; p++)
    {
        if ((*p == '=') || (*p == '|') || (*p == ';'))
            *p=' '; 
    }
    if (Gdebug == True)
    (void) fprintf (stderr," QUERY_STRING (tokenized): \n%s\n", query_string);

   rc=sscanf(query_string, "%s %d %s %d %d %d %s %d %s %d %d %d %s %d %d %s %d %s %s %s %d %s %d %s %s",
        buf1,&thickness,buf2,&r,&g,&b,buf3,&tr,buf4,&trr,&tg,&tb,
        buf5,&width,&height, buf6,&maxdigits,
        buf7,digit_info->ddhead,buf8,&st,buf9,&sh,buf10,digit_info->datafile);

    if (rc != 25)
    {
        rc=1;
        goto ExitProcessing;
    }
    
    if (strncmp(buf1,"ft",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf1 != ft\n");

        PrintHeader ();
        StringImage("Problem with ft in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    else
    {
        if (thickness < 0)
            thickness=AbsoluteValue(thickness);

        frame_info->width=thickness;
    }

    if (strncmp(buf2,"frgb",3) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf2 != frgb\n");

        PrintHeader ();
        StringImage("Problem with frgb in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    else
    {
        if (r < 0)
            r=0;
         else if (r > MaxRGB)
            r=MaxRGB;
        frame_info->matte_color.red=(unsigned char) r;
        
        if (g < 0)
            g=0;
         else if (g > MaxRGB)
            g=MaxRGB;

        frame_info->matte_color.green=(unsigned char) g;

        if (b < 0)
            b=0;
        else if (b > MaxRGB)
            b=MaxRGB;

        frame_info->matte_color.blue=(unsigned char) b;
    }

    /*
    ** tr=?
    */

    if (strncmp(buf3,"tr",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf3 != tr\n");

        PrintHeader();
        StringImage("Problem with tr in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    else
    {
        if ((tr != 0) && (tr != 1))
        {
        if (Gdebug == True)
            (void) fprintf (stderr," tr must be 0 or 1\n");

        PrintHeader();
        StringImage("tr must be 0 or 1 in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
        }

        switch(tr)
        {
            case 0:
            {
                digit_info->alpha=False;
                break;
            }
            case 1:
            {
                digit_info->alpha=True;
                break;
            }
        } 
    }

    /*
    ** trgb=?;?;?
    */
    if (strncmp(buf4,"trgb",4) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf4 != trgb\n");

        PrintHeader();
        StringImage("Problem with trgb in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    else
    {
        if (tr < 0)
            tr=0;
         else if (tr > MaxRGB)
            tr=MaxRGB;
        digit_info->alpha_red=(unsigned char) trr;
        
        if (tg < 0)
            tg=0;
         else if (tg > MaxRGB)
            tg=MaxRGB;
        digit_info->alpha_green=(unsigned char) tg;

        if (tb < 0)
            tb=0;
        else if (tb > MaxRGB)
            tb=MaxRGB;
        digit_info->alpha_blue=(unsigned char) tb;
    }

    /*
    ** wxh=??
    */
    if (strncmp(buf5,"wxh",3) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf5 != wxh\n");

        PrintHeader();
        StringImage("Problem with wxh in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    else
    {
        if (width < 0)
            width=AbsoluteValue(width);
        if (height < 0)
            height=AbsoluteValue(height);

        digit_info->width=(unsigned int) width;
        digit_info->height=(unsigned int) height;
    }

    if (strncmp(buf6,"md",2) != 0)
    {
        if (strncmp(buf6,"pad",3) != 0)
        {
        if (Gdebug == True)
            (void) fprintf (stderr," buf6 != md or pad\n");

        PrintHeader();
        StringImage("Problem with md in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
        }
        else
        {
            digit_info->leftpad=False;
            digit_info->maxdigits=0;
        }
    }
    else
    {
        if (maxdigits < 0)
            maxdigits=AbsoluteValue(maxdigits);
         digit_info->leftpad=True;
         digit_info->maxdigits=maxdigits;
    }

    if (strncmp(buf7,"dd",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf7 != dd\n");

        PrintHeader();
        StringImage("Problem with dd in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }

    if (strncmp(buf8,"st",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf8 != st\n");

        PrintHeader();
        StringImage("Problem with st in QUERY_STRING");
        rc=1;
        goto ExitProcessing;
    }
    else
        digit_info->st=st;

    if (strncmp(buf9,"sh",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf9 != sh\n");

        PrintHeader();
        StringImage("Problem with sh in QUERY_STIRNG");
        rc=1;
        goto ExitProcessing;
    }
    else
    {
        if ((sh != 0) && (sh != 1))
        {
            if (Gdebug == True)
                (void) fprintf (stderr," sh must be 0 or 1\n");

            PrintHeader();
            StringImage("sh must be 0 or 1 in QUERY_STRING");
            rc=1;
            goto ExitProcessing;
        }
        else
        {
            if (sh == 1)
                digit_info->show=True;
            else
                digit_info->show=False;
        }
    }
    if (strncmp(buf10,"df",2) != 0)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," buf10 != df\n");

        PrintHeader();
        StringImage("Problem with df in QUERY_STRING");
        rc=1; 
        goto ExitProcessing;
    }
    if (Gdebug == True)
    {
        (void) fprintf (stderr," \nparsed QS--\n");
        (void) fprintf (stderr," buf1=%s\n",buf1);
        (void) fprintf (stderr," ft=%d\n",thickness);
        (void) fprintf (stderr," buf2=%s\n",buf2);
        (void) fprintf (stderr," rgb=%d,%d,%d\n",r,g,b);
        (void) fprintf (stderr," buf3=%s\n",buf3);
        (void) fprintf (stderr," tr=%d\n",digit_info->alpha);
        (void) fprintf (stderr," buf4=%s\n",buf4);
        (void) fprintf (stderr," ar=%d\n",digit_info->alpha_red);
        (void) fprintf (stderr," ag=%d\n",digit_info->alpha_green);
        (void) fprintf (stderr," ab=%d\n",digit_info->alpha_blue);
        (void) fprintf (stderr," buf5=%s\n",buf5);
        (void) fprintf (stderr," wxh=%dx%d\n",width,height);
        (void) fprintf (stderr," buf6=%s\n",buf6);
        (void) fprintf (stderr," md=%d\n",maxdigits);
        (void) fprintf (stderr," buf7=%s\n",buf7);
        (void) fprintf (stderr," ddhead=%s\n",digit_info->ddhead);
        (void) fprintf (stderr," buf8=%s\n",buf8);
        (void) fprintf (stderr," st=%d\n",digit_info->st);
        (void) fprintf (stderr," buf9=%s\n",buf9);
        (void) fprintf (stderr," sh=%d\n",sh);
        (void) fprintf (stderr," buf10=%s\n",buf10);
        (void) fprintf (stderr," df=%s\n",digit_info->datafile);
        (void) fprintf (stderr," parsed QS--\n");

    }

    if (rc == 25)
        rc=0;

ExitProcessing:
    return(rc);
}

/*
** get current time
*/

char *GetTime ()
{
    time_t
        tm;

    char
        *times;

    tm = time (NULL);
    times = ctime(&tm);
    times[(int) strlen(times)-1] = '\0';
    return (times);
}

void Warning (message)
char
    *message;
{
    char
        *times;
    FILE
        *fp= (FILE *) NULL;
    char
        buf[1024];

    *buf='\0';
    (void) sprintf(buf,"%s/%s",LogDir,LogFile);
    times = GetTime();
    fp = fopen(buf, "a");

    if (fp == (FILE *) NULL)
    {
        (void) fprintf (stderr,"[%s] Count %s: Could not open CountLog file %s/%s\n ",times, Version, LogDir,LogFile);
        fp = stderr;
    }
        (void) fprintf (fp,"[%s] Count %s: %s\n", 
            times, Version,message);
    if (fp != stderr)
        (void) fclose (fp);
}

/*
 *  GetRemoteReferer - returns the remote referer
 *
 *  RCS:
 *      $Revision$
 *      $Date$
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
 *      char    *host       remote referer HTML
 *
 *
 *  Output Parameters:
 *      type    identifier  description
 *
 *      char    *rem_host   retuns the host
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
 *      muquit@semcor.com   12-Aug-95   first cut
 */

#include <stdio.h>
#include <string.h>

void GetRemoteReferer (host, rem_host)
char
    *host;
char
    *rem_host;
{
    register char
        *p,
        *q;

    int
        x;

    *rem_host = '\0';
    q=rem_host;

    for (p=host; *p != '\0'; p++)
    {
        if (*p == '/')
        {
            p += 2;
            break;
        }
    }
    while ((*p != '/') && (*p != '\0'))
        *q++ = *p++;

    *q = '\0';

    /*
    ** randerso@bite.db.uth.tmc.edu added the following lines of code
    ** to account for port numbers at the end of a url
    */

    x=0;
    while ((x < (int) strlen(rem_host)) && (rem_host[x] != ':'))
        x++;
    rem_host[x]='\0';
}

#ifdef USE_LOCK
#include <sys/file.h>
void SetLock (fd)
int
    fd;
{
#ifdef SYSV
    lseek(fd,0L,0);
    (void) lockf(fd,F_LOCK,0L);
#else
    (void) flock(fd,LOCK_EX);
#endif
}

void UnsetLock (fd)
int
    fd;
{
#ifdef SYSV
    lseek(fd,0L,0);
    (void) lockf(fd,F_ULOCK,0L);
#else
    (void) flock(fd,LOCK_UN);
#endif
}
#endif /*USE_LOCK*/

int CheckDirs()
{
    if ((strcmp(ConfigDir,DigitDir) == 0) ||
        (strcmp(ConfigDir,DataDir) == 0) ||
        (strcmp(ConfigDir,LogDir) == 0) ||
        (strcmp(ConfigDir,LogDir) == 0) ||
        (strcmp(DigitDir,DataDir) == 0) ||
        (strcmp(DigitDir,LogDir) == 0) ||
        (strcmp(DataDir,LogDir) == 0))
    return (1);
return (0);
}


/*
 *  CheckRemoteIP - checks if remote host in the ignore list
 *
 *  RCS:
 *      $Revision$
 *      $Date$
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
 *      True if the remote IP should be ignored (a match)
 *      False remote IP should be counted
 *
 *  Side Effects:
 *      text
 *
 *  Limitations and Comments:
 *      text
 *
 *  Development History:
 *      who                 when        why
 *      muquit@semcor.com   13-Sep-95   -
 */

unsigned int CheckRemoteIP(remote_ip,ip_ign)
char
    *remote_ip,
    *ip_ign;
{
    char
        tmp[10],
        buf[100],
        buf2[100];

    int
        x,
        y,
        z,
        w,
        xx,
        yy,
        zz,
        ww;

    int
        rc;

    *tmp='\0';
    *buf='\0';
    *buf2='\0';

    /*
    ** REMOTE_ADDR
    */

    (void) strcpy(buf,remote_ip);
    rc=sscanf(buf,"%d.%d.%d.%d",&xx,&yy,&zz,&ww);
    if (rc != 4)
        return(False);

    /*
    ** IP from conf file, we'll compare the remote IP with this one.
    ** we'll check for wildcard in the IP from conf file as well
    ** we'll check for all 3 classes of network
    */

    rc=sscanf(ip_ign,"%d.%d.%d.%d",&x,&y,&z,&w);
    if (rc != 4) /* possible wildcard */
    {
        /*
        ** check wildcard for a Class C network
        */
        if ((x >= 192) && (x <= 223))
        {
            /*
            ** we'r concerned with 4th octet
            */
            rc=sscanf(ip_ign,"%d.%d.%d.%s",&x,&y,&z,tmp);
            if (rc != 4) /* screwed up entry, don't ignore*/
                return (False);
            if (strcmp(tmp,"*") == 0)
            {
                if ((x == xx) &&
                    (y == yy) &&
                    (z == zz))
                {
                    return (True);
                }
            }
            else
                return (False);
        }
        else if ((x >= 128) && (x <= 191))
        {
            /*
            ** check wildcard for class B network
            ** we'll check the 3rd octet for wildcard
            */
            (void) fprintf (stderr," Class B\n");
            rc=sscanf(ip_ign,"%d.%d.%s",&x,&y,tmp);
            (void) fprintf (stderr," rc: %d\n",rc);
            (void) fprintf (stderr," tmp:%s\n",tmp);
            if (rc != 3)
                return (False);

            if ((strcmp(tmp,"*") == 0) ||
                (strcmp(tmp,"*.*") == 0))
            {
                (void) fprintf (stderr," xx,yy:%d,%d\n",xx,yy);
                if ((x == xx) &&
                    (y == yy))
                {
                    return (True);
                }
                else
                    return (False);
            }
        }
        else /* x < 128, got to be a Class A network */
        {
            /*
            ** we'll check the 2nd octet for wildcard
            */
            rc=sscanf(ip_ign,"%d.%s",&x,tmp);
            if (rc != 2)
                return (False);

            if ((strcmp(tmp,"*") == 0) ||
                (strcmp(tmp,"*.*") == 0) ||
                (strcmp(tmp,"*.*.*") == 0))
            {
                if (x == xx)
                    return (True);
                 else
                    return (False);
            }
        }
    }
    else
    {
        /*
        ** compare directly
        */
        if (strcmp(buf,ip_ign) == 0)
            return (True);
    }

return (False);
}
