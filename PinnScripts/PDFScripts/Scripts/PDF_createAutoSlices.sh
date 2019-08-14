#!/bin/csh
# Bj  09.2005
# generate P3 Script PDF_Slices

# Pfad
set Pfad=/home/p3rtp/Export
set outScript = "/var/tmp/PDF_Slices.Script.$SESSION_SVR"


echo "Start Slice Nummer"
@ First = $<
echo "Stop Slice Nummer"
@ Last = $<

echo "// Autoscript" > $outScript

while ( $First <= $Last )
echo ' ViewWindowList .Current .UserSliceNumber = "'$First'"; ' >> $outScript
echo ' Script.ExecuteNow = "/usr/local/adacnew/PinnacleSiteData/Scripts/PY/pdf/PDF_Slice.Script.bj"; ' >> $outScript
@ First++
end
