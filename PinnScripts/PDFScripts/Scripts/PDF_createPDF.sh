#!/bin/ksh
# finaly generate PDF
# Bj 01.2005
# Pat ID wird uebergeben

# Pfad
Pfad=/home/ycw/PDF
Quelle=/var/tmp/Bild.ps
Heute=`date '+%d.%m.%y'`
HeutePDF=`date '+%d.%m.%y-%k.%M'`

# GhostScript Fonts
// Solaris 8
// GS_LIB=/opt/swf/share/ghostscript/fonts
// Solaris 10
// GS_LIB=/usr/sfw/bin/ghostscript/fonts


# add last PS and generate PDF
cat $Quelle >> $Pfad/$1.$Heute.ps
ps2pdf13 -sPAPERSIZE=a4 -dPDFSETTINGS=/prepress -dAutoRotatePages=/PageByPage $Pfad/$1.$Heute.ps $Pfad/$1.$HeutePDF.pdf

# loesche ps
rm $Quelle
rm $Pfad/$1.$Heute.ps
