#!/bin/sh
########
# a program to test Count.cgi 1.5
# by muquit@semcor.com
# 09/17/95
##
# if sh=0, then a 1x1 transparent GIF will be written, it will give a
# illusion. so you can count access to a page but will not display any
# counter, otherwise it should always be 1
#
QUERY_STRING="ft=9|frgb=69;139;50|tr=0|trgb=0;0;0|wxh=15;20|md=6|dd=A|st=5000|sh=1|df=count2.dat"
export QUERY_STRING

## below is the explanation for all the options

#####################
#        ft=9
#           ft means frame thickness. If you want to wrap the counter
#           with a ornamental frame, you define the frame thickness 
#           like this. Here 9 is the thickness of the frame in pixel.
#           This value can be any positive number more than 1. For nice
#           3D effect, use a number more than 5. If you do not want
#           frame, just use ft=0.
#        
#        frgb=69;139;50
#           frgb defines the color of the frame. Here 69 is the red 
#           component, 139 is the green component and 50 is the blue
#           component of the color. The valid range of each component
#           is >=0 and <= 255. The components must be separated by ;
#           character. Note even if you define ft=0, these components
#           must be present, just use 0;0;0 in that case.
#        
#        tr=0
#           tr defines if you want transparency in the counter image.
#           here tr=0, that is I do not want transparent image. If you
#           want transparent image, define tr=1. Note that Coun.cgi, 
#           does not care if your digits are transparent GIFs or not.
#           You must tell explicitly which color you want to make 
#           transparent.
#
#        trgb=0;0;0
#           if tr=1, then black color of the image will get transparent.
#           Here 0;0;0 are the red, green and blue component of the color
#           you want to make transparent.
#        
#        wxh=15;20
#           wxh string defines the width and height of an individual 
#           digit image. Each digits must have the same width and 
#           height. If you like to use digits not supplied with my
#           distribution, find out the width and height of the digits
#           and specify them here.
#
#        md=6
#           md defines the maximum number of digits to display. It can be
#           >= 5 and <= 10. If your counter number is less than md, the
#           left digits will be padded with zeros. Here md=6 means, display
#           the counter with maximum 6 digits. f you do not want
#           to left pad with zeros, use pad=0 instead of md=6.
#           Note you can either use md=some_number of pad=0, in this
#           field, you can not use both. If you use pad=0, then
#           the digits will be displayed exactly without padding.
#            
#        dd=A
#           dd means digit directory. A indicates, it will use my LED digits
#           located at the directory A. The base of the directory A is defined
#           with DigitDir at step 1.
#
#        st=5
#           st means start, that is start the counter with this value. st is
#           only significant if you compiled the program with 
#           -DALLOW_FILE_CREATION. If you compiled with this option, the
#           datafile will be created to the directory defined byDataDir
#           in the config.h file and 5 will be written to it. 
#           
#        sh=1
#           sh mean show. If sh=0, then no digit images will be displayed,
#           however a transparent 1x1 transparent GIF image will be
#           returned, which will give the illusion of nothing being displayed.
#           Althouh it will seem that nothing is displayed, the counter will
#           be incremented all right.
#
#        df=count.dat
#           finally df means data file. This is the file which will contain the
#           counter number. The base directory of this file is defined 
#           with DataDir at step 1. This file must exist. To create this
#           file, at the shell prompt do this:
#
#                echo 1 > count.dat
#           
#           or use a editor to create it. But this file must exist and
#           writable by httpd.
#############################

# play with authentication if you compiled with -DACCESS_AUTH
# replace www.semcor.com
#HTTP_REFERER="http://www.semcor.com/cgi-bin/Count.cgi?aaaa"
#export HTTP_REFERER

# play with ignore host
#
#REMOTE_ADDR='192.160.166.1'
#export REMOTE_ADDR

###
# if you have diplay from ImageMagick, try this
# if you have xv, use xv instead of display
###
Count.cgi -debug |display -

##
# or you can write the image to file and display with any image viewer
# here digit image will be written to a file count.gif
##
##
#Count.cgi -debug > count.gif
