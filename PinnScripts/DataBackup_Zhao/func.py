#!/usr/bin/python

import datetime
import time
import sys
import os
import glob
#############################################################  
#convert (today - dayspast) to string, argv[1]- how many days, for auto backup -c
def checkbackup(delta, modifiedtime):
  if len(modifiedtime) < 10:
    modifiedtime = '2015-01-01'
    
  d1 = (datetime.date.today() - datetime.timedelta(days=int(delta))).strftime('%Y%m%d')
  d2 = time.strftime('%Y%m%d', time.strptime(str(modifiedtime)[:10], '%Y-%m-%d'))
  if d2 < d1:
    print 'Value = 1;'
  else:
    print 'Value = 0;'  
  
#############################################################  
#check file exist, exist return 1, otherwize return 0   -f
def findfile(filename):
  if os.path.exists(filename) and os.path.isfile(filename):
    print 'Value = 1;'
  else:
    print 'Value = 0;'
    
    
#############################################################  
#find file and mk list, dirname- path, basename-filename   -m
def makepatientlist(pattern):     
  filelist = glob.glob(pattern)
  filelist.sort();
  for filename in filelist:  
    print 'PatientLite ={\n  PatientID = 0;\n  PatientPath = "%s";\n  MountPoint = "";\n  FormattedDescription = "%s";\n  DirSize = 0;\n};\n' %(os.path.dirname(filename), os.path.basename(filename))
  
#############################################################
#delete special char -t
def trimspecialchar(filestr):
  for c in ['-',':','&',' ', '.']:
    filestr=''.join(filestr.split(c))

  print 'String = "%s.tar";' % filestr.lower()

#############################################################
#really backup data  -b
def backup(output, patientpath, instpath):
  command = '/usr/sfw/bin/gtar -i -c -h -z -f %s --exclude=.auto.plan.Trial.binary.* -C %s Institution -C %s %s 2>&1' % (output, instpath, os.environ.get('PATIENTS'),patientpath)
#  print command
  os.popen(command)
  
#############################################################
#format log data  -l
def logfmt(filename):
  print '%-128s\t%-16s\t%-19s' % (filename, os.environ.get('USER'),datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

 
##########################################################  
#run lauchpad -a
def startlp(opt):
  command = 'echo "Value = %s;" > %s/.temp' % (opt, os.getcwd()) 
  os.popen(command)
  os.popen('StartPinnacle')
  
###########################################################
#main entry 
if __name__=='__main__':
  
  if len(sys.argv) == 1:
    startlp('0')
    
  else:
    if sys.argv[1]=='-a':
      startlp('1')
      
    if sys.argv[1]=='-b':
      backup(sys.argv[2], sys.argv[3], os.path.dirname(sys.argv[0]))  
      
    if sys.argv[1]=='-c':
      checkbackup(sys.argv[2], sys.argv[3])
    
    if sys.argv[1]=='-f':
      findfile(sys.argv[2])  
      
    if sys.argv[1]=='-l':
      logfmt(sys.argv[2])
      
    if sys.argv[1]=='-m':
      makepatientlist(sys.argv[2])
    
    if sys.argv[1]=='-t':
      trimspecialchar(sys.argv[2])
