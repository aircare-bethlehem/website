/*
 *	SyncImage()	-	initializes the red, green, and blue intensities of each
 *					pixel as defined by the colormap index.
 *
 *	RCS:
 *		$Revision: 1.3 $
 *		$Date: 1995/07/16 17:03:54 $
 *
 *	Security:
 *		Unclassified
 *
 *	Description:
 *		Adapted from ImageMagick
 *
 *	Input Parameters:
 *		type	identifier	description
 *
 *		text
 *
 *	Output Parameters:
 *		type	identifier	description
 *
 *		text
 *
 *	Return Values:
 *		value	description
 *
 *	Side Effects:
 *		text
 *
 *	Limitations and Comments:
 *		text
 *
 *	Development History:
 *		when	who		why
 *	3/28/94		mm		first cut
 */
#include "combine.h"
#include "defines.h"

void SyncImage(image)
Image
  *image;
{
  register int
    i;

  register Runlength
    *p;

  register unsigned short
    index;

  p=image->pixels;
  for (i=0; i < image->packets; i++)
  {
    index=p->index;
    p->red=image->colormap[index].red;
    p->green=image->colormap[index].green;
    p->blue=image->colormap[index].blue;
    p++;
  }
}
