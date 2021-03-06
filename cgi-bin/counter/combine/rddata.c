/*
 *	Read_Data()	-	Reads data from an image file
 *
 *	RCS:
 *		$Revision: 1.3 $
 *		$Date: 1995/07/16 17:03:54 $
 *
 *	Security:
 *		Unclassified
 *
 *	Description:
 *		this function reads data from a gray scale image file
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
 *		0		on success;
 *		1		on failure
 *
 *	Side Effects:
 *		text
 *
 *	Limitations and Comments:
 *		text
 *
 *	Development History:
 *		when	who		why
 *		8/31/93, mm, first cut
 */

#include "combine.h"

int Read_Data (data, size, number_items,file)

char
	*data;

int size,
	number_items;

FILE
	*file;
{
	int
		rc=0;

	size*=number_items;

	while (size > 0)
	{
		number_items = fread(data,1,size,file);

		if (number_items <= 0)	/* Error */
		{
			rc=1;
			goto ExitProcessing;
		}	

	size-= number_items;
	data+= number_items;
	}

ExitProcessing:
	return(rc);
}
