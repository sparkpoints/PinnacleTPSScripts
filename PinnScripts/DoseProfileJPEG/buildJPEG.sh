#!/bin/ksh
# generate JPEG 
# Bj  03.2008
# Postscriptfile as $1
# MedRecord as $2 only if startet by script
# only EPS

# Settings in Pinnacle for use as printer
# Printer Type "Postscript" 
# PrintCommand in Pinnacle buildJPEG.sh
 
# Variablen 
Pfad=/home/p3rtp/Export/JPEG
TempBild=/var/tmp/BildTemp.ps
Bild=/var/tmp/Bild.ps
Treffer=0
Index=1
Start=0
Stop=0
ID=""

# ID
if [[ $ID == $2 ]]
	then 
	ID="Pinnacle-"
	else
	ID=$2-		
fi

# Get Start Stop
Start=`grep -n "PS-Adobe-2.0 EPSF-2.0" $1 | cut -d: -f1`
Stop=`grep -n "stop using temporary dictionary" $1 | cut -d: -f1`
Stop=`expr $Stop - 1`
Diff=`expr $Stop - $Start + 1`

head -n $Stop $1 | tail -$Diff > $TempBild

# Get resolution
XDim=`grep -n "dimensions of data" $TempBild | cut -d: -f2 |cut -d" " -f1`
YDim=`grep -n "dimensions of data" $TempBild | cut -d: -f2 |cut -d" " -f2`


# find translate
Stop=`grep -n "lower left corner" $TempBild | cut -d: -f1`
Start=`expr $Stop + 2`

head -n $Stop $TempBild > $Bild
echo "0 0 translate" >> $Bild
tail +$Start $TempBild >> $Bild


# generate single JPEG
 while test Treffer=0 
 do
 if test -f $Pfad/$ID$Index.jpg 
	then
	let Index=$Index+1
	else
	Treffer=1
	gs -dBATCH -dNOPAUSE -sDEVICE=jpeg -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dDOINTERPOLATE -dCOLORSCREEN -dJPEGQ=90 -dDEVICEHEIGHT=$YDim -dDEVICEWIDTH=$XDim -sOutputFile=$Pfad/$ID$Index.jpg  $Bild
	

	break
 fi
 done
 
 # clean up
rm $TempBild
rm $Bild