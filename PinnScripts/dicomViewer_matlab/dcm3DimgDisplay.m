function dcm3DimgDisplay(Dir_Path)
if nargin == 0
         [FilesSelected, dir_path] = uigetfile('*.zip','Select DICOM zip file');
         if isempty(FilesSelected);
              imaVOL = [];
              dcminfo = [];
              return;
         end
         filename = [dir_path,char(FilesSelected)];         
else
    return
end
    
%     import data using dicomreadvolume.m
[imaVOL dcminfo] = dicomreadvolume(filename); 
ct3(imaVOL,dcminfo); 
    
% ct3(dicomreadvolume(filename));


