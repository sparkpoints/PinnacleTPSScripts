#!/usr/bin/python

import commands
import logging

logging.basicConfig(level=logging.DEBUG, format= '%(asctime)s %(filename)s[line:%(lineno)d] %(levelname)s %(message)s',\
                    datefmt='%a,%d %b %Y %H:%M:%s',filename='/home/ycw/bin/Session_Admin.log',filemode='a')
                    
app_name = commands.getoutput('uname -n')
logging.info("Session admin using the cron on %s" %app_name)

cmd = '/opt/SUNWut/sbin/utsession '
cmd_list = cmd + '-p'
cmd_kill = cmd + '-k'

if __name__ == "__main__":
    Doctors = ['wp','yzy','zbl','wpg','wfm','wj','zl','zlj','cj','pqs','zch','yjq',\
                'syc','sj','czj','zwc','wjing','rk','lzy','gll','yb','gy','mmb','wq',\
                'hhl','lnb','zxm','tzh','zbz','wzz','lyz','wx','sy','xlm','qd','wzq',\
                'lxx','cyj','yzz']
    print "begin"
    Physics = ['ww','dmg','zrp','jsp','ycw','zdg','jb','wqx','zhj','p3rtp']
    LoginUsers = commands.getoutput(cmd_list)
    
    UsersList  = [line for line in LoginUsers.split('\n') if line.strip() != '']
    for line in UsersList:
        UserInfo = line.split()
        if UserInfo[2] in Doctors:
            killuser = cmd_kill + ' -d ' + UserInfo[3]
            killstatus = commands.getstatusoutput(killuser)
            if killstatus[0] == 0:
                logging.info("Successfull kill user:%s"%UserInfo[2])

    logging.info("Session Ends on %s" %app_name)
    print "End"
    #print UsersList[3]
