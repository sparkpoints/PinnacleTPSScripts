Run.Script----------------------------Main Route Entry

  CreateBackupList.Script-------------Create Backup List
    LoadPatien.Script-----------------After Backup List Created, Load all Patient

  //////////////////////////////////////////////////////
  AutoBackup.Script-------------------Auto Backup Entry
    FindForBackup.Script--------------Find Old Patients and Check Backup Indicator

  //////////////////////////////////////////////////////
  ManualBackup.Script-----------------Manual Backup Entry, Show a Form and Check Backup Indicator



  BackupOne.Script--------------------Start Backup a Patient
    MakeFilename.Script---------------Make filename According to Patient Info
    FindFile.Script-------------------Check if above file is existing
    GenBackupInstitution.Script-------Generate Institution File for Backup
    WriteLogFile.Script---------------If Backup Successful, Write log to file
  
  
  MovePatient.Script------------------Move Patients to Specified Institution if Required
  
  
  
func.py-------------------------------Some functions for special use