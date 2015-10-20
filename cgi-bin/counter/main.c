/*
 *  WWW document access counter
 *
 *  RCS:
 *      $Revision: 1.3 $
 *      $Date: 1995/07/16 17:02:55 $
 *
 *  Security:
 *      Unclassified
 *
 *  Description:
 *     main routine for WWW homepage access counter
 *  
 *  Input Parameters:
 *      type    identifier  description
 *
 *      N/A
 *
 *  Output Parameters:
 *      type    identifier  description
 *
 *      N/A
 *
 *  Return Values:
 *      value   description
 *
 *  Side Effects:
 *      None
 *
 *  Limitations and Comments:
 *      None
 *
 *  Development History:
 *      who                 when        why
 *      muquit@semcor.com   10-Apr-95   first cut
 *      muquit@semcor.com   06-07-95    release 1.2
 *      muquit@semcor.com   07-13-95    release 1.3
 */

#define __Main__
#include "combine.h"
#include "count.h"
#include "config.h"

static char *ImagePrefix[]=
{
    "zero", "one", "two", "three", "four", "five", 
    "six", "seven", "eight", "nine",
};


void main (argc, argv)
int
    argc;
char
    **argv;

{
    int
        rc = 0;

    unsigned int
        ignore_site=False;

    register int
        i;

    char
        *remote_ip,
        *query_string;

    int
        n;

    int
        counter_length;

    int
        left_pad;

    char
        filename[MaxTextLength];

    char
        tmpbuf[MaxTextLength];

    char
        digitbuf[MaxTextLength];

    int
        fd;

    char
        format[10],
        buf[50];

    int
        count,
        counter;

    char
        Limit[50];

    int
        LimitDigits;

    int
        tagdigit;

    int
        MaxDigits=10;

    DigitInfo
        digit_info;

    FrameInfo
        frame_info;

    register char
        *p;


    unsigned int
        use_st;
#ifdef ACCESS_AUTH
    char
        *rem_refh;
#endif

/*
**---------initialize globals------Starts---
*/
    for (i=0; i < MaxSites; i++)
    {
        GrefererHost[i] = (char *) NULL;
        GignoreSite[i] = (char *) NULL;
    }
    Grhost=0;
    Gsite=0;
    Gdebug=False;
/*
**---------initialize globals------Ends---
*/
    count=1;
    *format='\0';
    *Limit = '\0';
    *buf='\0';
    *filename = '\0';
    *digitbuf='\0';
    *tmpbuf = '\0';
    counter = 0;
    tagdigit=9;
    left_pad=MaxDigits;
    use_st=False;

    /*
    ** parse command line, this is only used for testing at commandline
    ** no command line flag is allowed in the web page while calling
    ** the program
    */

    for (i=1; i < argc; i++)
    {
        if (!strncmp(argv[i],"-debug",(int)strlen("-debug")))
        {
            Gdebug=True;
            break;
        }
    }

    if (Gdebug == True)
    {
    (void) fprintf (stderr,"[%s] Count %s: --Debug Starts\n", 
        GetTime(), Version);
#ifdef USE_LOCK
    (void) fprintf (stderr," datafile locking is enabled\n");
#else
    (void) fprintf (stderr," datafile locking is disabled\n");
#endif /*USE_LOCK*/
    }

    rc=CheckDirs();
    if (rc == 1)
    {
        *tmpbuf='\0';
        (void) sprintf(tmpbuf,"ConfigDir,DigitDir,DataDir,LogDir must differ");
        Warning(tmpbuf);
        PrintHeader();
        StringImage(tmpbuf);
        exit(1);
    }

    /*
    ** parse the authorization list
    */
    rc = ParseAuthorizationList ();

    switch (rc)
    {
        case ConfigOpenFailed:
        {
            *tmpbuf='\0';
            (void) sprintf (tmpbuf, 
                "Faliled to open configuration file: \"%s/%s\"",
                    ConfigDir,ConfigFile);
            Warning (tmpbuf);
            PrintHeader ();
            StringImage (tmpbuf);
            exit(1);
            break;
        }

        case NoIgnoreHostsBlock:
        {
            *tmpbuf='\0';
            (void) sprintf (tmpbuf,
                "No IgnoreHosts Block in the configuration file: \"%s/%s\"",
                    ConfigDir,ConfigFile);

            Warning(tmpbuf);
            PrintHeader ();;
            StringImage(tmpbuf);
            exit(1);
        }

        case NoRefhBlock:
        {
            *tmpbuf='\0';
            (void) sprintf(tmpbuf,"Compiled with -DACCESS_AUTH,but no such block in configuration file!");
            Warning(tmpbuf);
            PrintHeader ();;
            StringImage(tmpbuf);
            exit(1);
        }

        case UnpexpectedEof:
        {
            *tmpbuf='\0';
            (void) sprintf (tmpbuf, 
            "Unexpected EOF in configuration file: \"%s/%s\"",
                ConfigDir,ConfigFile);
            Warning(tmpbuf);
            PrintHeader ();
            StringImage(tmpbuf);
            exit(1);
        }

    } /* switch (rc) */


    if (Gdebug == True)
        (void) fprintf (stderr," Gsite: %d\n", Gsite);

#ifdef ACCESS_AUTH
    /*
    ** check if the referer is a remote host or not. refere should
    ** be the local host.
    */

    rem_refh = getenv("HTTP_REFERER");
    if (rem_refh != (char *) NULL)
    {
        char
            http_ref[1024],
            Rhost[1024];
        *http_ref = '\0';
        *Rhost = '\0';
        /*
        ** this will be same as your host when accessed from your
        ** page. if the host is anything else, it is an unauthorized
        ** access. handle it.
        */
        (void) strcpy (http_ref, rem_refh);
        GetRemoteReferer(http_ref, Rhost);

        if (Gdebug == True)
        {
            (void) fprintf (stderr," Grhost:%d\n",Grhost);
            (void) fprintf (stderr," Rhost: %s\n",Rhost);
        }
        if (*Rhost != '\0')
        {
            if (Grhost > 0)
            {
                for (i=0; i < Grhost; i++)
                {
                    rc=strcmp(Rhost,GrefererHost[i]);
                    if (rc == 0)
                        break;
                }
            }
            if (rc != 0)
            {
                *tmpbuf='\0';
                (void) sprintf(tmpbuf,"Unauthorized Access denied to host: %s",Rhost);
                Warning(tmpbuf);                    
                PrintHeader();
                StringImage(tmpbuf);
                exit(1);
            }
        }
    }

#endif /* ACCESS_AUTH */
    /*
    ** get the user name from query string
    */
    query_string = getenv("QUERY_STRING");

    if (query_string == (char *) NULL)
    {
        *tmpbuf='\0';
        (void) sprintf(tmpbuf,"%s","Empty QUERY_STRING!");
        Warning(tmpbuf);
        PrintHeader ();
        StringImage(tmpbuf);
        exit(1);
    }

    rc=ParseQueryString(query_string,&digit_info,&frame_info);

    if (rc)
    {
        if (Gdebug == True)
            (void) fprintf (stderr," rc from ParseQueryString()=%d\n",rc);

        *tmpbuf='\0';
        (void) sprintf(tmpbuf,"%s: %s","Incorrect QUERY_STRING",query_string);
        Warning(tmpbuf);
        PrintHeader ();
        StringImage(tmpbuf);
        exit(1);
    }

    if (digit_info.leftpad == True)
    {
        MaxDigits=digit_info.maxdigits;

        if ((MaxDigits < 5) || (MaxDigits > 10))
        {
            Warning("Maxdigits (md) must be >= 5 and <= 10");
            PrintHeader ();
            StringImage("Maxdigits (md) must be >= 5 and <= 10");
            exit(1);
        }
    }

    if (checkfilename (digit_info.datafile) != 0)
    {
        *tmpbuf='\0';
        (void) sprintf (tmpbuf,
            "Counter datafile \"%s\" invalid!", digit_info.datafile);
        Warning(tmpbuf);
        PrintHeader ();
        StringImage(tmpbuf);
        exit(1);
    }

    (void) strcpy(filename, DataDir);
    (void) strcat(filename, "/");
    (void) strcat (filename, digit_info.datafile);

    /*
    ** check if the counter file exists or not
    */
#ifndef ALLOW_FILE_CREATION
    if (CheckFile (filename) != 0)
    {
        *tmpbuf='\0';
        (void) sprintf (tmpbuf,
            "Counter datafile \"%s\" must be created first!", filename);
        Warning(tmpbuf);
        PrintHeader ();
        StringImage (tmpbuf);
        exit(1);
    }
#endif

    /*
    ** get frameinfo
    */

    if (frame_info.width > 1)
        digit_info.Frame=True;
    else
        digit_info.Frame=False;
    /*
    ** get the IP address of the connected machine to check if we need
    ** to increment the counter
    */
    remote_ip = getenv("REMOTE_ADDR");
    if (remote_ip == (char *) NULL)
    {
        /*
        ** put a dummy here
        */
        remote_ip = "dummy_ip";
    }
    else
    {
        for (i=0; i < Gsite; i++)
        {
            ignore_site=CheckRemoteIP(remote_ip,GignoreSite[i]);
            if (ignore_site == True)
            {
                break;
            }
        }
    }

    /*
    ** initialize Limit array
    */


    if (Gdebug == True)
        (void) fprintf (stderr," MsxDigits=%d\n", MaxDigits);

    (void) sprintf (Limit, "%d", tagdigit);

    for (i=0; i < MaxDigits-1; i++)
        (void) sprintf (Limit, "%s%d", Limit,tagdigit);

    LimitDigits = atoi (Limit);

    if (Gdebug == True)
        (void) fprintf (stderr," Limit: %s\n", Limit);

#ifdef ALLOW_FILE_CREATION
    if (CheckFile (filename) != 0)
        use_st=True;
#endif
    fd = open (filename, O_RDWR | O_CREAT,0644);
    if (fd < 0)
    {
        *tmpbuf='\0';
#ifdef ALLOW_FILE_CREATION
        if (CheckFile (filename) != 0)
            (void) sprintf(tmpbuf,
                "Could not create data file: \"%s\"",filename);
        else
            (void) sprintf (tmpbuf,
                "Could not write to counter file: \"%s\"", filename);
#else
        (void) sprintf (tmpbuf,
            "Could not write to counter file: \"%s\"", filename);
#endif /* ALLOW_FILE_CREATION */

        Warning(tmpbuf);
        PrintHeader ();
        StringImage(tmpbuf);
        exit(1);
    }

#ifdef USE_LOCK
    SetLock(fd);
#endif
    /*
    ** try to read from the file
    */

    lseek(fd,0L,0);
    n = read(fd, buf, MaxDigits);

    if (n > 0)
    {


        /*
        ** check if the datafile is edited, NULL terminate at first non-digit
        */
        for (i=0; i < n; i++)
        {
            if (!isdigit(buf[i]))
            {
                buf[i]='\0';
                break;
            }
        }
        if (i == n)
            buf[n]='\0';

        if (*buf == '\0')
            counter=0;
        else
            counter = atoi(buf);
        *buf='\0';
        (void) sprintf(buf,"%d",counter);
        
        if (Gdebug == True)
            (void) fprintf (stderr," Counter before increment: %d\n", counter);

        if (counter == 0)
            counter_length = 1;
        else

        if (counter >= LimitDigits)
            counter= LimitDigits;
        if (counter != LimitDigits)
            counter++;
         (void) sprintf(buf, "%d", counter);
         counter_length = (int) strlen(buf);
        
        if (Gdebug == True)
            (void) fprintf (stderr," Counter after increment: %d\n", counter);

        if (ignore_site  == False)
        {
            lseek(fd,0L,0);
            (void) write(fd, buf, (int)strlen(buf));
            (void) close (fd); /*unlocks as well */
        }
    }
    else
    {

        if (Gdebug == True)
        {
            (void) fprintf (stderr," n < 0\n");
            (void) fprintf (stderr," Counter before increment: %d\n", counter);
        }

        if (use_st == True)
        {
            counter=digit_info.st;
            (void) sprintf(buf, "%d", counter);
        }
        else
        {
            counter++;
            (void) sprintf(buf, "%d", counter);
        }
        if (Gdebug == True)
            (void) fprintf (stderr," Counter after increment: %d\n", counter);

        lseek(fd,0L,0);
        write (fd, buf, (int) strlen(buf));
        (void) close (fd);
        counter_length = (int) strlen(buf);
    }

#ifdef USE_LOCK
    UnsetLock(fd);
#endif

    if (digit_info.show == False)
    {
        Image
            *image;

        image=CreateBaseImage(1,1,0,0,0,DirectClass);
        if (image == (Image *) NULL)
        {
            PrintHeader();
            StringImage("Failed to create 1x1 GIF image");
            exit(1);
        }

        AlphaImage(image,0,0,0);
        PrintHeader();
        (void) WriteGIFImage (image, (char *)NULL);
        DestroyAnyImageStruct (&image);
        exit(0);
    }

    if (Gdebug == True)
    {
        if (counter == LimitDigits)
            (void) fprintf (stderr," Counter reached it's limit!\n");
    }

if (digit_info.leftpad == False)
{
    (void)sprintf(digitbuf,"%s/%s/%s.gif",
        DigitDir,digit_info.ddhead,ImagePrefix[(int)*buf-'0']);

    for(p=buf+1; *p!='\0'; p++)
    {
        count++;
        (void) sprintf(digitbuf, "%s %s/%s/%s.gif",
            digitbuf,DigitDir,digit_info.ddhead, 
            ImagePrefix[(int)*p-'0']);
    }
    MaxDigits=count;
}
else
{
    if (counter_length < MaxDigits)
        left_pad = MaxDigits - counter_length;
    if (Gdebug == True)
    {
        (void) fprintf (stderr," MaxDigits: %d\n",MaxDigits);
        (void) fprintf (stderr," left_pad: %d\n", left_pad);
    }

    if ((left_pad < MaxDigits) && (left_pad != 0))
    {
        (void) sprintf(digitbuf, "%s/%s/%s.gif", 
            DigitDir,digit_info.ddhead,ImagePrefix[0]);
        for (i=1; i < left_pad; i++)
        {
            count++;
            (void) sprintf(digitbuf,"%s %s/%s/%s.gif", 
                digitbuf, DigitDir,digit_info.ddhead,ImagePrefix[0]);

        }

        for (p=buf; *p != '\0'; p++)
        {
            count++;
            (void) sprintf(digitbuf, "%s %s/%s/%s.gif",
                digitbuf,DigitDir,digit_info.ddhead,
                ImagePrefix[(int)*p-'0']);
        }
        MaxDigits=count;
    }
    else    /* MaxDigits*/
    {
        (void) fprintf (stderr," We'r in MaxDigits\n");

        for (p=buf; *p != '\0'; p++)
        {
            (void) sprintf(digitbuf, "%s %s/%s/%s.gif",
                digitbuf,DigitDir,digit_info.ddhead,
                ImagePrefix[(int)*p-'0']);
        }
    }

    if (Gdebug == True)
    {
        (void) fprintf (stderr," digitbuf: %s\n", digitbuf);
        (void) fprintf (stderr," MsxDigits=%d\n", MaxDigits);
    }
}
    /*
    ** now combine the digits and create one GIF file
    */

    digit_info.maxdigits=MaxDigits;
    WriteCounterImage(digitbuf, &digit_info,&frame_info);
    if (Gdebug == True)
    {
        (void) fprintf (stderr,"[%s] Count %s: --Debug Ends\n", 
            GetTime(), Version);
        (void) fprintf (stderr," MsxDigits=%d\n", MaxDigits);
    }

}

