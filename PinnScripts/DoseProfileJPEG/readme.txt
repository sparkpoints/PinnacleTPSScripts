DosisProfile.Script.bj 
Generate a ViewWindow an two points
Set all Options to gerate a DosProfile between the two Points
The Profile will be saved in /PrimaryPatientData/NewPatients

JPEG.Script.bj
Startscript for the shell script buildJPEG
The jpeg will be saved in /home/p3rtp/Export/JPEG

buildJPEG.sh 
The script extract the Encapsulated Postscript Data out of the Pinnacle print. 
Ghostscript will be uses to translate the EPS into JPEG.
You have to set the Ghostscript Variable GS_LIB to the Ghostscript font folder!
Also the Folder /home/p3rtp/Export/JPEG must exist.
Put the script into /home/p3rtp/bin

It's possible to generate a Pinnacle Printer 
Printer Type "Postscript" 
PrintCommand "buildJPEG.sh"
to "print" JPEGs but without the MedicalRecord Number


If you need help, feel free to kontakt me 

b.riis@strahlentherapie-hl.de
