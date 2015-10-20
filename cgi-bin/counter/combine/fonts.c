/*
*	font.c()	-	description
*
*	RCS:
*		$Revision$
*		$Date$
*
*	Security:
*		Unclassified
*
*	Description:
*		Adapted from showtime
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
*	08/27/94	muquit	first cut
*/

int
	cols_font_char[128];

int
	rows_font_char[128];

int

unsigned char 
	*font_char[128];

#include "allf.h"

void InitializeFonts()
{
	cols_font_char[100] = cols_font_char100;
	rows_font_char[100] = rows_font_char100;
	font_char[100] = font_char100;

	cols_font_char[101] = cols_font_char101;
	rows_font_char[101] = rows_font_char101;
	font_char[101] = font_char101;

	cols_font_char[102] = cols_font_char102;
	rows_font_char[102] = rows_font_char102;
	font_char[102] = font_char102;

	cols_font_char[103] = cols_font_char103;
	rows_font_char[103] = rows_font_char103;
	font_char[103] = font_char103;

	cols_font_char[104] = cols_font_char104;
	rows_font_char[104] = rows_font_char104;
	font_char[104] = font_char104;

	cols_font_char[105] = cols_font_char105;
	rows_font_char[105] = rows_font_char105;
	font_char[105] = font_char105;

	cols_font_char[106] = cols_font_char106;
	rows_font_char[106] = rows_font_char106;
	font_char[106] = font_char106;

	cols_font_char[107] = cols_font_char107;
	rows_font_char[107] = rows_font_char107;
	font_char[107] = font_char107;

	cols_font_char[108] = cols_font_char108;
	rows_font_char[108] = rows_font_char108;
	font_char[108] = font_char108;

	cols_font_char[109] = cols_font_char109;
	rows_font_char[109] = rows_font_char109;
	font_char[109] = font_char109;

	cols_font_char[110] = cols_font_char110;
	rows_font_char[110] = rows_font_char110;
	font_char[110] = font_char110;

	cols_font_char[111] = cols_font_char111;
	rows_font_char[111] = rows_font_char111;
	font_char[111] = font_char111;

	cols_font_char[112] = cols_font_char112;
	rows_font_char[112] = rows_font_char112;
	font_char[112] = font_char112;

	cols_font_char[113] = cols_font_char113;
	rows_font_char[113] = rows_font_char113;
	font_char[113] = font_char113;

	cols_font_char[114] = cols_font_char114;
	rows_font_char[114] = rows_font_char114;
	font_char[114] = font_char114;

	cols_font_char[115] = cols_font_char115;
	rows_font_char[115] = rows_font_char115;
	font_char[115] = font_char115;

	cols_font_char[116] = cols_font_char116;
	rows_font_char[116] = rows_font_char116;
	font_char[116] = font_char116;

	cols_font_char[117] = cols_font_char117;
	rows_font_char[117] = rows_font_char117;
	font_char[117] = font_char117;

	cols_font_char[118] = cols_font_char118;
	rows_font_char[118] = rows_font_char118;
	font_char[118] = font_char118;

	cols_font_char[119] = cols_font_char119;
	rows_font_char[119] = rows_font_char119;
	font_char[119] = font_char119;

	cols_font_char[120] = cols_font_char120;
	rows_font_char[120] = rows_font_char120;
	font_char[120] = font_char120;

	cols_font_char[121] = cols_font_char121;
	rows_font_char[121] = rows_font_char121;
	font_char[121] = font_char121;

	cols_font_char[122] = cols_font_char122;
	rows_font_char[122] = rows_font_char122;
	font_char[122] = font_char122;

	cols_font_char[123] = cols_font_char123;
	rows_font_char[123] = rows_font_char123;
	font_char[123] = font_char123;

	cols_font_char[124] = cols_font_char124;
	rows_font_char[124] = rows_font_char124;
	font_char[124] = font_char124;

	cols_font_char[125] = cols_font_char125;
	rows_font_char[125] = rows_font_char125;
	font_char[125] = font_char125;

	cols_font_char[126] = cols_font_char126;
	rows_font_char[126] = rows_font_char126;
	font_char[126] = font_char126;

	cols_font_char[32] = cols_font_char32;
	rows_font_char[32] = rows_font_char32;
	font_char[32] = font_char32;

	cols_font_char[33] = cols_font_char33;
	rows_font_char[33] = rows_font_char33;
	font_char[33] = font_char33;

	cols_font_char[34] = cols_font_char34;
	rows_font_char[34] = rows_font_char34;
	font_char[34] = font_char34;

	cols_font_char[35] = cols_font_char35;
	rows_font_char[35] = rows_font_char35;
	font_char[35] = font_char35;

	cols_font_char[36] = cols_font_char36;
	rows_font_char[36] = rows_font_char36;
	font_char[36] = font_char36;

	cols_font_char[37] = cols_font_char37;
	rows_font_char[37] = rows_font_char37;
	font_char[37] = font_char37;

	cols_font_char[38] = cols_font_char38;
	rows_font_char[38] = rows_font_char38;
	font_char[38] = font_char38;

	cols_font_char[39] = cols_font_char39;
	rows_font_char[39] = rows_font_char39;
	font_char[39] = font_char39;

	cols_font_char[40] = cols_font_char40;
	rows_font_char[40] = rows_font_char40;
	font_char[40] = font_char40;

	cols_font_char[41] = cols_font_char41;
	rows_font_char[41] = rows_font_char41;
	font_char[41] = font_char41;

	cols_font_char[42] = cols_font_char42;
	rows_font_char[42] = rows_font_char42;
	font_char[42] = font_char42;

	cols_font_char[43] = cols_font_char43;
	rows_font_char[43] = rows_font_char43;
	font_char[43] = font_char43;

	cols_font_char[44] = cols_font_char44;
	rows_font_char[44] = rows_font_char44;
	font_char[44] = font_char44;

	cols_font_char[45] = cols_font_char45;
	rows_font_char[45] = rows_font_char45;
	font_char[45] = font_char45;

	cols_font_char[46] = cols_font_char46;
	rows_font_char[46] = rows_font_char46;
	font_char[46] = font_char46;

	cols_font_char[47] = cols_font_char47;
	rows_font_char[47] = rows_font_char47;
	font_char[47] = font_char47;

	cols_font_char[48] = cols_font_char48;
	rows_font_char[48] = rows_font_char48;
	font_char[48] = font_char48;

	cols_font_char[49] = cols_font_char49;
	rows_font_char[49] = rows_font_char49;
	font_char[49] = font_char49;

	cols_font_char[50] = cols_font_char50;
	rows_font_char[50] = rows_font_char50;
	font_char[50] = font_char50;

	cols_font_char[51] = cols_font_char51;
	rows_font_char[51] = rows_font_char51;
	font_char[51] = font_char51;

	cols_font_char[52] = cols_font_char52;
	rows_font_char[52] = rows_font_char52;
	font_char[52] = font_char52;

	cols_font_char[53] = cols_font_char53;
	rows_font_char[53] = rows_font_char53;
	font_char[53] = font_char53;

	cols_font_char[54] = cols_font_char54;
	rows_font_char[54] = rows_font_char54;
	font_char[54] = font_char54;

	cols_font_char[55] = cols_font_char55;
	rows_font_char[55] = rows_font_char55;
	font_char[55] = font_char55;

	cols_font_char[56] = cols_font_char56;
	rows_font_char[56] = rows_font_char56;
	font_char[56] = font_char56;

	cols_font_char[57] = cols_font_char57;
	rows_font_char[57] = rows_font_char57;
	font_char[57] = font_char57;

	cols_font_char[58] = cols_font_char58;
	rows_font_char[58] = rows_font_char58;
	font_char[58] = font_char58;

	cols_font_char[59] = cols_font_char59;
	rows_font_char[59] = rows_font_char59;
	font_char[59] = font_char59;

	cols_font_char[60] = cols_font_char60;
	rows_font_char[60] = rows_font_char60;
	font_char[60] = font_char60;
	cols_font_char[61] = cols_font_char61;
	rows_font_char[61] = rows_font_char61;
	font_char[61] = font_char61;

	cols_font_char[62] = cols_font_char62;
	rows_font_char[62] = rows_font_char62;
	font_char[62] = font_char62;

	cols_font_char[63] = cols_font_char63;
	rows_font_char[63] = rows_font_char63;
	font_char[63] = font_char63;

	cols_font_char[64] = cols_font_char64;
	rows_font_char[64] = rows_font_char64;
	font_char[64] = font_char64;

	cols_font_char[65] = cols_font_char65;
	rows_font_char[65] = rows_font_char65;
	font_char[65] = font_char65;

	cols_font_char[66] = cols_font_char66;
	rows_font_char[66] = rows_font_char66;
	font_char[66] = font_char66;

	cols_font_char[67] = cols_font_char67;
	rows_font_char[67] = rows_font_char67;
	font_char[67] = font_char67;

	cols_font_char[68] = cols_font_char68;
	rows_font_char[68] = rows_font_char68;
	font_char[68] = font_char68;

	cols_font_char[69] = cols_font_char69;
	rows_font_char[69] = rows_font_char69;
	font_char[69] = font_char69;

	cols_font_char[70] = cols_font_char70;
	rows_font_char[70] = rows_font_char70;
	font_char[70] = font_char70;

	cols_font_char[71] = cols_font_char71;
	rows_font_char[71] = rows_font_char71;
	font_char[71] = font_char71;

	cols_font_char[72] = cols_font_char72;
	rows_font_char[72] = rows_font_char72;
	font_char[72] = font_char72;

	cols_font_char[73] = cols_font_char73;
	rows_font_char[73] = rows_font_char73;
	font_char[73] = font_char73;

	cols_font_char[74] = cols_font_char74;
	rows_font_char[74] = rows_font_char74;
	font_char[74] = font_char74;

	cols_font_char[75] = cols_font_char75;
	rows_font_char[75] = rows_font_char75;
	font_char[75] = font_char75;

	cols_font_char[76] = cols_font_char76;
	rows_font_char[76] = rows_font_char76;
	font_char[76] = font_char76;

	cols_font_char[77] = cols_font_char77;
	rows_font_char[77] = rows_font_char77;
	font_char[77] = font_char77;

	cols_font_char[78] = cols_font_char78;
	rows_font_char[78] = rows_font_char78;
	font_char[78] = font_char78;

	cols_font_char[79] = cols_font_char79;
	rows_font_char[79] = rows_font_char79;
	font_char[79] = font_char79;

	cols_font_char[80] = cols_font_char80;
	rows_font_char[80] = rows_font_char80;
	font_char[80] = font_char80;

	cols_font_char[81] = cols_font_char81;
	rows_font_char[81] = rows_font_char81;
	font_char[81] = font_char81;

	cols_font_char[82] = cols_font_char82;
	rows_font_char[82] = rows_font_char82;
	font_char[82] = font_char82;

	cols_font_char[83] = cols_font_char83;
	rows_font_char[83] = rows_font_char83;
	font_char[83] = font_char83;

	cols_font_char[84] = cols_font_char84;
	rows_font_char[84] = rows_font_char84;
	font_char[84] = font_char84;
	cols_font_char[85] = cols_font_char85;
	rows_font_char[85] = rows_font_char85;
	font_char[85] = font_char85;

	cols_font_char[86] = cols_font_char86;
	rows_font_char[86] = rows_font_char86;
	font_char[86] = font_char86;

	cols_font_char[87] = cols_font_char87;
	rows_font_char[87] = rows_font_char87;
	font_char[87] = font_char87;

	cols_font_char[88] = cols_font_char88;
	rows_font_char[88] = rows_font_char88;
	font_char[88] = font_char88;

	cols_font_char[89] = cols_font_char89;
	rows_font_char[89] = rows_font_char89;
	font_char[89] = font_char89;

	cols_font_char[90] = cols_font_char90;
	rows_font_char[90] = rows_font_char90;
	font_char[90] = font_char90;

	cols_font_char[91] = cols_font_char91;
	rows_font_char[91] = rows_font_char91;
	font_char[91] = font_char91;

	cols_font_char[92] = cols_font_char92;
	rows_font_char[92] = rows_font_char92;
	font_char[92] = font_char92;

	cols_font_char[93] = cols_font_char93;
	rows_font_char[93] = rows_font_char93;
	font_char[93] = font_char93;

	cols_font_char[94] = cols_font_char94;
	rows_font_char[94] = rows_font_char94;
	font_char[94] = font_char94;

	cols_font_char[95] = cols_font_char95;
	rows_font_char[95] = rows_font_char95;
	font_char[95] = font_char95;

	cols_font_char[96] = cols_font_char96;
	rows_font_char[96] = rows_font_char96;
	font_char[96] = font_char96;

	cols_font_char[97] = cols_font_char97;
	rows_font_char[97] = rows_font_char97;
	font_char[97] = font_char97;

	cols_font_char[98] = cols_font_char98;
	rows_font_char[98] = rows_font_char98;
	font_char[98] = font_char98;

	cols_font_char[99] = cols_font_char99;
	rows_font_char[99] = rows_font_char99;
	font_char[99] = font_char99;

}

