// save plan data first
SavePlan = "Save Plan";

//Free temp stored variables
Store.FreeAt.TempHomeDir = "";
Store.FreeAt.TempCommand = "";
Store.FreeAt.TempExeFile = "";
Store.FreeAt.TempExeFileApp = "";
Store.FreeAt.TempSysDir  = "";

Store.FreeAt.TempPlan = "";
Store.FreeAt.TempPatient = "";
Store.FreeAt.TempMRN = "";
Store.FreeAt.TempPlanPath = "";

// determine MedRecNum, patient, plan, revision names
Store.At.TempMRN = SimpleString {};
Store.At.TempMRN.AppendString = PlanInfo.MedicalRecordNumber;
Store.At.TempPatient = SimpleString {};
Store.At.TempPatient.AppendString = PlanInfo.PatientName;
Store.At.TempPlan = SimpleString {};
Store.At.TempPlan.AppendString = PlanInfo.PlanName;
Store.At.TempPlanPath = SimpleString {};
Store.At.TempPlanPath.AppendString = PlanInfo.PlanPath;


//Set bin  Home Dir "/home/p3rtp/bin/"
Store.At.TempHomeDir = SimpleString {};
Store.At.TempHomeDir.AppendString = "/home/p3rtp/bin/";

//Set Pinnacle Scripts dir
Store.At.TempSysDir = SimpleString {};
Store.At.TempSysDir.AppendString = "/usr/local/adacnew/PinnacleSiteData/Scripts/TempScripts/";

//Set Target Pinnacle Scripts Name:"CurrentIMRTStepOne.Script.p3rtp"
Store.At.TempExeFile = SimpleString {};
Store.At.TempExeFile.AppendString = Store.At.TempSysDir.String;
Store.At.TempExeFile.AppendString = "CurrentIMRTStepOne.Script.p3rtp";

//Set Target Pinnacle Scripts Name:"CurrentIMRTStepTwo.Script.p3rtp"
Store.At.TempExeFileApp = SimpleString {};
Store.At.TempExeFileApp.AppendString = Store.At.TempSysDir.String;
Store.At.TempExeFileApp.AppendString = "IMRTStepTwo.Script.p3rtp";



//Step1:run "Lung_IMRT.perl" to Create Target PinnaScripts 
Store.At.TempCommand = SimpleString {};
Store.At.TempCommand.AppendString = "xterm -e perl ";
Store.At.TempCommand.AppendString = Store.At.TempHomeDir.String;
Store.At.TempCommand.AppendString = "IMRTStepOne.pl ";
Store.At.TempCommand.AppendString = " -l \"";
Store.At.TempCommand.AppendString = Store.At.TempPlanPath.String;
Store.At.TempCommand.AppendString = "\"";
//execute this perl scripts
SpawnCommand = Store.At.TempCommand.String;

//Free
Store.FreeAt.TempCommand = ""; 

//2 of Step1:run the target PinnScripts:"CurrentIMRTStepOne.Script.p3rtp"
Store.FreeAt.TempAnswer = "";
AskYesNoDefault = 1;
AskYesNoPrompt = "Running This Script?";
Store.FloatAt.TempAnswer = AskYesNo;
IF.Store.At.TempAnswer.Value.THEN.Script.ExecuteNow = Store.At.TempExeFile.String;
IF.Store.At.TempAnswer.Value.THEN.Script.ExecuteNow = Store.At.TempExeFileApp.String;

// save plan data first
SavePlan = "Save Plan";

//Free All variables
Store.FreeAt.TempPlan = "";
Store.FreeAt.TempPatient = "";
Store.FreeAt.TempMRN = "";
Store.FreeAt.TempPlanPath = "";
Store.FreeAt.TempExeFile = "";
Store.FreeAt.TempHomeDir = "";
Store.FreeAt.TempSysDir  = "";
/* v */
