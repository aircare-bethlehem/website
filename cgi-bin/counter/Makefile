#####
# Makefile for WWW Access counter
# by Muhammad A Muquit
# 04/10/95, muquit@semcor.com
# http://www.semcor.com/~muquit/
# updated for Count 1.2 06/06/95, --muquit
# updated for Count 1.5 09/17/95, -- muquit
#####

#######################################################################
# if you are on a SYSV machine, add -DSYSV to CFLAGS
##

#######################################################################
# if you do not want Datafile locking facility, remove -DUSE_LOCK option
# from CFLAGS. Please Note, if you are on a SYSV machine and you use this
# option, you must also add -DSYSV option to CFLAGS
##

#######################################################################
# If you want to deny unauthorized access to the counter program add the
# flag -DACCESS_AUTH to CFLAGS. If you add this option, edit the 
# configuration file and a block with your host names. Please do not forget
# this, otherwise you will get unauthorized access denied message. Look at the
# sample count.conf file. 
##

#######################################################################
# If you do not want to create data file for user, add -DALLOW_FILE_CREATION
# flag to CFLAGS. If you compile with that flag, data file will be created
# if it does not exist and the value defined in run-time with st will be
# written to the data file. Make sure the data directory has write 
# permission for httpd
##

CC= gcc 
CFLAGS= -O -D__USE_FIXED_PROTOTYPES__ -DACCESS_AUTH\
		-DUSE_LOCK -I. -I./combine


OBJS= main.o utils.o strimage.o

all:	libCombine.a Count

#
# make the GIF combining library
#
libCombine.a:
	(cd combine; make)
#
Count:	$(OBJS)
		$(CC) $(CFLAGS) -o Count.cgi $(OBJS) combine/libCombine.a

main.o:	main.c
		$(CC) $(CFLAGS) -c main.c

utils.o:	utils.c
		$(CC) $(CFLAGS) -c utils.c

strimage.o:	strimage.c
		$(CC) $(CFLAGS) -c strimage.c

main.o:	count.h config.h
utils.o:	count.h config.h

clean:
	(cd combine; make clean)
	/bin/rm -f *.o Count.cgi core
