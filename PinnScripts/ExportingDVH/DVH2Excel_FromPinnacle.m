function DVH_calculating_from_Pinnacle
%Usage: 找寻存储pinnacle计划系统导出DVH目录
%
DataDirPath = uigetdir('E:\dvhs');
DirList = dir(DataDirPath);
InstanceNum = length(DirList); %DVH个数
CurrentData = struct([]);      %输出的数据
for i = 1:InstanceNum          %依次处理每一个dvh文档
    if strcmp('.',DirList(i,1).name) == 1 
    elseif strcmp('..',DirList(i,1).name)== 1
    else
        CurrentData{i,1} = DirList(i,1).name;        
        Currentfile = [DataDirPath,'\',char(DirList(i,1).name)];   %Current dvh路径     
        CurrentData{i,2} = ManufactingData(Currentfile);      %调用函数处理后，数据存入CurrentData结构中
    end
end
%            %存入dvh.mat，
for i=3:length(CurrentData(:,1))
    CurrentData{i,1} = [CurrentData{i,1},'.xls'];       %excel 后缀xls
end
cd(DataDirPath);
[Flag] = mkdir(DataDirPath,'xls');                     %exceldata 存入dir./xls
if Flag == 1
    cd([DataDirPath,'/xls']);
    for i=3:length(CurrentData(:,1))
        xlswrite(CurrentData{i,1},CurrentData{i,2});		%存储为对应xls文档
    end
else
    disp('save CurrentData to currentdir dvh.mat');
    save dvh.mat CurrentData;
end

disp('work done!!!');



function Output = ManufactingData(filename)  %计算DVH百分比

InputStruct = importdata(filename);    %读入，存入struct
InputData = InputStruct.data;          %数据
DataLength = length(InputData(:,1));   %数据长度
index = DataLength;                    %index从大到小
Output = zeros(DataLength,4);
Sum = 0;
Mark = 0;
TotalVol = sum(InputData(:,2));
while(index)
    if InputData(index,2) ~= 0     %检查Maxdose开始位置
        Mark = 1; 
        Sum = Sum + InputData(index,2);         
    end
    if Mark == 1;               
        Output(index,1) = InputData(index,1);
        Output(index,2) = InputData(index,2);
        Output(index,3) = Sum;                  %绝对值
        Output(index,4) = Sum/TotalVol;         %百分比
    else
        Output(index,1:2) = InputData(index,1:2); %直接复制前两行数据
    end
    index = index - 1; 
end
