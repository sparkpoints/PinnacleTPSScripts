#!/usr/bin/perl -w
#time mark
#2012Aug17,V1.0.0.4 Modifying NPC target with 0 weight
# ----------------------------------------------------------------------
use strict;
use Switch;
use Getopt::Long;
use File::Copy;

my $debug = 0;

my $Cur_MRN = "";
my $Cur_Name = "";
my $Cur_Plan = "";
my $Pat_Data_Path = "";
Getopt::Long::GetOptions(
    'm=s' => \$Cur_MRN,
    'n=s' => \$Cur_Name,
    'p=s' => \$Cur_Plan,
    'l=s' => \$Pat_Data_Path);    

##:define default directory path and default message
my $PatientDataBaseHome = "/pinnacle_patient_expansion/NewPatients/";
my $SystemScriptHome = "/usr/local/adacnew/PinnacleSiteData/Scripts/IMRTcode/";
my $BinHome = $SystemScriptHome."bin/";
my $ScriptTempDir = $SystemScriptHome."Temp/";

my $ROIList = $ScriptTempDir."ROI_List.txt";
my $ROIListModify = $ScriptTempDir."ROI_Modify.txt";
my $BeamTemplate = $ScriptTempDir."BeamTemplate.txt";
my $IMRTTemplate = "/home/p3rtp/bin/IMRTTemplate.txt";

print "==$Cur_MRN,$Cur_Name,$Cur_Plan,$Pat_Data_Path==";
while(1){
my $input = <STDIN>;
}




