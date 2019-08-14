function DcmSimpleViewer
%function ct3(matrix2display,w)

%% Seraching Dicom Dir
if nargin == 0
    dirname = uigetdir('C:\Documents and Settings\Administrator\My Documents\MATLAB\HFS');
    if isempty(dirname)
        disp('empty dir');
        return;
    end;
end;  
%% import dicom data
[dosecell,dose_xmesh,dose_ymesh,dose_zmesh,ctcell,ct_xmesh,ct_ymesh,ct_zmesh,VOI]=dicomrt_DICOMimport(dirname,'r');

%% dicom data pre-analyzing
[matrix2display_temp,type_matrix,labelm,PatientPosition]=dicomrt_checkinput(ctcell);
[dose2display_temp,type_dose,labeld,PatientPosition]=dicomrt_checkinput(dosecell);
matrix2display=dicomrt_varfilter(matrix2display_temp);   %ct data
dose2display=dicomrt_varfilter(dose2display_temp);       %dose data

if exist('VOI')==1                                      %check Voi data
    [VOI_temp]=dicomrt_checkinput(VOI);
    VOI=dicomrt_varfilter(VOI_temp);
end
temp = size(VOI);
voi2use = 1:2:temp(1);              % displaying contours by Seq_number!

% Check normalization and initialize plot parameters: 
normDose = 30;
levels = [105 95 80 70 50];
if normDose~=0
    dose2display=dose2display./normDose.*100;    % 
end
% Set isolevels display
[contourcolor,doseareas]=dicomrt_setisolevels(normDose,dosecell);

%% displaying ct-slice number pre-define
Xmax = size(matrix2display,1);         %max number of X dimension
Ymax = size(matrix2display,2);         %max number of Y dimension
Zmax = size(matrix2display,3);         %max number of Z dimension
    
XCurSlice = floor(Xmax/2);
YCurSlice = floor(Ymax/2);
ZCurSlice = floor(Zmax/2); 
%% INITALIZE THE FIGURE WINDOWS
% Trans plane
TranFig = figure(3); %f3
im_z = get(TranFig,'CurrentAxes');
displaying(TranFig,ZCurSlice,'z');

% Cronal Plane
CronFig = figure(1); %f1
im_x = get(CronFig,'CurrentAxes');
displaying(CronFig,XCurSlice,'x');

% Segg Plane
SeggFig = figure(2); %f2
im_y = get(SeggFig,'CurrentAxes');
displaying(SeggFig,YCurSlice,'y');


set(SeggFig, 'WindowScrollWheelFcn', @wheel)
set(SeggFig, 'WindowButtonDownFcn', @click)
set(CronFig, 'WindowScrollWheelFcn', @wheel)
set(CronFig, 'WindowButtonDownFcn', @click)
set(TranFig, 'WindowScrollWheelFcn', @wheel)
set(TranFig, 'WindowButtonDownFcn', @click)


%% CAPTURE MOUSEWHEEL EVENTS
    function wheel(src, evnt)
        cur=gcf;
        switch cur
            case 1
                if evnt.VerticalScrollCount > 0
                    XCurSlice=XCurSlice+1;
                else
                    XCurSlice=XCurSlice-1;
                end
                if XCurSlice>Xmax
                    XCurSlice=Xmax;
                elseif XCurSlice<1
                    XCurSlice=1;
                else
                    displaying(SeggFig,XCurSlice,'x')
                end
%                 do_lines
            case 2
                if evnt.VerticalScrollCount > 0
                    YCurSlice=YCurSlice-1;
                else
                    YCurSlice=YCurSlice+1;
                end
                if YCurSlice>Ymax
                    YCurSlice=Ymax;
                elseif YCurSlice<1
                    YCurSlice=1;
                else
                    displaying(CronFig,YCurSlice,'y');
                end
%                 do_lines
            case 3
                if evnt.VerticalScrollCount > 0
                    ZCurSlice=ZCurSlice+1;
                else
                    ZCurSlice=ZCurSlice-1;
                end
                if ZCurSlice>Zmax
                    ZCurSlice=Zmax;
                elseif ZCurSlice<1
                    ZCurSlice=1;
                else            
                    displaying(TranFig,ZCurSlice,'z');
                end
%                 do_lines
            otherwise
                %do nothing
        end
    end

%% CAPTURE MOUSE CLICKS
    function click(src,evnt)
        %account for reversal of z dimension
        disp(num2str([XCurSlice YCurSlice (Zmax+1-ZCurSlice)]))
    end

