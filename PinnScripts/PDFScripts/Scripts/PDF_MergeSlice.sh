#!/bin/ksh
# merge PS
# Bilddrehung
# Bj  04.2007
# Pat ID wird uebergeben

# Pfad
Pfad=/home/ycw/PDF
Quelle=/var/tmp/Bild.ps
Treffer=0
Index=1
Heute=`date '+%d.%m.%y'`

# gesammt ps erzeugen
cat $Quelle >> $Pfad/$1.$Heute.ps

# loesche ps
rm $Quelle
