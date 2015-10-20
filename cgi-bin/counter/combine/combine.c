/*
 *  CombineImages - combines images and returns the final image
 *
 *  RCS:
 *      $Revision: 1.3 $
 *      $Date: 1995/07/16 17:03:54 $
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
 *      muquit@semcor.com   11-Jul-95   first cut
 */

#include "combine.h"
#include "defines.h"

Image *CombineImages (files,bwidth,bheight)
char
    *files;
unsigned int
    bwidth,
    bheight;
{
   char
        **p;

   char
        *buf[50];

   Image
        *base_image,
        *sub_image;

   unsigned int
        base_width,
        base_height;

   base_width= 0;
   base_height= 0;

   p = buf;
   while (*files != '\0')
   {
        while (*files == ' ')
            *files++ = '\0';

        *p++ = files;

        while ((*files != '\0') && (*files != ' '))
            files++;
   }
   *p = '\0';

   base_image = CreateBaseImage (bwidth,bheight,0,0,0,DirectClass);

   for (p=buf; *p != '\0'; p++)
   {
        sub_image = ReadImage (*p);
        if (sub_image != (Image *) NULL)
        {
#ifdef DEBUG
(void) fprintf (stderr," sub_image->alpha: %d\n",sub_image->alpha);
#endif
            FlattenImage (base_image, sub_image, 
                ReplaceCompositeOp,base_width, 0);
            base_width += sub_image->columns;
            DestroyAnyImageStruct(&sub_image);
        }
        else
        {
            (void) fprintf (stderr," FAILED Combining digits!\n");
             return ((Image *) NULL);
        }
   }
   

   if (base_image == (Image *) NULL)
        return ((Image *) NULL);

   return (base_image);
}