/*
 * checkfilename:
 * - check to see if a path was specified - return 1 if so, 0 otherwise
 * it might not be foolproof, but I can't come up with
 * any other ways to specify paths.
 * by carsten@group.com (07/27/95)
 */

int checkfilename(str)
char
    *str;
{
    while (*str)
    {
        if (*str == '/' || *str == '~')
            return 1;
        str ++;
    }
    return 0;
}

/*
** check if the counter file exists
*/

int CheckFile (filename)
char
    *filename;
{
    int
        rc=0;

    rc = access (filename, F_OK);
    return rc;
}

/*
** something went wrong..write the built in GIF image to stdout
*/

void SendErrorImage (bits, length)
unsigned char
    *bits;
int
    length;
{
    register unsigned char
        *p;

    register int
        i;

    p = bits;
    for (i=0; i < length; i++)
    {
        (void) fputc((char) *p, stdout);
        (void) fflush (stdout);
        p++;
    }
}

void PrintHeader ()
{
    if (Gdebug == False)
    {
        (void) fprintf (stdout,
            "Content-type: image/gif%c%c",LF,LF);
        (void) fflush (stdout);
    }
    return;
}

/*
** now combine the digits and create one single GIF image
*/
void WriteCounterImage (files,digit_info,frame_info)
char
    *files;
