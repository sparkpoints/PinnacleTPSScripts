#!/usr/bin/perl -w
#time mark 
#2013May10,V2.0.0.0 Modigying whole Main Frame

#2012Aug17,V1.0.0.4 Modifying NPC target with 0 weight
# ----------------------------------------------------------------------
use strict;
use Switch;
use Getopt::Long;
use File::Copy;      
use File::Temp qw(tempfile);
use File::Spec;

my $debug = 0;

my $CurrentMRN = "";      #plan medical Record number
my $CurrentNumber = "";   #patient is record number in database Patient_xxx
my $PINNSCRIPT = "";   #create pinncle scripts for running
my $PlanPath = "";  #current plan's data dir
Getopt::Long::GetOptions(
    'm=s' => \$CurrentMRN,
    'n=s' => \$CurrentNumber,
    't=s' => \$PINNSCRIPT,
    'l=s' => \$PlanPath);    

##:define default directory path and default message   
#Pinnacle patient's Plan data database path
my $PatientDataBaseHome = "/pinnacle_patient_expansion/NewPatients/";  
#IMRT Planning base dir
my $SystemScriptHome = "/usr/local/adacnew/PinnacleSiteData/Scripts/IMRTcode/";
my $BinHome = $SystemScriptHome."bin/";         #perl scripts dir
my $ScriptTempDir = $SystemScriptHome."Temp/";  #debug temp file dir

my ($FH_PLAN,$PlanParam) = tempfile();   #Plan parameters
my ($FH_ROI,$ROIList) = tempfile();      #roi list 
my ($FH_ROIM,$ROIListM) = tempfile();    #roi modifying 

my $TempVar = $PatientDataBaseHome.$PlanPath;
my ($nonuse,$PlanBaseDir,$PlanNumber) = File::Spec->splitpath($TempVar);

print "mrn = $CurrentMRN\n";
print "num = $CurrentNumber\n";
print "scr = $PINNSCRIPT\n";
print "pat = $PlanPath\n";
print "dir=$PlanBaseDir\n";
print "file=$PlanNumber\n";
sub DataParse{
    my ($SourceFile,$TargetFile,$FinScripFile) = @_;
	my $line = '';
	open(FINAL,">>$FinScripFile") or die "unable to open $FinScripFile: $!";
	if (-r $SourceFile) {
		open(DATA, "<$SourceFile") or die "Unable to open $SourceFile: $!";   
		open(OUT,">$TargetFile") or die "unable to open $TargetFile: $!";
		#record ROI position
		my $cnt = 0;  
		while ($line = <DATA>) {
			chomp($line);
			#match ROI name
			if($line =~ /^           name:(.*)/){ 
				$line = $1;			 
				print OUT "$cnt\t$line\n" if $debug;
				push(@Globel_ROIList,"$cnt\t$line");  # save roi to list;
				$cnt++;
			};
		};
		close(DATA);
		close(OUT);
	}else{
		die "$SourceFile is not readable\n";
	};
	#check patient
    #open(OUT,"<$TargetFile") or die "unable to open $TargetFile: $!";
    my $tmp = 0;
	my $PTVmark = 0;
	my $PGTVmark = 0;
    foreach $line (@Globel_ROIList){
       if(!defined($line)) {next;}
	   if($line =~ /Patient$/i){ $tmp = 1;};
	   if(($line =~ /PTV$/i) || ($line =~ /PTV[0-9]$/i)){ $PTVmark = $PTVmark + 1; };
	   if(($line =~ /PGTV$/i) || ($line =~ /PGTV[0-9]$/i) || ($line =~ /PGTVn[xd]$/)){	$PGTVmark = $PGTVmark + 1;};   
    };   
    
	if($PGTVmark == 1 && $PTVmark == 1){$Globel_PlanType = 1;}; #PGTV and PTV both exist
	if($PGTVmark == 1 && $PTVmark == 0){$Globel_PlanType = 2;}; #PGTV only
	if($PGTVmark == 0 && $PTVmark == 1){$Globel_PlanType = 3;}; #PTV only	
	if($PGTVmark == 2 && $PTVmark == 2){$Globel_PlanType = 4;}; #PTV1,PTV2,PGTV1,PGTV2	
	if($PGTVmark == 2 && $PTVmark == 0){$Globel_PlanType = 5;}; #PGTV1,PGTV2
	if($PGTVmark == 0 && $PTVmark == 2){$Globel_PlanType = 6;}; #PTV1,PTV2
    if($tmp == 0 || $Globel_PlanType == 0){
	   print FINAL "WarningMessage = \"Checking Contour_Patients!\";\n";    #pre_define Pinnacle Non_normal exit
	   close(FINAL);      #exit programe when Contour_Patients is not define
	   print "No Patient in ROI lists \n" if $debug;
	   print "hit \"ente\" key to getout\n" if $debug;	   
	   #my $tmpcurinput = <STDIN>;
	   goto PerlEND; #exit perl programe
    };
    close(FINAL);
    #close(OUT);
};    

while(1){
my $input = <STDIN>;
}




