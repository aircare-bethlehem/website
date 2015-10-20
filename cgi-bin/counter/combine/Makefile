#
# Makefile for GIF combining lib
# muquit@semcor.com
# 07-11-95
# 09-17-95 (Count 1.5)

CC= gcc
RM=rm -f
AR= ar cq

# for SYSV use RANLIB=echo
# RANLIB=echo
RANLIB= ranlib

INCDIR= -I. -I..

# replace -O with -g in order to debug
CDEBUGFLAGS= -O -D__USE_FIXED_PROTOTYPES__
CFLAGS= $(CDEBUGFLAGS) $(INCDIR)

SRCS = comnine.c crbasei.c allocim.c readgif.c rddata.c dstraimg.c\
       readblk.c lzwdec.c syncimg.c duplicim.c writegif.c lsbfwrs.c\
       lzenc.c uncmpimg.c readim.c flatten.c signature.c quantize.c\
       compimg.c rgbtran.c tranrgb.c compcmap.c frameim.c modulate.c\
       alphaim.c setpixel.c getfinfo.c imgstr.c gdfonts.c
OBJS = combine.o crbasei.o allocim.o readgif.o rddata.o dstraimg.o\
       readblk.o lzwdec.o syncimg.o duplicim.o writegif.o lsbfwrs.o\
       lzwenc.o uncmpimg.o readim.o flatten.o signature.o quantize.o\
       compimg.o rgbtran.o tranrgb.o compcmap.o frameim.o modulate.o\
       alphaim.o setpixel.o getfinfo.o imgstr.o gdfonts.o

.c.o:
	$(RM) $@
	$(CC) -c $(CFLAGS) $*.c

all: libCombine.a

libCombine.a: $(OBJS)
	$(RM) $@
	$(AR) $@ $(OBJS)
	$(RANLIB) $@

combine.o: combine.h

clean:
	$(RM) *.o libCombine.a core