DigitInfo
    *digit_info;
FrameInfo
    *frame_info;
{
    Image
        *framed_image,
        *image;

    image = CombineImages(files,
        digit_info->maxdigits*digit_info->width,digit_info->height);

    if (image != (Image *) NULL)
    {
        if (digit_info->Frame == True)
        {
            RGB
               color,  
               matte_color;

            matte_color.red=frame_info->matte_color.red;
            matte_color.green=frame_info->matte_color.green;
            matte_color.blue=frame_info->matte_color.blue;
             
            frame_info->height=frame_info->width;
            frame_info->outer_bevel=(frame_info->width >> 2)+1;
            frame_info->inner_bevel=frame_info->outer_bevel;
            frame_info->x=frame_info->width;
            frame_info->y=frame_info->height;
            frame_info->width=image->columns+(frame_info->width << 1);
            frame_info->height=image->rows+(frame_info->height << 1);
            frame_info->matte_color=matte_color;

            XModulate(&color,matte_color.red,matte_color.green,
                matte_color.blue, HighlightModulate);
            frame_info->highlight_color.red=color.red;
            frame_info->highlight_color.green=color.green;
            frame_info->highlight_color.blue=color.blue;

            XModulate(&color,matte_color.red,matte_color.green,
                matte_color.blue, ShadowModulate);
            frame_info->shadow_color.red=color.red;
            frame_info->shadow_color.green=color.green;
            frame_info->shadow_color.green=color.green;

            framed_image=FrameImage(image,frame_info);
            if (framed_image != (Image *) NULL)
            {
                DestroyAnyImageStruct (&image);
                image=framed_image;
            }

        }

        image->comments = (char *) malloc (1024*sizeof(char));
        if (image->comments != (char *) NULL)
        {
            (void) sprintf(image->comments,"\n%s %s \n%s %s\n%s %s\n",
                "Count.cgi", Version, "By", Author, "URL:", Url);
        }
         if (digit_info->alpha == True)
             AlphaImage(image,digit_info->alpha_red,digit_info->alpha_green,
                digit_info->alpha_blue);
         PrintHeader ();
        (void) WriteGIFImage (image, (char *)NULL);
        DestroyAnyImageStruct (&image);
    }
    else
    {
        Warning("Failed to create digit images");
        PrintHeader ();
        StringImage("Failed! Check DigitDir in config.h or dd in QUERY_STRING");
        exit(1);
    }
}

