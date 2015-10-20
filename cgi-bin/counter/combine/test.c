#include "combine.h"
#include "defines.h"
#include "gdfonts.h"

void main(argc,argv)
int
    argc;
char
    *argv[];
{
    Image
        *fimage,
        *image;

    int
        i,
        j,
        k,
        x,
        y,
        z;
    char
        string[100];

    FrameInfo
        frame_info;

    SFontInfo
        font_info;

    (void) strcpy(string, argv[1]);

    image=CreateBaseImage(gdFontSmall->w*(int)strlen(string)+2,
        gdFontSmall->h+2,0,0,0,DirectClass);
    if (image == (Image *) NULL)
    {
        (void) fprintf (stderr,"Failed to create base image!\n");
        exit(1);
    }

    font_info.do_bg=True;
    font_info.bgr=0;
    font_info.bgg=0;
    font_info.bgb=0;

    font_info.fgr=255;
    font_info.fgg=255;
    font_info.fgb=0;

    ImageString(image,gdFontSmall,1,1,string,&font_info);
    GetFrameInfo(image->columns,image->rows,&frame_info);
    fimage=FrameImage(image,&frame_info);
    if (fimage != (Image *) NULL)
    {
        DestroyAnyImageStruct(&image);
        image=fimage;
    }
    (void) WriteGIFImage (image,(char *) NULL);
}
