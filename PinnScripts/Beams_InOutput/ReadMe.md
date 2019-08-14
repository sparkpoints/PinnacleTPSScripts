目的：导出plan的Beam和Prescription信息，在新plan或者QAplan中导入刚刚导出的Beam和Pres信息，主要应用QA计划设计和多程计划的剂量叠加。

使用流程和设置
1. 打开待导出的Plan，记录每个Beam的MUs，选择exportbeams.Script.p3rtp脚本，导出beams
2. 打开目标Plan，选择importbeams..Script.p3rtp脚本，导入beams参数，正向计算FinalDose，然后将记录的Mus人工输入到beams的MU项中。
