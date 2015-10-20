#!/bin/sh
chmod 777 users
chmod 777 mesg
chmod 777 laction
chmod 777 logged
chmod 777 system
chmod 777 system/*
chmod 777 system/room/*
chmod 777 system/mesglog/*
chmod 755 chat.pl
chmod 755 adm.pl
chmod 755 login.pl
chmod 755 include.pl
chmod 755 .
rm -f users/*
rm -f mesg/*
rm -f logged/*
rm -f laction/*
rm -f system/ip/*
rm -f system/domain/*
rm -f system/host/*
rm -f system/nick/*

