#!/usr/bin/python
import sys
segment = ''
mus = 0.0
mlcfile = ''
outfile = ''
## main.py -s segment -v MU -m MLC.file -o out.file

mlcvarian120 = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,\
                0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,\
                0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,\
                1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1]
def CalcMLCArea(MLCfile):
    mlcfile = open(MLCfile,'r')    
    pointbeg = 0
    pointend = 1
    index = 0
    Area = 0.0
    for line in mlcfile:
        #print line
        if "NumberOfPoints" in line:
            NumberOfPoints = line.strip(';').split('=')[1].strip(' ')
        if 'Points[] ' in line:
            pointbeg = 1
            pointend = 0
            continue
        if pointbeg == 1 and pointend == 0 and index < NumberOfPoints:
            widthlist = line.strip(' ').split(',')
            width = float(widthlist[0])+float(widthlist[1])
            #print width,mlcvarian120[index]
            if width <= 0.5:
                width = 0
            Area += width * mlcvarian120[index]
            index += 1
        if index == 60:
            pointbeg = 0
            pointend = 1

            #print Area 
            mlcfile.close()
            #outfile.close()
            break
    return Area

#main
if __name__ == '__main__':
    if len(sys.argv) < 2:
    	exit()
    else:
       if sys.argv[1] == '-s':
       	   segment = sys.argv[2]
       if sys.argv[3] == '-v':
           mus = sys.argv[4]
       if sys.argv[5] == '-m':
       	   mlcfile = sys.argv[6]
       if sys.argv[7] == '-o':
           outfile = sys.argv[8]    
    MLCArea = CalcMLCArea(mlcfile)
    wightMU = float(MLCArea) * float(mus)
    outfile = open(outfile,'a+')
    print >> outfile, segment,mus,MLCArea,wightMU
    outfile.close()
