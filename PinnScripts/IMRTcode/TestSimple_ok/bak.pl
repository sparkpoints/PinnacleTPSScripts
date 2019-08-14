#!/usr/bin/perl -w
#time mark
#2012Aug17,V1.0.0.4 Modifying NPC target with 0 weight
# ----------------------------------------------------------------------
use strict;
use Switch;
use Getopt::Long;
use File::Copy;

my $debug = 1;

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
my $SystemScriptHome = "/usr/local/adacnew/PinnacleSiteData/Scripts/TempScripts/";
my $BinHome = "/home/p3rtp/bin/";
my $ScriptTempDir = "/home/p3rtp/Tempdir/";

my $ROIList = $ScriptTempDir."ROI_List.txt";
my $ROIListModify = $ScriptTempDir."ROI_Modify.txt";
my $BeamTemplate = $ScriptTempDir."BeamTemplate.txt";
my $IMRTTemplate = "/home/p3rtp/bin/IMRTTemplate.txt";

my $FIN_SCRIPT = "";
my $CurPlanRoiFile = "";
if($debug){
   $FIN_SCRIPT = $ScriptTempDir."CurrentIMRTStepOne.Script.p3rtp";
   #$CurPlanRoiFile = $ScriptTempDir."Patient_3883/Plan_2/plan.roi";
   $CurPlanRoiFile =  $PatientDataBaseHome."Institution_1_bak/Mount_0/Patient_11497/Plan_1/plan.roi";
}else{
   $FIN_SCRIPT = $SystemScriptHome."CurrentIMRTStepOne.Script.p3rtp";
   $CurPlanRoiFile =  $PatientDataBaseHome.$Pat_Data_Path."/plan.roi";
};
##:paln parameters define
my $Globel_BeamNum = "";           #plan beam number
my $Globel_PlanType = 0;           #0 - 6 type
my @Globel_Prescriptions = (); 		#Prescription of One Fraction (180-200cGy)
my @Globel_TargetNameList = ();		#Target name (PGTV,#0,PTV,#1)

my @Globel_ROIList = ();
my @Globel_ROIModifyList = ();		#Target name (0,PTV,TARGET)
my $Globel_FractionNum = "";		#Fraction numbers(28F)
my $Globel_TotalDose = "";			#Total Dose = $Prescription * $Globel_FractionNum