%% REDRAW MARKER LINES
%     function do_lines
% %         set(p131,'YData',[ZCurSlice ZCurSlice]);
% %         set(p121,'XData',[YCurSlice YCurSlice]);
% %         set(p132,'YData',[ZCurSlice ZCurSlice]);
% %         set(p122,'XData',[YCurSlice YCurSlice]);
% %         
% %         set(p231,'YData',[ZCurSlice ZCurSlice]);
% %         set(p211,'XData',[XCurSlice XCurSlice]);
% %         set(p232,'YData',[ZCurSlice ZCurSlice]);
% %         set(p212,'XData',[XCurSlice XCurSlice]);
%         
%         set(p311,'XData',[ct_xmesh(XCurSlice) ct_xmesh(XCurSlice)]);
%         set(p321,'YData',[ct_ymesh(YCurSlice) ct_ymesh(YCurSlice)]);
%         set(p312,'XData',[ct_xmesh(XCurSlice) ct_xmesh(XCurSlice)]);
%         set(p322,'YData',[ct_ymesh(YCurSlice) ct_ymesh(YCurSlice)]);
%     end
%% displaying function
    function displaying(gcf,CurSlice,axis_dirc)
        % figure displaying        
        if axis_dirc == 'z' || axis_dirc == 'Z'
%             set(gcf,'CurrentAxes',im_z);
            set(gcf,'Name',['TransPlane_SliceNo:',num2str(CurSlice),'(',num2str(ct_zmesh(CurSlice)),'cm/z)']);
            set(gcf,'MenuBar','none');
            get(gcf,'CurrentAxes');
            imagesc(matrix2display(:,:,CurSlice),'XData',ct_xmesh,'YData',ct_ymesh);
            colormap(gray); 
            
            %display voi
            hold on 
            if exist('VOI')==1      
                dicomrt_plotVOI(3,CurSlice,VOI_temp,voi2use,ct_xmesh,ct_ymesh,ct_zmesh,PatientPosition);        
            end
%             p311=plot([ct_xmesh(XCurSlice) ct_xmesh(XCurSlice)],[ct_ymesh(end) ct_ymesh(end)-2],'g', 'linewidth',2);
%             p312=plot([ct_xmesh(XCurSlice) ct_xmesh(XCurSlice)],[ct_ymesh(1) ct_ymesh(1)+2],'g', 'linewidth',2);
%             p321=plot([ct_xmesh(1) ct_xmesh(1)+2],[ct_ymesh(YCurSlice) ct_ymesh(YCurSlice)],'g', 'linewidth',2);
%             p322=plot([ct_xmesh(end)-2 ct_xmesh(end)],[ct_ymesh(YCurSlice) ct_ymesh(YCurSlice)],'g', 'linewidth',2);
            xlabel('X axis (cm)','FontSize',12);
            ylabel('Y axis (cm)','FontSize',12);
            
            % display dose
            doseSlice=dicomrt_findsliceVECT(ct_zmesh,CurSlice,dose_zmesh,PatientPosition); %get dose_num(using ct_num)
            if isempty(doseSlice) ~= 1
                for i=1:length(levels)
                    % Z axis           -> XY image
                    [n,p] = histc(levels(i),doseareas);
                    [C,h]=contour(dose_xmesh,dose_ymesh,dose2display(:,:,doseSlice),[levels(i) levels(i)],contourcolor(p));
                    xlabel('X axis (cm)','FontSize',12)
                    ylabel('Y axis (cm)','FontSize',12)
                    set(h,'Linewidth',2);
                    if isempty(C)~=1
                        labl=clabel(C,h);
                        set(labl,'Color',contourcolor(p));
                        set(labl,'FontWeight','bold');
                    else
                        warning(['dicomrt_displaycontour: Contour for :',num2str(levels(i)),' was not found']);
                    end                
                end
            end
            hold off
        elseif axis_dirc == 'y' || axis_dirc == 'Y'
%             set(gcf,'CurrentAxes',im_y);
            set(gcf,'Name',['SeggPlane_SliceNo:',num2str(CurSlice),'(',num2str(ct_ymesh(CurSlice)),'cm/y)']);
            set(gcf,'MenuBar','none');
            get(gcf,'CurrentAxes');
            imagesc(permute(matrix2display(:,CurSlice,:),[3 1 2]),'XData',ct_zmesh,'YData',ct_xmesh);
            colormap(gray);
            xlabel('Z axis (cm)','FontSize',12);
            ylabel('X axis (cm)','FontSize',12);
        elseif axis_dirc == 'x' || axis_dirc == 'X'      
%             set(gcf,'CurrentAxes',im_x);
            set(gcf,'Name',['CronPlane_SliceNo:',num2str(CurSlice),'(',num2str(ct_xmesh(CurSlice)),'cm/x)']);
            set(gcf,'MenuBar','none');
            get(gcf,'CurrentAxes');
            imagesc(permute(matrix2display(CurSlice,:,:),[3 2 1]),'XData',ct_zmesh,'YData',ct_ymesh);
            colormap(gray);
            xlabel('Z axis (cm)','FontSize',12);
            ylabel('Y axis (cm)','FontSize',12);
        end
    end    
end