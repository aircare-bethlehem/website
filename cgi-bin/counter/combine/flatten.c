/*
 *	FlattenImage()	-	flattens images
 *
 *	RCS:
 *		$Revision: 1.3 $
 *		$Date: 1995/07/16 17:03:54 $
 *
 *	Security:
 *		Unclassified
 *
 *	Description:
 *      Adapted from ImageMagick
 *
 *	Input Parameters:
 *		type	identifier	description
 *
 *		Image *baseimage	 base image struct
 *		Image *subimage		 subimage struct 
 *	    unsigned int compose composite operator 
 *		int x_offset		 x offset from upper left corner, + rightward
 *		int y_offset		 y offset from upper left corner, + downward 
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
 *	08/26/94	muquit	first cut
 */

#include "combine.h"
#include "defines.h"

void FlattenImage(baseimage,subimage,compose,x_offset,y_offset)
Image
	*baseimage;

Image
	*subimage;

unsigned int
	compose;

int
	x_offset,
	y_offset;
{
int
	blue,
	green,
	red;

register int
	i,
	x,
	y;

register Runlength
	*p,
	*q;

register short
	index;

    blue=red=green=MaxRGB;
    index=0;

	if (((x_offset+(int) baseimage->columns) < 0) ||
		((y_offset+(int) baseimage->rows) < 0) ||
		(x_offset > (int) baseimage->columns) || 
		(y_offset > (int) baseimage->rows))
	{
      (void) fprintf (stderr,
        "Unable to flatten image!\n");
      return;
	}

	if (!UncompressImage(baseimage))
		return;
#ifdef XDEBUG
    switch (baseimage->class)
    {
        case PseudoClass:
        {
            fprintf (stderr, "Base Image Class: PseudoClass\n");
            break;
        }

        case DirectClass:
        {
            fprintf (stderr, "Base Image Class: DirectClass\n");
            break;
        }
    }

    switch (subimage->class)
    {
        case PseudoClass:
        {
            fprintf (stderr, "Sub Image Class: PseudoClass\n");
            break;
        }

        case DirectClass:
        {
            fprintf (stderr, "Sub Image Class: DirectClass\n");
            break;
        }

    }
#endif

	if (compose == ReplaceCompositeOp)
    {
	  /*
	  ** promote image to DirectClass if colormap differs
	  */

      if (baseimage->class == PseudoClass)
        if (subimage->class == DirectClass)
          baseimage->class=DirectClass;
        else
          {
            if (baseimage->signature == (char *) NULL)
              ColormapSignature(baseimage);
            if (subimage->signature == (char *) NULL)
              ColormapSignature(subimage);
            if (strcmp(baseimage->signature,subimage->signature) != 0)
              baseimage->class=DirectClass;
          }
          if (baseimage->alpha && !subimage->alpha)
          {
            p=subimage->pixels;
            for (i=0; i < subimage->packets; i++)
            {
                p->index=Opaque;
                p++;
            }
            subimage->class=DirectClass;
            subimage->alpha=True;
          }
    }
  else
    {

	/*
	** initialize alpha channel of the image
	*/
		if (!baseimage->alpha)
		{
			q=baseimage->pixels;
			red = q->red;
			green = q->green;
			blue = q->blue;

			for (i=0; i < baseimage->packets; i++)
			{
				q->index = MaxRGB;
				if ((q->red == red) && 
					(q->green == green) && 
					(q->blue == blue))
					q->index = 0;
				q++;
			}
			baseimage->class = DirectClass;
			baseimage->alpha = True;
		}

		if (!subimage->alpha)
		{
			p = subimage->pixels;
			red = p->red;
			green = p->green;
			blue = p->blue;

			for (i=0; i < subimage->packets; i++)
			{
				p->index = MaxRGB;
				if ((p->red == red) && 
					(p->green == green) && 
					(p->blue == blue))
					p->index = 0;
				p++;
			}
			subimage->class = DirectClass;
			subimage->alpha = True;
		}
	

    }
#ifdef XDEBUG
	switch (baseimage->class)
	{
		case PseudoClass:
		{
			fprintf (stderr, "Base Image Class: PseudoClass\n");
			break;
		}
		
		case DirectClass:
		{
			fprintf (stderr, "Base Image Class: DirectClass\n");
			break;
		}
	}

	switch (subimage->class)
	{
        case PseudoClass:
        {
            fprintf (stderr, "Sub Image Class: PseudoClass\n");
            break;
        }
        
        case DirectClass:
        {
            fprintf (stderr, "Sub Image Class: DirectClass\n");
            break;
        }

	}
#endif

#ifdef DEBUG
(void) fprintf (stderr," flatten: subimage->alpha: %d\n",subimage->alpha);
#endif

	p=subimage->pixels;
	subimage->runlength=p->length+1;

	for (y=0; y < subimage->rows; y++)
	{
    	if (((y_offset+y) < 0) || ((y_offset+y) >= baseimage->rows))
      	continue;

    	q=baseimage->pixels+(y_offset+y)*baseimage->columns+x_offset;

    	for (x=0; x < subimage->columns; x++)
    	{
      	if (subimage->runlength != 0)
        	subimage->runlength--;
      	else
		{
			p++;
			subimage->runlength=p->length;
		}

		if (((x_offset+x) < 0) || ((x_offset+x) >= baseimage->columns))
		{
			q++;
			continue;
		}

	/*
	** Now handle compositing
	*/

	switch (compose)
	{
        /*
        ** make black pixels [r,g,b=(0,0,0)] of the sub_image transparent
        ** NOTE: NITFS black is 1, 1, 1, so we do not have to worry
        ** about entities having black colors, because it will be 1,1,1, not
        ** 0,0,0
        */
      
        case BlackTransparentOp:
        {
            if (((int)p->red == 0) && ((int)p->green == 0) &&
                ((int)p->blue == 0))
            {
                /*
                ** these pixels are transparent, i.e., keep the pixels of
                ** the base image intact
                */
         
                red = (int) q->red;
                green = (int) q->green;
                blue = (int) q->blue;
            }       
            else
            {
                /*
                ** these pixels are opaque..
                ** replace these pixels of the base image by subimage
                */
        
                red = (int) p->red;   
                green = (int) p->green;
                blue = (int) p->blue;
            }
            break;
        }   /* end case BlackTransparentOp*/

		case ReplaceCompositeOp:
		{
			/*
			** these pixels of the sub_image are opaque, replace the
			** pixels of the base image with these
			*/

			red=p->red;
			green=p->green;
			blue=p->blue;
			index=p->index;
			break;
			}
	}	/* end switch */

	  /*
	  ** do some checking anyway
	  */

      if (red > MaxRGB)
        q->red=MaxRGB;
      else
        if (red < 0)
          q->red=0;
        else
          q->red=red;
      if (green > MaxRGB)
        q->green=MaxRGB;
      else
        if (green < 0)
          q->green=0;
        else
          q->green=green;
      if (blue > MaxRGB)
        q->blue=MaxRGB;
      else
        if (blue < 0)
          q->blue=0;
        else
          q->blue=blue;
      if (index > 255)
        q->index=255;
      else
        if (index < 0)
          q->index=0;
        else
          q->index=index;
      q->length=0;
      q++;
    }
  }
}