##:sub-function define
sub CurTime{
	my @CurTime = localtime;
	my $yyyymmdd = "";
	$yyyymmdd = $CurTime[5]+1900;
	my $tmpTime = $CurTime[4]+1;
	$tmpTime = "0$tmpTime" if $tmpTime < 10;
	$yyyymmdd .= $tmpTime;
	$tmpTime = $CurTime[3];
	$tmpTime = "0$tmpTime" if $tmpTime < 10;
	$yyyymmdd .= $tmpTime;
	print "$yyyymmdd\n" if $debug;
	return $yyyymmdd
}
sub ROICheck{##Read Plan ROI file
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
sub CreatRingNT{
	my ($ROIListFile,$ROIModifyFile,$FinScripFile) = @_;
	my ($targetmark,$oarmark,$phantommark,$tempmark) = ('TARGET','OAR','PHANTOM','CONTOURS');
	my $tempName = '';
	my @tempData = ();	
	my $TotalROINum = 0; #roi total number
	my $tmpCnt = 0; #mark counts
	my $temp = 0; 
	my $patientPos = ""; #Patient contours position	
	my $targetPos = ""; #target pos
	
	open(OUT,">>$FinScripFile") or die "unable to open $FinScripFile: $!"; #Pinn script file	
	print OUT "WindowList .CTSim .PanelList .\#\"\#2\" .GotoPanel = \"FunctionLayoutIcon2\";\n";
	print OUT "WindowList .NewROISpreadsheet .Create = \"ROISpreadsheetButton\";\n";
	print OUT "RoiLayout .Index = 1;\n";
	
	@Globel_ROIModifyList = ();
	$tmpCnt = 0;
	foreach my $line (@Globel_ROIList){
	   if(!defined($line)) {next;}
	   $tmpCnt = $tmpCnt + 1;	  #counting Total roi numbers  	   
	   @tempData= split(/\t/,$line);
	   chomp($tempData[1]);	
	   #target
	   if(($tempData[1] =~ /PGTV$/i) || ($tempData[1] =~ /P(.*)GTV[0-9]$/i)|| ($tempData[1] =~ /P(.*)GTVn[xd]$/i)){
	       $tempName = $&;		   
	       push(@Globel_TargetNameList,$tempName,$tempData[0]);   #save targets name,position       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"$tempName\";\n";
		   push(@Globel_ROIModifyList, "$tempData[0]\t$tempName\t$targetmark");
	       next;
	   };	   
	   if($tempData[1] =~ /PTV$/i || $tempData[1] =~ /PTV[0-9]$/i){	 
	       $tempName = $&; 		   
	       push(@Globel_TargetNameList,$tempName,$tempData[0]); #save targets name     
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"$tempName\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\t$tempName\t$targetmark");
	       next;
	   };
	   #OAR_Head
	   if($tempData[1] =~ /Len[-_]L(.*)/i || $tempData[1] =~ /Lens[-_]L(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Len_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLen_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Len[-_]R(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Len_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLen_R\t$oarmark");
	       next;
	   };	
	   if($tempData[1] =~ /Parotid[-_]R(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Parotid_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tParotid_R\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Parotid[-_]L(.*)/i){
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Parotid_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tParotid_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Pituitary(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Pituitary\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tPituitary\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Temp(.*)lobe[-_]R(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Temp.lobe_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tTemp.lobe_R\t$oarmark");
	       next;
	   };	
	   if($tempData[1] =~ /Temp(.*)lobe[-_]L(.*)/i){ 
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Temp.lobe_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tTemp.lobe_L\t$oarmark\n");
	       next;
	   };	
	   if($tempData[1] =~ /Temp(.*)joint[-_]R(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Temp.joint_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tTemp.joint_R\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Temp(.*)joint[-_]L(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Temp.joint_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tTemp.joint_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Mandible(.*)/i){     
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Mandible\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tMandible\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Brainstem$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Brainstem\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tBrainstem\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Brainstem\+(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Brainstem_PRV\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tBrainstem_PRV\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)nerve[-_]L$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.nerve_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.nerve_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)nerve[-_]L\+(.*)/i){	
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.nerve_L_PRV\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.nerve_L_PRV\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)nerve[-_]R$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.nerve_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.nerve_R\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)nerve[-_]R\+(.*)/i){	
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.nerve_R_PRV\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.nerve_R_PRV\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)chiasm$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.chiasm\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.chiasm\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Opt(.*)chiasm\+(.*)$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Opt.chiasm_PRV\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tOpt.chiasm_PRV\t$oarmark");
	       next;
	   };
	   #OAR_chest	
	   if($tempData[1] =~ /Larynx(.*)/i){     
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Larynx\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLarynx\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Trachea(.*)/i){       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Trachea\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tTrachea\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Esophagus(.*)/i){       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Esophagus\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tEsophagus\t$oarmark");
	       next;
	   };
	   if(($tempData[1] =~ /cord$/i) || ($tempData[1] =~ /cord[0-9]$/i)){	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Cord\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tCord\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /cord\+(.*)/i){	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Cord_PRV\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tCord_PRV\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Lung[-_]R(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Lung_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLung_R\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Lung[-_]L(.*)/i){		     
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Lung_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLung_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Lung[-_]ALL(.*)/i || $tempData[1] =~ /Lung[-_]total(.*)/i) {      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Lung_Total\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLung_Total\t$oarmark");
	       next;
	   };	
	   if($tempData[1] =~ /Heart(.*)/i){ 	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Heart\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tHeart\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Stomach(.*)/i){ 	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Stomach\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tStomach\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Pancreas(.*)/i){ 	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Pancreas\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tPancreas\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Spleen(.*)/i){ 	       
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Spleen\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tSpleen\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Liver(.*)/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Liver\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tLiver\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Kidney[-_]R(.*)/i){      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Kidney_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tKidney_R\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Kidney[-_]L(.*)/i){      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Kidney_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tKidney_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Kidney[-_]ALL(.*)/i || $tempData[1] =~ /Kidney[-_]total(.*)/i) {      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Kidney_Total\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tKidney_Total\t$oarmark");
	       next;
	   };		
	   #OAR_Abdoman
	   if($tempData[1] =~ /Bladder(.*)/i){ 	     
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Bladder\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tBladder\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /Rectum(.*)/i){ 	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Rectum\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tRectum\t$oarmark");
	       next;
	   };
	   if(($tempData[1] =~ /small(.*)/i) || ($tempData[1] =~ /(.*)intestine/i)){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Small.intestine\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tSmall.intestine\t$oarmark");
	       next;
	   };	
	   if ($tempData[1] =~ /(.*)bowel/i){  
	   print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Bowel\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tBowel\t$oarmark");
	       next;
	   };    
	   if($tempData[1] =~ /fem(.*)l$/i){	      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Femoral.head_L\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tFemoral.head_L\t$oarmark");
	       next;
	   };
	   if($tempData[1] =~ /fem(.*)r$/i){      
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Femoral.head_R\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tFemoral.head_R\t$oarmark");
	       next;
	   };	  
		#OAR_Normal Tissue
	   if($tempData[1] =~ /Patient$/i){
	       $patientPos = $tempData[0];
	       #print OUT "RoiList.Current = $tempData[0]\n";
	       print OUT "RoiList.\#\"\#$tempData[0]\".Name = \"Patient\";\n";
	       push(@Globel_ROIModifyList, "$tempData[0]\tPatient\t$tempmark");
	       next;
	   };
	   push(@Globel_ROIModifyList, "$tempData[0]\t$tempData[1]\t$tempmark");
	};
	print OUT "WindowList .NewROISpreadsheet .Unrealize = \"Close ROI Spreadsheet\";\n";
		
	$TotalROINum = $tmpCnt;	
	print OUT "WindowList .CTSim .PanelList .\#\"\#2\" .GotoPanel = \"FunctionLayoutIcon2\";\n";
	print OUT "WindowList .RoiExpandWindow .Create = \"ROI Expansion/Contraction...\";\n";
	print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";
	
	my @CurTarget = ();
	my ($SaveTargetPos,$SaveTargetName) = (undef,undef);
	my ($PTVminiPGTVposition,$PTVminiPGTVname,$PTVminiPGTVpos) = (undef,undef,undef);
	my $ExtendingRing = 0;  #extending 0 cm
	my $ROIsourceposition = 0;  
	my $matchtargetname = ''; 
	#my ($secondTargetPos,$secondTargetName) = ()
	my $CurROIPos = $TotalROINum;  # Cur ROI position
	
	if($Globel_PlanType == 4){     #creating PGTVnx + PGTVnd; PTV1+PTV2
		#PGTVnx + PGTVnd
		$tmpCnt = 0; #position mark
		foreach $tempName(@Globel_TargetNameList){				
			if ($tempName =~ /PGTVn[xd]$/i){					 
				$temp = $Globel_TargetNameList[$tmpCnt+1]; #temp for position
				push(@CurTarget,$tempName,$temp);
				delete $Globel_ROIModifyList[$temp]; #modify ptv1 from target to contours
				$Globel_ROIModifyList[$temp] = "$temp\t$tempName\tCONTOURS";
			};
			$tmpCnt = $tmpCnt + 1;
		};
		
		$tempName = "PGTV_PLAN"; #new target Name 
		$ExtendingRing = 0;
		#$ROIsourceposition = 0; 
		print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
		print OUT "IF .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[3]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[3]\" .Address;\n";
		print OUT "IF .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[1]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[1]\" .Address;\n";
		print OUT "RoiExpandControl .ConstantPadding = \"1\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"$ExtendingRing\";\n"; 
		print OUT "RoiExpandControl .Expand = \"1\";\n";
		print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";	
			
		($SaveTargetName,$SaveTargetPos) = ($tempName,$CurROIPos);
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tTARGET") ;			
		$CurROIPos = $CurROIPos + 1;			
		@CurTarget = (); #temp variable	
		
		#PTV1+PTV2		
		$tmpCnt = 0; #position mark
		foreach $tempName(@Globel_TargetNameList){				
			if ($tempName =~ /PTV[0-9]$/i){				 
				$temp = $Globel_TargetNameList[$tmpCnt+1]; 	#temp for position
				push(@CurTarget,$tempName,$temp);
				delete $Globel_ROIModifyList[$temp]; 	#modify ptv1 from target to contours
				$Globel_ROIModifyList[$temp] = "$temp\t$tempName\tCONTOURS";
			};
			$tmpCnt = $tmpCnt + 1;
		};
		$tempName = "PTV_PLAN"; #new target Name 
		$ExtendingRing = 0;
		#$ROIsourceposition = 0; 
		print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
		print OUT "IF .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[3]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[0]\" .Address;\n";
		print OUT "IF .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[1]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[1]\" .Address;\n";
		print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n"; 
		print OUT "RoiExpandControl .Expand = \"1\";\n";
		print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";
					
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tTARGET") ;	 #modify ROIList
		
		@Globel_TargetNameList = ();									#change targetslist from
		push(@Globel_TargetNameList,$SaveTargetName,$SaveTargetPos);	# PGTVnx,PGTVnd,PTV1,PTV2
		push(@Globel_TargetNameList,$tempName,$CurROIPos);				# ==> PGTV_PLAN,PTV_PLAN
		$CurROIPos = $CurROIPos + 1;	
		@CurTarget = (); #temp variable			
	};
	if($Globel_PlanType == 6 || $Globel_PlanType == 5){ #creating PGTV1 + PGTV2; PTV1+PTV2
		$tmpCnt = 0; #position mark
		foreach $tempName(@Globel_TargetNameList){				
				if ($tempName =~ /PTV[0-9]$/i || $tempName =~ /PGTV[0-9]$/i){
					$matchtargetname = $&;					
					$temp = $Globel_TargetNameList[$tmpCnt+1]; #temp for position
					push(@CurTarget,$tempName,$temp);
					delete $Globel_ROIModifyList[$temp]; #modify ptv1 from target to contours
					$Globel_ROIModifyList[$temp] = "$temp\t$tempName\tCONTOURS";
				};
				$tmpCnt = $tmpCnt + 1;
			};
		$matchtargetname = s/\d//;
		$tempName = $matchtargetname."_PLAN"; #new target Name 
		$ExtendingRing = 0;
		print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
		print OUT "IF .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[3]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[3]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[3]\" .Address;\n";
		print OUT "IF .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$CurTarget[1]\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$CurTarget[1]\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$CurTarget[1]\" .Address;\n";
		print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n"; 
		print OUT "RoiExpandControl .Expand = \"1\";\n";
		print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";	
		
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tTARGET") ;
		@Globel_TargetNameList = ();		
		push(@Globel_TargetNameList,$tempName,$CurROIPos);		
		$CurROIPos = $CurROIPos + 1;
		@CurTarget = ();
	};
	if($Globel_PlanType == 4 || $Globel_PlanType == 1){
		$tmpCnt = 0;
		foreach $tempName(@Globel_TargetNameList){
			if ($tempName =~ /PGTV*/i){				
				$ROIsourceposition = $Globel_TargetNameList[$tmpCnt+1]; #TARGET position				
			}elsif($tempName =~ /PTV*/i){
				$SaveTargetPos = $Globel_TargetNameList[$tmpCnt+1]; #TARGET position				
				delete $Globel_ROIModifyList[$SaveTargetPos]; #modify ptv1 from target to contours
				$Globel_ROIModifyList[$SaveTargetPos] = "$SaveTargetPos\t$tempName\tCONTOURS";
				$PTVminiPGTVposition = $tmpCnt;                    #save PTV position			
			}
			$tmpCnt = $tmpCnt + 1;
		};
		#PGTV + 5mm
		$ROIsourceposition = $ROIsourceposition;  #PGTV
		$temp = $SaveTargetPos;	#PTV
		$ExtendingRing = 0.3;
		$tempName = "PGTV+3mm"; #new target Name 
		print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
		print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";
		print OUT "IF .RoiList .\#\"\#$temp\" .RoiExpandState .Is .\#\"Avoid Exterior\" .THEN .RoiList .\#\"\#$temp\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$temp\" .RoiExpandState = \"Avoid Exterior\";\n";	       
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$temp\" .Address;\n";
		print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n";
		print OUT "RoiExpandControl .DoRingExpansion = \"Create Ring ROI\";\n";		
		
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tPHANTOM") ;
		$CurROIPos = $CurROIPos + 1;
		#PTV-PGTV
		$SaveTargetPos = $ROIsourceposition; 
		$ROIsourceposition = $temp;  	#PTV 
		$temp = $SaveTargetPos;			#PGTV
		$ExtendingRing = 0;
		$tempName = "PTV-PGTV"; #new target Name 
		print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
		#PTV
		print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Source\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";
		#PGTV
		print OUT "IF .RoiList .\#\"\#$temp\" .RoiExpandState .Is .\#\"Avoid Interior\" .THEN .RoiList .\#\"\#$temp\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$temp\" .RoiExpandState = \"Avoid Interior\";\n";	       
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$temp\" .Address;\n";
		$temp = $CurROIPos - 1; #PGTV + 3mm
		print OUT "IF .RoiList .\#\"\#$temp\" .RoiExpandState .Is .\#\"Avoid Interior\" .THEN .RoiList .\#\"\#$temp\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$temp\" .RoiExpandState = \"Avoid Interior\";\n";	       
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$temp\" .Address;\n";				
		print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n"; 
		print OUT "RoiExpandControl .Expand = \"1\";\n";
		print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";
		($PTVminiPGTVname,$PTVminiPGTVpos) = ($tempName,$CurROIPos);				
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tTARGET") ;
		$CurROIPos = $CurROIPos + 1;
		
	};	
	$tmpCnt = 0;
	foreach $tempName(@Globel_TargetNameList){	
		if($Globel_PlanType%3 == 1){  # PGTV + PTV (type 1,4 ) not need  PGTV + 1,2,3cm
			if ($tempName =~ /PTV*/i){
				$matchtargetname = $&;
				$targetPos = $Globel_TargetNameList[$tmpCnt+1]; #TARGET position
				last;
			};
		}else{
			if ($tempName =~ /PTV*/i || $tempName =~ /PGTV*/i){
				$matchtargetname = $&;
				$targetPos = $Globel_TargetNameList[$tmpCnt+1]; #TARGET position				
				last;
			};
		};
		$tmpCnt = $tmpCnt + 1;
	};	
	#Avoid Patient
	$ROIsourceposition = $patientPos;
	print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
	print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .\#\"Avoid Exterior\" .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Avoid Exterior\";\n";
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";
	#PTV|PGTV + 5mm
	$ROIsourceposition = $targetPos;		
	$ExtendingRing = 0.5;						
    $tempName = $matchtargetname."\+".$ExtendingRing."cm"; #new target Name
	print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
	print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
	print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Source\";\n";
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";
	print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
	print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n";
	print OUT "RoiExpandControl .DoRingExpansion = \"Create Ring ROI\";\n";
	$temp = $CurROIPos;
	push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tPHANTOM") ;
	$CurROIPos = $CurROIPos + 1;	
	
	$matchtargetname = $matchtargetname;	
	$ExtendingRing = 0;
	my @extendinglist = (1,2,3);
	my @extendingname = ("+1cm","+2cm","+3cm");
	my $i = 0;
	while($i<3){
		$ROIsourceposition = $temp;	 #target 
		$ExtendingRing = $extendinglist[$i];
		#$temp = $ExtendingRing +  $extendinglist[$i];					
		$tempName = $matchtargetname.$extendingname[$i]; #new target Name
		print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
		print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n"; 		
		print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .\#\"Avoid Interior\" .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Avoid Interior\";\n";
		print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";
		print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
		print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n";
		print OUT "RoiExpandControl .DoRingExpansion = \"Create Ring ROI\";\n";
		$temp = $CurROIPos;     #next target
		push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tPHANTOM") ;
		$CurROIPos = $CurROIPos + 1;				
		$i = $i + 1;
	};
	#Creating PTV+3cm
	$ROIsourceposition = $targetPos; #target
	$temp = $patientPos; #patient
	$ExtendingRing = 3;
	$tempName = "tempoar"; #new target Name 
	print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
	print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
	print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
	print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Source\";\n";
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";		
	print OUT "IF .RoiList .\#\"\#$temp\" .RoiExpandState .Is .\#\"Avoid Exterior\" .THEN .RoiList .\#\"\#$temp\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$temp\" .RoiExpandState = \"Avoid Exterior\";\n";	       
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$temp\" .Address;\n";				
	print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
	print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n"; 
	print OUT "RoiExpandControl .Expand = \"1\";\n";
	print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";
	
	push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tCONTOURS") ;
	$CurROIPos = $CurROIPos + 1;
	#creating NT    
	$ROIsourceposition = $patientPos;    #Patient
	$temp = $CurROIPos-1;    				 #PTV|PGTV+3cm tempoar
	$ExtendingRing = 0;
	$tempName = "NT"; #new target Name 
	print OUT "RoiList .\#\"*\" .ResetRoiExpandState = \"Clear All\";\n";
	print OUT "RoiExpandControl .TargetRoiName = \"$tempName\";\n";
	print OUT "RoiExpandControl .CreateNewTarget = \"1\";\n";  
	print OUT "IF .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState .Is .Source .THEN .RoiList .\#\"\#$ROIsourceposition\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$ROIsourceposition\" .RoiExpandState = \"Source\";\n";
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$ROIsourceposition\" .Address;\n";		
	print OUT "IF .RoiList .\#\"\#$temp\" .RoiExpandState .Is .\#\"Avoid Interior\" .THEN .RoiList .\#\"\#$temp\" .ResetRoiExpandState .ELSE .RoiList .\#\"\#$temp\" .RoiExpandState = \"Avoid Interior\";\n";	       
	print OUT "RoiExpandControl .CheckTargetRoi = RoiList .\#\"\#$temp\" .Address;\n";				
	print OUT "RoiExpandControl .ConstantPadding = \"$ExtendingRing\";\n";
	print OUT "RoiExpandControl .UseConstantPadding = \"1\";\n"; 
	print OUT "RoiExpandControl .Expand = \"1\";\n";
	print OUT "RoiExpandControl .DoExpand = \"Expand\";\n";
	
	push(@Globel_ROIModifyList,"$CurROIPos\t$tempName\tPHANTOM") ;
	$CurROIPos = $CurROIPos + 1;
	
	if ($Globel_PlanType == 4 || $Globel_PlanType == 1 && defined($PTVminiPGTVposition)) {	
		delete $Globel_TargetNameList[$PTVminiPGTVposition];          	#Remove PTV as Target
		delete $Globel_TargetNameList[$PTVminiPGTVposition+1];          #del PTV position			
		push(@Globel_TargetNameList,$PTVminiPGTVname,$PTVminiPGTVpos);        #add PTV-PGTV as Target
	}
	#display phantom contours
	foreach my $data(@Globel_ROIModifyList){
	   chomp($data);
	   if(!defined($data)) {next;};	   
	   @tempData = split(/\t/,$data);
	   if($tempData[2] eq "PHANTOM"){
	      print OUT "RoiList .Current = $tempData[0];\n";
	      print OUT "RoiList .Current .Display2d = \"off\";\n"; 
	   };
	};	
	#Delete Curves mini Area
	
	#print OUT "WindowList .RoiCleanupWindow .Create = \"Clean ROI...\";\n";
	#print OUT "RoiList .Current .CurveMinArea = \"0.02\";\n";
	#open(ROIOUT,">$ROIModifyFile") or die "unable to open $ROIModifyFile:$!" if $debug; #Modify ROI file
	#foreach my $data(@Globel_ROIModifyList){
	#   chomp($data);
	#   if(!defined($data)) {next;};
	#   print ROIOUT "$data\n" if $debug; #  save modifying Roi into disk files;
	#   @tempData = split(/\t/,$data);
	#   chomp $tempData[2];	   
	#   print OUT "RoiList .\#\"#$tempData[0]\" .Clean = \"Rescan\";\n";
	#   print OUT "RoiList .\#\"#$tempData[0]\" .CleanAndDelete = \"Delete Curves\";\n";		     
	#};
	#print OUT "WindowList .RoiCleanupWindow .Unrealize = \"Dismiss\";\n";
	
    close(ROIOUT) if $debug;
    close(OUT);
};
sub PlanBeamNum{
	#input Beam numbers	
	while(1){
		print "Plan Beam Number Choice:\n";
		print "==================================================\n";
		print "||    4:  Imrt4 beams;  5: Imrt5 beams;         ||\n";
		print "||    6:  Imrt6 beams;  7: Imrt7 beams;         ||\n";
		print "||    8:  Imrt8 beams;  9: Imrt9 beams;         ||\n";	
		print "==================================================\n";
		print "BeamNumber=(1-9):";
		$Globel_BeamNum = <STDIN>;
		chomp($Globel_BeamNum);
		if($Globel_BeamNum >= 1 && $Globel_BeamNum <= 36){			
			last;
		}else{
			print "\nError Input: selecting 1-9.  \n\n";
			next;
		};
	}
	print "YouPlan will Add $Globel_BeamNum New Beam\n\n";
};
sub PlanTypeDef{
    my $PhysicanInput = ""; 	
	print "\nPlease defined Discription Dose\n";	
	foreach my $line(@Globel_TargetNameList){
		if (!defined($line) || $line =~ /\d+/) {next;};
		while(1){			
			print "$line\t = ";
			$PhysicanInput = <STDIN>;
			chomp($PhysicanInput);
			if ($PhysicanInput =~ /^\d+$/ &&  $PhysicanInput < 1200){	
				push(@Globel_Prescriptions,$line,$PhysicanInput);              #target name#target dose
				#push(@Globel_Prescriptions,$PhysicanInput);		
				last;
			}else{
				print "\nYou should Input dose(PTV=200)\n";
				next;
			};						
		};		
	};	
	#print "\nPlease defined Fraction Number\n";		
	while(1){
		print "FractionNumber\t = ";
		$PhysicanInput = <STDIN>;
		chomp($PhysicanInput);
		if ($PhysicanInput =~ /^\d+$/ &&  $PhysicanInput < 50){				
			$Globel_FractionNum = $PhysicanInput;
			last;
		}else{
			print "\nYou should Input dose(exp 200)\n";
			next;
		};
	};	
};
sub CreateISOPoint{
    my ($FinScripFile) = @_;
	my $currenttargetname  = ();
	my $TempTargetName = undef;
	foreach $TempTargetName(@Globel_TargetNameList){
	   if (!defined($TempTargetName)){ next;};
	   if ($TempTargetName =~ /PTV(.*)/i || $TempTargetName =~ /PGTV(.*)/i){
	       $currenttargetname = $TempTargetName;
			last;                            #point place at PTV center
		};
	};
    open(OUT,">>$FinScripFile") or die "unable to open $FinScripFile: $!";	
    print OUT "WindowList .CTSim .PanelList .\#\"\#1\" .GotoPanel = \"FunctionLayoutIcon1\";\n";
    print OUT "TrialList .Current .LaserLocalizer .LockJaw = \"0\";\n";
    #Ref point
    print OUT "PoiList .Current = \"POI_1\";\n";
    print OUT "PoiList .Current .Name = \"Ref.point\";\n";
    print OUT "PoiList .Current .Color = \"green\";\n";
    #Iso.center Autoplace at  center of (PGTV/PTV)
    print OUT "CreateNewPOI = \"Add Point\";\n";
    print OUT "PoiList .Current .Name = \"Iso.center\";\n";
    print OUT "PoiList .Current .Color = \"red\";\n";
    print OUT "WindowList .PoiAutoplace .Create = \"Autoplace POI...\";\n";
    print OUT "RoiList .Current = \"$currenttargetname\";\n";
    print OUT "AutoplaceCurrentPoi = \"Automatically Place Point\";\n";
    print OUT "WindowList .PoiAutoplace .Unrealize = \"Dismiss\";\n";
    close(OUT);
};
sub CreateBeams{
	my ($FinScripFile) = @_;
	my @tempGantrys = ();
	my $CurBeamGantry = "";
	
	open(OUT,">>$FinScripFile") or die "unable to open $FinScripFile: $!";
	if($Globel_BeamNum == 4) {
	   @tempGantrys = (15,165,220,335);
	}elsif($Globel_BeamNum == 5){
	   @tempGantrys = (300,0,60,140,220);
	}elsif($Globel_BeamNum == 6) {
	   @tempGantrys = (0,45,100,180,260,315);
	}elsif($Globel_BeamNum == 7){
	   @tempGantrys = (0,52,104,156,208,260,312);
	}elsif($Globel_BeamNum == 8) {
	   @tempGantrys = (30,65,100,135,225,260,295,330);
	}elsif($Globel_BeamNum == 9){
	   @tempGantrys = (0,40,80,120,160,200,240,280,320);		
	}else{
	   @tempGantrys = (0,72,144,216,288);
	   $Globel_BeamNum = 5;		
	};
	
	print OUT "WindowList .CTSim .PanelList .\#\"\#3\" .GotoPanel = \"FunctionLayoutIcon3\";\n";
	print OUT "TrialList .Current .LaserLocalizer .LockJaw = \"0\";\n";
	my $TempCnt = $Globel_BeamNum;
	while($TempCnt-- > 0){
	   print OUT "CreateNewBeam = \"Add Beam\";\n";	   
	};
	print OUT "WindowList .NewBeamSpreadsheet .Create = \"BeamSpreadsheetButton\";\n";
	print OUT "BeamLayout .Index = 0;\n";
	print OUT "BeamLayout .Index = 1;\n";
	print OUT "TrialList .Current .BeamList .\#\"*\" .Isocenter = \"Iso.center\";\n";
	$TempCnt = $Globel_BeamNum;
	while($TempCnt-- > 0){
		$CurBeamGantry = $tempGantrys[$TempCnt];
	 	chomp $CurBeamGantry;		
		print OUT "TrialList .Current .BeamList .\#\"\#$TempCnt\" .Gantry = \"$CurBeamGantry\";\n";			
	};		
	close(OUT);
};
sub DefinePrescriptionISODose{
	my ($TargetFile) = @_;
	my $temppgtvname = undef;
	my $temppgtvpres = undef;
	my $tempptvname = undef;
	my $tempptvpres = undef;
	
	
	my $tmp = 0;	
	my $TempTargetName = undef;
	foreach $TempTargetName (@Globel_Prescriptions){  #PTV,200,PGTV,200 save data
		if (!defined($TempTargetName) || $TempTargetName =~ /\d+/) {next;};
		if ($TempTargetName =~ /^PGTV(.*)/i) {
		   $temppgtvname = $TempTargetName; 
		   $temppgtvpres = $Globel_Prescriptions[$tmp+1];
		   next;
		}elsif($TempTargetName =~ /^PTV(.*)/i){
		   $tempptvname = $TempTargetName; 
		   $tempptvpres = $Globel_Prescriptions[$tmp+1];
		   next;
		};
		$tmp = $tmp + 1;
	};
	my $currenttargetname = '';
	my $TempPrescription = ''; 
	my @curisodoseline = ();
	if($Globel_PlanType == 4 || $Globel_PlanType == 1){
	   $currenttargetname = $temppgtvname;
	   $TempPrescription = $temppgtvpres;
	   @curisodoseline = ($temppgtvpres*$Globel_FractionNum,$tempptvpres*$Globel_FractionNum,4500,3500,2500); 	
	}elsif($Globel_PlanType == 5 || $Globel_PlanType == 2){
	   $currenttargetname = $temppgtvname;
	   $TempPrescription = $temppgtvpres;
	   @curisodoseline = ($temppgtvpres*$Globel_FractionNum,4500,3500,2500,6000); 	 
	}else{
	   $currenttargetname = $tempptvname;
	   $TempPrescription = $tempptvpres;
	   @curisodoseline = ($tempptvpres*$Globel_FractionNum,4500,3500,2500,6000); 
	};
	#prescription
	open (OUT,">>$TargetFile") or die "unable open file $TargetFile\n";
	print OUT "WindowList .CTSim .PanelList .\#\"\#4\" .GotoPanel = \"FunctionLayoutIcon4\";\n";
	#setting prescription dose
	print OUT "WindowList .TrialPrescription .Create = \"Edit Prescriptions...\";\n";	
	print OUT "TrialList .Current .PrescriptionList .\#\"\#0\" .MakeCurrent = 1;\n";
	print OUT "WindowList .PrescriptionEditor .Create = \"Edit...\";\n";
	print OUT "TrialList .Current .PrescriptionList .Current .PrescriptionDose = \"$TempPrescription\";\n";
	print OUT "TrialList .Current .PrescriptionList .Current .PrescriptionPercent = \"95\";\n";
	print OUT "TrialList .Current .PrescriptionList .Current .NormalizationMethod = \"ROI Mean\";\n";
	print OUT "TrialList .Current .PrescriptionList .Current .PrescriptionRoi = \"$currenttargetname\";\n";
	print OUT "TrialList .Current .PrescriptionList .Current .NumberOfFractions = \"$Globel_FractionNum\";\n";
	print OUT "WindowList .PrescriptionEditor .Unrealize = \"Dismiss\";\n";
	print OUT "WindowList .TrialPrescription .Unrealize = \"Dismiss\";\n";
	#weights
	print OUT "WindowList .BeamWeighting .Create = \"Beam Weighting...\";\n";
	print OUT "WindowList .WeightingOptions .Create = \"Weighting Options...\";\n";
	print OUT "TrialList .Current .WeightEqual = \"Set Equal Weights for Unlocked Beams\";\n";
	print OUT "WindowList .WeightingOptions .Unrealize = \"Dismiss\";\n";
	print OUT "WindowList .BeamWeighting .Unrealize = \"Dismiss\";\n";
	#Iso dose line
	print OUT "WindowList .CTSim .PanelList .\#\"\#5\" .GotoPanel = \"FunctionLayoutIcon5\";\n";
	print OUT "IsodoseControl .NormalizationMode = \"Absolute\";\n";
	print OUT "WindowList .IsodoseWindow .Create = \"Line Details...\";\n";
	
	my @linetype = ("red","purple","blue","skyblue","forest");
	$tmp = 0;		
	foreach $TempTargetName (@curisodoseline){
	   print OUT "IsodoseControl .LineList .\#\"\#$tmp\" .IsoValue = \"$TempTargetName\";\n";
	   print OUT "IsodoseControl .LineList .\#\"\#$tmp\" .Color = \"$linetype[$tmp]\";\n";
	   $tmp = $tmp + 1;
	};	
	print OUT "IsodoseControl .LineList .\#\"\*\" .LineWidthString = \"Medium\";\n";
	print OUT "WindowList .IsodoseWindow .Unrealize = \"Dismiss\";\n";
    print OUT "\n";	
	close(OUT);
};
sub MarkDisplayRoiDVH{
    my ($FinScripFile) = @_;
    
    #open(IN,"<$tmpROI_MODY") or die "unable to open $tmpROI_MODY: $!";
    open(OUT,">>$FinScripFile") or die "unable to open $FinScripFile: $!";
    
    print OUT "WindowList .PlanEval .CreateUnrealized = \"Dose Volume Histogram...\";\n";
    print OUT "WindowList .PlanEval .PanelList .\#\"\#0\" .GotoPanel = \"Dose Volume Histogram...\";\n";
    print OUT "WindowList .PlanEval .Create = \"Dose Volume Histogram...\";\n";
    print OUT "PluginManager .PlanEvalPlugin .TrialList .\#\"\#0\" .Selected = 1;\n";
    foreach my $line (@Globel_ROIModifyList){
		chomp($line);
		my ($linenum,$roiname,$roimark) = split(/\t/,$line);
        if ($roimark eq 'TARGET' || $roimark eq 'OAR'){
			print OUT "PluginManager .PlanEvalPlugin .ROIList .\#\"\#$linenum\" .Selected = 1;\n";
			next;
		};       
		if ($roimark eq 'CONTOURS' && ($roimark =~ /PTV(.*)/i || $roimark =~ /PGTV(.*)/i)){
			print OUT "PluginManager .PlanEvalPlugin .ROIList .\#\"\#$linenum\" .Selected = 1;\n";
			next;
		};
    };
    print OUT "DVHPlotStyle .NormalizeX = 0;\n";
    print OUT "\n";	
    close(OUT);
    #close(IN);
};
sub IMRTSetting{
	my ($TargetFile) = @_;
	my $curIMRTtargetposition = 0;	
	my ($maxitem,$doseitem,$segmentsnum) = (100,40,40); # IMRT parameters
	open(TEMP,"<$IMRTTemplate") or die "unable to open $IMRTTemplate: $!";
	my @TemplateData = <TEMP>;
	close(TEMP);
	
	my @templistdata = ();
	my $tempname = "";
	#my $TempTotalDose = "";
	my $tempdose = "";
	
	my $CurTargetName = "";
	my $CurTargetType = "";	
	my $CurTargetDose = "";
	my $CurTargetPerc = "";
	my $CurTargetWeight = "";
	my $CurTargetAvalue = "";
	my $CurTargetEUD = "";
	
	if($Globel_BeamNum > 5){
	   $segmentsnum = 70;                  #big IMRT
	};
	if($Globel_PlanType == 4){
	   ($maxitem,$doseitem,$segmentsnum) = (90,10,90);  #for NPC 
	}
	open (OUT,">>$TargetFile") or die "unable open file $TargetFile\n";
	print OUT "StartIMRT = \"IPButton\";\n";
	print OUT "ImrtTemplateLayout = \"Optimization\";\n";
	print OUT "WindowList .IMRTTemplate .Create = \"IMRT Parameters...\";\n";
	print OUT "TrialList .Current .BeamList .\#\"\*\" .IMRTParameterType = \"DMPO\";\n";
	print OUT "PluginManager .InversePlanningManager .OptimizationManager .Current .TrialList .Current .MaxIterations = \"$maxitem\";\n";
	print OUT "PluginManager .InversePlanningManager .TrialList .Current = \{\n";
	print OUT "         DoseIteration = \"$doseitem\";\n";	
	print OUT "         MaxDynamicSegments = \"$segmentsnum\";\n";	
	print OUT "         MinimumMUPerSegment = \"5\";\n";
	print OUT "         MinimumSegmentArea = \"5\";\n";
	print OUT "         ComputeFinalDose = 1;\n";
	print OUT "         \};\n";
	#target dose
	my $temp = 0;
	$curIMRTtargetposition = 0;
	foreach $tempname (@Globel_Prescriptions){
		if (($tempname =~ /^PGTV(.*)/i) || ($tempname =~ /^PTV(.*)/i)){
			$CurTargetName = $tempname;
			$tempdose = $Globel_Prescriptions[$temp+1] * $Globel_FractionNum;
					
	        
	        $CurTargetName = $CurTargetName;
	        $CurTargetType = "Max Dose";
	        if($Globel_PlanType == 4 || $Globel_PlanType == 1){	
	           $CurTargetDose = $tempdose + 270;
	        }else{
	           $CurTargetDose = $tempdose + 170;
	        }
	        $CurTargetWeight = 80;      
	           
			print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";			
			$curIMRTtargetposition += 1;	
			
			$CurTargetName = $CurTargetName;
	        $CurTargetType = "Min DVH";
	        if($Globel_PlanType == 4 || $Globel_PlanType == 1){	
	           $CurTargetDose = $tempdose + 170;
	        }else{
	           $CurTargetDose = $tempdose + 70;
	        }
	        $CurTargetPerc = 95;
	        $CurTargetWeight = 100;	        
	           
			print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .UserPercent = \"$CurTargetPerc\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";			
			$curIMRTtargetposition += 1;
			
			$CurTargetName = $CurTargetName;
	        $CurTargetType = "Min Dose";
	        $CurTargetDose = $tempdose;
	        $CurTargetWeight = 100;	        
	           
			print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";			
			$curIMRTtargetposition += 1;		
					
		};		
		$temp = $temp + 1;
	};
	#phantom 
	my ($curpgtvdose,$curptvdose) = (undef,undef); 
	my @typelist = ();	
	my @doselist = ();
		
	$temp = 0;
	foreach $tempname (@Globel_Prescriptions){
	   if ($tempname =~ /^PGTV(.*)/i){			         
	         $curpgtvdose = $Globel_Prescriptions[$temp+1] * $Globel_FractionNum;  
	   }elsif($tempname =~ /^PTV(.*)/i){
	         $curptvdose = $Globel_Prescriptions[$temp+1] * $Globel_FractionNum; 
	   }
	   $temp = $temp + 1;
	}; 
	if($Globel_PlanType == 4 || $Globel_PlanType == 1){		    
			@typelist = ("Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD");
			@doselist = ($curpgtvdose + 160,$curpgtvdose - 640,$curptvdose + 160,$curptvdose - 800,$curptvdose -700,$curptvdose -1600,$curptvdose -1700,$curptvdose -2400,$curptvdose -2700,$curptvdose-3000,2500,1500);		    
	}elsif($Globel_PlanType == 5 || $Globel_PlanType == 2){
		    @typelist = ("Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD");
			@doselist = ($curpgtvdose + 160,$curpgtvdose - 400,$curpgtvdose -200,$curpgtvdose -1000,$curpgtvdose -600,$curpgtvdose -1400,$curpgtvdose -1200,$curpgtvdose -1600,3500,1500);	
	}else{
		    @typelist = ("Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD","Max Dose","Max EUD");
			@doselist = ($curptvdose + 160,$curptvdose - 400,$curptvdose -200,$curptvdose -1000,$curptvdose -600,$curptvdose -1400,$curptvdose -1200,$curptvdose-1600,3500,1500);
	};
	
	$temp = 0;
	foreach my $temptargetname (@Globel_ROIModifyList){
	   chomp($temptargetname);
	    if(!defined($temptargetname)){next;};
		@templistdata = split(/\t/,$temptargetname);
		
		if ($templistdata[2] eq 'PHANTOM'){		
			$CurTargetName = $templistdata[1];
	        $CurTargetType = $typelist[$temp];
	        $CurTargetDose = $doselist[$temp];	      
	        $CurTargetWeight = 30;	        
	           
			print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";		
			$curIMRTtargetposition += 1;
			
			$CurTargetName = $templistdata[1];
	        $CurTargetType = $typelist[$temp+1];
	        $CurTargetDose = $doselist[$temp+1];	      
	        $CurTargetWeight = 1;	        
	           
			print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";		
			$curIMRTtargetposition += 1;
			
			$temp = $temp + 2;			
		};
	};	
	
	foreach my $line (@Globel_ROIModifyList){
	    if(!defined($line)){next;};
		chomp $line;
		@templistdata = split(/\t/,$line);
		chomp $templistdata[2];
		if($templistdata[2] eq 'OAR'){
			foreach $CurTargetName (@TemplateData){		   
			    chomp($CurTargetName);
			    if($CurTargetName eq ""){next;};
			    my  @curlistdata = split(/\t/,$CurTargetName);
			    if($templistdata[1] eq $curlistdata[0]){
			         $CurTargetName = $curlistdata[0];
			         $CurTargetType = $curlistdata[1];
			         $CurTargetDose = $curlistdata[2];
			         if($CurTargetType eq "Max DVH"){
			             $CurTargetPerc = $curlistdata[3];
	                     $CurTargetWeight = $curlistdata[4];
			         }else{
			             $CurTargetWeight = $curlistdata[3];
			         };
			         print OUT "PluginManager .InversePlanningManager .AddObjective = \"Add Objective\";\n";
			         print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .ROIName = \"$CurTargetName\";\n";
			         print OUT "PluginManager .InversePlanningManager .SetObjectiveType .\#\"\#$curIMRTtargetposition\" = \"$CurTargetType\";\n";
			         print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Dose = \"$CurTargetDose\";\n";
			         if($CurTargetType eq "Max DVH"){
			             print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .UserPercent = \"$CurTargetPerc\";\n";
			         };
			         print OUT "PluginManager .InversePlanningManager .CombinedObjectiveList .\#\"\#$curIMRTtargetposition\" .Weight = \"$CurTargetWeight\";\n";			
			         $curIMRTtargetposition = $curIMRTtargetposition + 1;  
			    };
			};			
		};		  	
	};
	
	#Scripts file End Mark
	print OUT "/* *H */\n";	
	close(OUT);
};
##:Main function Begin
my $yyyymmdd = CurTime;
if (-e $FIN_SCRIPT){
	if ($debug){
		move("$FIN_SCRIPT","/home/p3rtp/Backup/ScriptsTemp/temp/$yyyymmdd.script") ;
	}else{
		unlink($FIN_SCRIPT);
	};	
};
##:Step1  checking ROIS
ROICheck($CurPlanRoiFile,$ROIList,$FIN_SCRIPT);

##:Step2  Create Target Ring and Nomal Tissue Area 
CreatRingNT($ROIList,$ROIListModify,$FIN_SCRIPT);

##:Step3   Ask Physician input The BeamsNumber
PlanBeamNum;

##:Step4   Ask Physican Input Discription of Plan
PlanTypeDef;

##:Step5  Create Iso point which is the center of (PGTV/PTV)
CreateISOPoint($FIN_SCRIPT);

##:Step6  Create New Beams  and setting the equal weights
#CreateBeams($BeamTemplate,$FIN_SCRIPT,$BeamNum);
CreateBeams($FIN_SCRIPT);

##:Step7  Define Prescription,ISO dose line,
DefinePrescriptionISODose($FIN_SCRIPT);

##:Step8  Mark displaying ROIs in DVH
MarkDisplayRoiDVH($FIN_SCRIPT);

##:Step9  Set IMRT Parameters and Add target and OAR doselimition 
IMRTSetting($FIN_SCRIPT);

PerlEND:print "end of programe\n";


