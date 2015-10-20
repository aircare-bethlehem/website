/*
 *	combine.h	-	Header file for combine librarly
 *
 *	RCS:
 *		$Revision: 1.3 $
 *		$Date: 1995/07/16 17:03:54 $
 *
 *	Security:
 *		Unclassified
 *
 *	Description:
 *		This file contains all necessary definitions, typedefs for
 *		xnitfview program
 *
 *	Dependencies:
 *		None
 *
 *	Comments:
 *		text
 *
 *	Development History:
 *		when	who		why
 *  07-11-95    muquit  first cut
 */

#ifndef COMBINE_H
#define COMBINE_H
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <memory.h>
#include <ctype.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "defines.h"

#if __STDC__ || defined(sgi) || defined(_AIX)
#define _FD(formal_parameters) formal_parameters
#else
#define	const
#define	_FD(formal_parameters) ()
#endif

/*
** structs
*/

typedef struct _RectangleInfo
{
	unsigned int
		width,
		height;

	int
		x,
		y;
} RectangleInfo;

typedef struct _EllipseInfo
{
    int
        line_style;
    int
        line_thickness;

    int
        semimajor_axis,
        semiminor_axis;

    int
        centerX,
        centerY;

    unsigned  int
        fill;

    int
        edge_red,
        edge_green,
        edge_blue;

    int
        fill_red,
        fill_green,
        fill_blue;

     int
        rotation;
} EllipseInfo;


typedef struct _RGB
{
	unsigned char
		red,
		green,
		blue,
		flags;

	unsigned short
		index;
} RGB;

typedef struct _Runlength
{
	unsigned char
		red,
		green,
		blue,
		length;

	unsigned short
		index;
} Runlength;

typedef struct _FrameInfo
{
    int
        x,
        y;

    int
        inner_bevel,
        outer_bevel;

    unsigned int
        width,
        height;
    RGB
        matte_color,
        highlight_color,
        shadow_color;

} FrameInfo;

typedef struct _Image
{
	char
		filename[2048];

	FILE
		*fp;

	RGB
		*colormap;

	unsigned int
		colors;

	char 
		type[12],
		*comments;

	unsigned int
		rows,
		columns,
		xorig,
		yorig,
		id,
		alpha,
		class,
		scene,
		compression;

	char
		*signature;

	Runlength
		*pixels;

	unsigned int
		runlength,
		pack_siz;

	unsigned long
		packets;
} Image;

typedef struct _Diversity
{
	unsigned char
		red,
		green,
		blue;

	unsigned short
		index;

	unsigned long
		count;
} Diversity;

typedef struct _ImageInfo
{
    char
        filename[256];

    unsigned int
        interlace;

} ImageInfo;

/*
** font struct from gd library
*/

typedef struct _gdFont
{
    /*
    ** # of characters in font
    */
    int
        nchars;
    /*
    ** First character is numbered... (usually 32 = space)
    */
    int
        offset;
    /*
    ** Character width and height
    */
    int
        w;
    int
        h;
    /*
    ** Font data; array of characters, one row after another.
    ** Easily included in code, also easily loaded from
    ** data files.
    */
    char
        *data;
} gdFont;

typedef gdFont
    *gdFontPtr;

typedef struct _SFontInfo
{
    unsigned int
        do_bg;

    unsigned char
        fgr,
        fgg,
        fgb;

    unsigned char
        bgr,
        bgg,
        bgb;

} SFontInfo;
/*
** forward declaration
*/

Image
    *CreateBaseImage _FD ((unsigned int, unsigned int, int, int, int,
        unsigned int));

void 
    FlattenImage _FD ((Image *, Image *, unsigned int, int, int));

void
    ColormapSignature _FD ((Image *));

Image
    *AllocateImageStruct _FD((void));

void
    DestroyAnyImageStruct _FD ((Image **));

int
    Read_Data _FD ((char *, int, int, FILE *));

int
    ReadDataBlock _FD ((char *, FILE *));

int
    LZWDecodeImage _FD ((Image *));

void
    SyncImage _FD ((Image *));

Image
    *DuplicateImage _FD ((Image *, unsigned int, unsigned int, unsigned int));

int
    WriteGIFImage _FD ((Image *, char *));

void
    LSBFirstWriteShort _FD ((unsigned int, FILE *));

unsigned int
    LZWEncodeImage _FD ((Image *, unsigned int));

unsigned int
    UncompressImage _FD ((Image *));

Image
    *ReadImage _FD ((char *));

int
    ReadGIFImage _FD ((Image *));

Image
    *CombineImages _FD ((char *,unsigned int, unsigned int));

void
    CompressImage _FD ((Image *));

void
    QuantizeImage _FD ((Image *, unsigned int, unsigned int, unsigned int,
        unsigned int, unsigned int));

void
    RGBTransformImage _FD ((Image *, unsigned int));

void
    TransformRGBImage _FD ((Image *, unsigned int));

void
    CompressColormap _FD ((Image *));

void
    Fputc _FD ((char, FILE *));

Image
    *FrameImage _FD((Image *, FrameInfo *));

void
    XModulate _FD((RGB *, unsigned char, unsigned char, unsigned char, int));

void
    AlphaImage _FD((Image *, unsigned char, unsigned char, unsigned char));

void
    GetFrameInfo _FD ((unsigned int, unsigned int, FrameInfo *));

void
    ImageString _FD ((Image *, gdFontPtr, int, int, char *, SFontInfo *));

void
    ImaegChar _FD ((Image *, gdFontPtr, int, int, char, SFontInfo));

void
    SetPixel _FD ((Image *,int, int,SFontInfo *,unsigned int));

#endif /* COMBINE_H */
