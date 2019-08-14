SavePlan = "Save Plan";// save plan data first

//Define stored variables
Store.FreeAt.HomeDir = "";  
Store.FreeAt.BinDir  = "";
Store.FreeAt.SysTempDir = "";
Store.At.HomeDir = SimpleString {};             //--Set Main dir contain all scripts
Store.At.HomeDir.AppendString = "/usr/local/adacnew/PinnacleSiteData/Scripts/IMRTcode/";
Store.At.BinDir = SimpleString {};              //--Set Perl Scripts dir
Store.At.BinDir.AppendString = Store.At.HomeDir.String;
Store.At.BinDir.AppendString = "bin/";
Store.At.SysTempDir = SimpleString {};          //--Set Temp dir
Store.At.SysTempDir.AppendString = Store.At.HomeDir.String;
Store.At.SysTempDir.AppendString = "Temp/";

//==========Checking! if this is a new plan ==========================================================
Store.FreeAt.TempInfoMessage = "";
Store.FloatAt.ErrorMark = 0;                 //ErrorMark = 3 is new plan
IF.PlanInfo.PlanIsEditable.THEN.Store.At.ErrorMark.Add = 1;
IF.TrialList.Current.BeamList.HasNoElements.THEN.Store.At.ErrorMark.Add = 1;
IF.TrialList.Current.PrescriptionList.HasNoElements.THEN.Store.At.ErrorMark.Add = 1;
IF.Store.At.ErrorMark.Value.NotEqualTo.#"#3".THEN
={
Store.At.TempInfoMessage = SimpleString{};
Store.At.TempInfoMessage.AppendString = "Error01       Now! The Scripts Not Support Phase2 Planning  ";
Store.At.TempInfoMessage.AppendString = "@Error02      Plan may Locked, Data will not saving     ";
Store.At.TempInfoMessage.AppendString = "@                                                  ";
Store.At.TempInfoMessage.AppendString = "@SO, Please copy a NewPlan, Del old Beams & PrescripDose, Re_Run this Scripts!";
WarningMessage = Store.At.TempInfoMessage.String;
Store.FreeAt.TempInfoMessage = "";
};

//Del empty ROIs
Store.At.TempInfoMessage = SimpleString{};
Store.At.TempInfoMessage.AppendString = Store.At.HomeDir.String;
Store.At.TempInfoMessage.AppendString = "RemoveEmptyROIs.Script.p3rtp";
IF.Store.At.ErrorMark.Value.EqualTo.#"#3".THEN.Script.ExecuteNow = Store.At.TempInfoMessage.String;
Store.FreeAt.TempInfoMessage = "";

//Checking Ref.point
Store.FloatAt.ErrorMark = 0;
IF.PoiList.Current.Name.Contains.#"POI".THEN.Store.At.ErrorMark.Add = 1;
IF.PoiList.Current.Name.Contains.#"Poi".THEN.Store.At.ErrorMark.Add = 1;
IF.PoiList.Current.Name.Contains.#"ref".THEN.Store.At.ErrorMark.Add = 1;
IF.PoiList.Current.Name.Contains.#"Ref".THEN.Store.At.ErrorMark.Add = 1;
IF.Store.At.ErrorMark.Value.GreaterThan.#"#0".THEN.Store.FloatAt.ErrorMark = 3;
IF.Store.At.ErrorMark.Value.LessThan.#"#3".THEN.WarningMessage = "You Must Mannually define <Ref.Point>";

//========================================================================================================
//Step1:Analyzing Plan data
Store.At.TempInfoMessage = SimpleString{};
Store.At.TempInfoMessage.AppendString = Store.At.HomeDir.String;
Store.At.TempInfoMessage.AppendString = "AnalyzingPlanData.Script.p3rtp";
IF.Store.At.ErrorMark.Value.EqualTo.#"#3".THEN.Script.ExecuteNow = Store.At.TempInfoMessage.String;
Store.FreeAt.TempInfoMessage = "";

//Step2:Define Dose and Setting Initial DMPO paramenterl

SavePlan = "Save Plan";                  //Save Result

//Free All variables
Store.FreeAt.HomeDir = "";
Store.FreeAt.BinDir  = "";
Store.FreeAt.SysTempDir = "";
Store.FreeAt.temp = "";


/* v */
