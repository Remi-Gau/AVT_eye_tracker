%% Analyze dummy calibration data
%%
clc; clear; close all;

Subjects = 2;
Run = 1;

% Screen variable
Opt.HorRes = 1024;
Opt.MonWidth = 38;
Opt.ViewDist = 54;
% Maximum field of view in degrees of visual angles
Opt.MaxFOV = 2.0 * 180.0 * atan(Opt.MonWidth/2.0/Opt.ViewDist)/ pi;
% Pixel per degreee
Opt.PPD = Opt.HorRes/Opt.MaxFOV;

% Eye tracker variable
Opt.SamplingFreq = 120;

% Azimuth and elevation used for the calibration in degrees of visual
% angles.
% we assumed that the median value for each of those range is 0;
Opt.ElevationLvls = -8:8:8;
Opt.AzimuthLvls = -8:4:8;

Opt.CalibDur = 3000;
Opt.PreCalibDur = 200;
Opt.PostCalibDur = 250;
Opt.Color='cbgymcbgymcbgym'; % colors to use to plot the different fixation trials

Opt.NbSDCalib = 3;

% Opt.StimDur = 50;
% Opt.PreStimDur = 1400;
% Opt.PostStimDur = 700;
% 
% Opt.PreStimWin = 50;
% Opt.PostStimWin = 450;
% 
% Opt.DataPtsPerTrial = ceil((Opt.StimDur+Opt.PreStimDur+Opt.PostStimDur)/1000*Opt.SamplingFreq);
% 
% Opt.NbSD = 5;
% 
% Opt.SaccVelThresh = 15/1000; % in deg per msec
% Opt.SaccDurThresh = 60; % in ms
% Opt.SaccRadAmp = 1;
% 

% Dimensions of figures to plot
Opt.FigDim = [100 100 1200 900];
Opt.Print = 1;
Opt.Visible = 'on';

% first row of data points in txt file
IndStart = 2;

SubjInd = 1;

StartDirectory = pwd;

FigDir = StartDirectory;
Opt.FigDir = FigDir;

LogFileList = dir(fullfile(StartDirectory, 'Subjects_Data', ...
    ['Subject_' sprintf('%1.0f', Subjects(SubjInd))], 'Behavioral', ...
    ['GazeData_Subject_', num2str(Subjects(SubjInd)), '_Run_*.txt']));

RunNumber = LogFileList(Run).name(end-23:end-20);

% Extracts the content of the text file
disp(LogFileList(Run).name)
fid = fopen(fullfile(StartDirectory, 'Subjects_Data', ...
    ['Subject_' sprintf('%1.0f', Subjects(SubjInd))], 'Behavioral', ...
    LogFileList(Run).name ));
FileContent = textscan(fid,'%s %s %s %s %s %s %s %s %s', 'headerlines', IndStart, 'returnOnError',0);
fclose(fid);
clear fid

% index	 pos_time  pos_x  pos_y  marker

% Turns each string cell into an array
% index	 pos_time  pos_x  pos_y  pup_time  pup_x_diameter pup_y_diameter  blink_status  marker
EyeData.Time = str2num(char(FileContent{1,2})); % The unit is ms. This means, with a sampling rate of 120hz,
% that that the inter-sample interval will be 9 ms for one third of the sampled data points.
EyeData.Pos_x = str2num(char(FileContent{1,3})); % Horizontal position of the gaze
EyeData.Pos_y = str2num(char(FileContent{1,4})); % Vertical position of the gaze
EyeData.Pup_x_diameter = str2num(char(FileContent{1,5})); % Same for the pupil diameter
EyeData.Pup_y_diameter = str2num(char(FileContent{1,6}));
EyeData.Blink = str2num(char(FileContent{1,7})); % Markers for blinks (-1: normal; 1: EyeData.Blink start; 0: EyeData.Blink end)
EyeData.Marker = str2num(char(FileContent{1,8})); % Triggers for the beginning and end of each fixation trial

EyeData.Name = LogFileList.name;

clear FileContent


%% Check amount of missing data
% Sometimes the eyetracker stops recording when it loses the eyes.
% We try here to estimate of lost data points. This is likely to be
% an underestimate because position data during a EyeData.Blink should be
% removed as well.
RecDur = (EyeData.Time(end)-EyeData.Time(1));
MaxDataPoints = round(RecDur/(1000/Opt.SamplingFreq));
PercentMissingData = round ( ( (MaxDataPoints - numel(EyeData.Time)) ) / MaxDataPoints * 100 );
fprintf('Missing %i percent of %i seconds recording.\n', PercentMissingData, round(RecDur/1000) )


%% Calibration
[EyeData] = TobiiEyeXTrackCalib(EyeData, Opt);


