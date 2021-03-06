%%
clc; clear; close all

addpath(genpath(fullfile(pwd, 'SubFun')))

Subjects = 2;

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

Opt.StimDur = 50;
Opt.PreStimDur = 1400; % 1400
Opt.PostStimDur = 700;  % 700

Opt.PreStimWin = 50; %50
Opt.PostStimWin = 450; %450

Opt.DataPtsPerTrial = ceil((Opt.StimDur+Opt.PreStimDur+Opt.PostStimDur)/1000*Opt.SamplingFreq);

% Proportion valid points per trial needed for trial to be included
Opt.PropDataPtsPerTrial = 0.75;

% Threshold to remove outliers
Opt.NbSD = 5;

% Saccades detection
Opt.SaccVelThresh = 15/1000; % in deg per msec
Opt.SaccDurThresh = 60; % in ms
Opt.SaccRadAmp = 1;

% Fixation threshold: radius in visual angle
Opt.FixThres = 2;
Opt.BadFixThres = [.15 .05];

% Amount of bad trials
Opt.BadTrialsThres = [.15 .05];

% Dimensions of figures to plot
Opt.FigDim = [100 100 1200 900];
Opt.Print = 1;
Opt.Visible = 'on';

% first row of data points in txt file
IndStart = 2;

StartDirectory = pwd;

SaccadesAll = nan(1,length(Subjects));
Saccades = cell(1,length(Subjects));


Fixation= cell(1,length(Subjects));

for SubjInd = 1:length(Subjects)
    
    FigDir = fullfile(StartDirectory,'Figures','PsyPhySubjects', ...
        strcat('Subject_', sprintf('%1.0f', Subjects(SubjInd))));
    Opt.FigDir = FigDir;
    mkdir(FigDir)
    
    DataFolder = fullfile(StartDirectory, 'Subjects_Data', ...
        strcat('Subject_', sprintf('%1.0f', Subjects(SubjInd))), ...
        'Behavioral');
    
    LogFileList = dir(fullfile(DataFolder,...
        strcat('GazeData_Subject_', num2str(Subjects(SubjInd)), '_Run_30*.txt')) );
    
    for iFile = 1:length(LogFileList)

        RunNumber = LogFileList(iFile).name(end-23:end-20);
        
        TEMP = dir(fullfile(DataFolder,...
            strcat('Trial_List_Subject_', num2str(Subjects(SubjInd)), '_Run_', RunNumber ,'*.txt')) );
        TrialList = load(fullfile(DataFolder,TEMP.name));
        
        
        TEMP = dir(fullfile(DataFolder,...
            strcat('Side_List_Subject_', num2str(Subjects(SubjInd)), '_Run_', RunNumber ,'*.txt')) );
        SideList = load(fullfile(DataFolder,TEMP.name));
        SideList(TrialList==0)=[];
        
        SideList(SideList==4) = -1;
        SideList(SideList==8) = 0;
        SideList(SideList==12) = 1;
        
        TrialList(TrialList==0)=[];
        
        % Extracts the content of the text file
        disp(LogFileList(iFile).name)
        fid = fopen(fullfile(DataFolder, LogFileList(iFile).name));
        FileContent = textscan(fid,'%s %s %s %s %s %s %s %s', 'headerlines', IndStart, 'returnOnError',0);
        %         FileContent = textscan(fid,'%s %s %s %s %s', 'headerlines', IndStart, 'returnOnError',0);
        fclose(fid);
        clear fid
        
        % index	 pos_time  pos_x  pos_y  pup_time  pup_x_diameter  pup_y_diameter  blink_status  marker
        
        % Turns each string cell into an array
        % index	 pos_time  pos_x  pos_y  pup_time  pup_x_diameter pup_y_diameter  blink_status  marker
        EyeData.Time = str2num(char(FileContent{1,2})); % The unit is ms. This means, with a sampling rate of 120hz,
        % that that the inter-sample interval will be 9 ms for one third of the sampled data points.
        EyeData.Pos_x = str2num(char(FileContent{1,3})); % Horizontal position of the gaze
        EyeData.Pos_y = str2num(char(FileContent{1,4})); % Vertical position of the gaze
        %         EyeData.Pup_x_diameter = str2num(char(FileContent{1,5})); % Same for the pupil diameter
        %         EyeData.Pup_y_diameter = str2num(char(FileContent{1,6}));
        %         EyeData.Blink = str2num(char(FileContent{1,7})); % Markers for blinks (-1: normal; 1: EyeData.Blink start; 0: EyeData.Blink end)
        EyeData.Marker = str2num(char(FileContent{1,8})); % Triggers for the beginning and end of each fixation trial
        %         EyeData.Marker = str2num(char(FileContent{1,5})); % Triggers for the beginning and end of each fixation trial
        
        
        % Clean the data when the
        EyeData.Pos_x(EyeData.Pos_x==-10000) = NaN;
        EyeData.Pos_y(EyeData.Pos_y==-10000) = NaN;
        
        EyeData.Blink = isnan(EyeData.Pos_x);
        
        OverTime = find(diff(EyeData.Time)>1000);
        
        for i=1:numel(OverTime)
            EyeData.Time(OverTime(i)+1:end) = EyeData.Time(OverTime(i)+1:end)-1000;
        end
        
        
        EyeData.Name = LogFileList(iFile).name;
        
        EyeData.PixPerDegX = Opt.PPD;

        clear FileContent
        
        %% Check amount of missing data
        % Sometimes the eyetracker stops recording when it loses the eyes.
        % We try here to estimate of lost data points. This is likely to be
        % an underestimate because position data during a EyeData.Blink should be
        % removed as well.
        RecDur = (EyeData.Time(end)-EyeData.Time(1));
        MaxDataPoints = round(RecDur/(1000/Opt.SamplingFreq));
        %         PercentMissingData = round ( ( MaxDataPoints - numel(EyeData.Time) ) / MaxDataPoints * 100 );
        PercentMissingData = round ( ( (MaxDataPoints - numel(EyeData.Time)) + sum(isnan(EyeData.Pos_x)) ) / MaxDataPoints * 100 );
        fprintf('Missing %i percent of %i seconds recording.\n', PercentMissingData, round(RecDur/1000) )
        
        %% Calibration
        [EyeData] = TobiiEyeXTrackCalib(EyeData, Opt);
        
        %% Trials overview
        MarkersToPlot = find(EyeData.Marker>=numel(EyeData.TrialsStarts)+1);
        EyeData.Marker(MarkersToPlot) = EyeData.Marker(MarkersToPlot)-(numel(EyeData.TrialsStarts));
        TrialsDataSamples = MarkersToPlot(1):numel(EyeData.Time);
        
        fprintf('Analysing trials data\n')
        TrialsDur = EyeData.Time(TrialsDataSamples(end))-EyeData.Time(TrialsDataSamples(1));
        MaxNbSamples = round(TrialsDur/(1000/Opt.SamplingFreq));
        PercentMissingDataTrials = round ( ...
            ( (MaxNbSamples - numel(TrialsDataSamples)) +  ...
            sum(isnan(EyeData.Pos_x(TrialsDataSamples(1):TrialsDataSamples(end)))) )...
            / MaxNbSamples * 100 );
        fprintf(' Missing %i percent of %i seconds recording.\n', PercentMissingDataTrials, round(TrialsDur/1000) )
        
        
        figure('name', ['Overview trials - ' EyeData.Name], ...
            'position', Opt.FigDim, 'visible', Opt.Visible)
        %         subplot(321)
        subplot(311)
        hold on
        plot(EyeData.Time(TrialsDataSamples), EyeData.Pos_x(TrialsDataSamples))
        plot(EyeData.Time(MarkersToPlot), EyeData.Pos_x(MarkersToPlot),'or')
        H = axis;
        axis([H(1)  EyeData.Time(TrialsDataSamples(end)) H(3) H(4)])
        
        %         subplot(322)
        %         hold on
        %         plot(EyeData.Time(TrialsDataSamples), EyeData.Pup_x_diameter(TrialsDataSamples))
        %         plot(EyeData.Time(MarkersToPlot), EyeData.Pup_x_diameter(MarkersToPlot),'or')
        
        %         subplot(323)
        subplot(312)
        hold on
        plot(EyeData.Time(TrialsDataSamples), EyeData.Pos_y(TrialsDataSamples))
        plot(EyeData.Time(MarkersToPlot), EyeData.Pos_y(MarkersToPlot),'or')
        H = axis;
        axis([H(1)  EyeData.Time(TrialsDataSamples(end)) H(3) H(4)])
        
        %         subplot(324)
        %         hold on
        %         plot(EyeData.Time(TrialsDataSamples), EyeData.Pup_y_diameter(TrialsDataSamples))
        %         plot(EyeData.Time(MarkersToPlot), EyeData.Pup_y_diameter(MarkersToPlot),'or')
        
        subplot(313)
        hold on
        plot(EyeData.Time(TrialsDataSamples), EyeData.Blink(TrialsDataSamples))
        plot(EyeData.Time(MarkersToPlot), EyeData.Blink(MarkersToPlot),'or')
        H = axis;
        axis([H(1)  EyeData.Time(TrialsDataSamples(end)) H(3) H(4)])
        
        %         subplot(326)
        %         hold on
        %         plot(EyeData.Time(TrialsDataSamples), EyeData.Blink(TrialsDataSamples))
        %         plot(EyeData.Time(MarkersToPlot), EyeData.Blink(MarkersToPlot),'or')
        
        if Opt.Print
            print(gcf, fullfile(FigDir, ['OverviewTrials_' EyeData.Name '.tif']), '-dtiff')
        end
        
        %% Cleaning
        % Remove calibration data
        EyeData.Time = EyeData.Time(TrialsDataSamples);
        EyeData.Pos_x = EyeData.Pos_x(TrialsDataSamples)-EyeData.X_0ffset;
        EyeData.Pos_y = EyeData.Pos_y(TrialsDataSamples)-EyeData.Y_0ffset;
        
        %         EyeData.Pup_x_diameter = EyeData.Pup_x_diameter(TrialsDataSamples);
        %         EyeData.Pup_y_diameter = EyeData.Pup_y_diameter(TrialsDataSamples);
        
        %         EyeData.Blink = EyeData.Blink(TrialsDataSamples);
        EyeData.Blink = isnan(EyeData.Pos_x);
        
        EyeData.Marker = EyeData.Marker(TrialsDataSamples);
        
        TrialsStarts = find(EyeData.Marker);
        
        EyeData.iTime = [];
        EyeData.iMarkers = [];
        EyeData.iPos_x = [];
        EyeData.iPos_y = [];
        EyeData.iV = [];
        EyeData.iA = [];
        
        EyeData.Saccades = [];
        
        if numel(TrialList)~=numel(TrialsStarts)
            warning('We are missing the data for %i trials.', numel(TrialList)-numel(TrialsStarts))
        end
        
        
        %%
        % Data points with an absolute distance to the median bigger than a
        % certain value will be excluded
        X = EyeData.Pos_x;
        stdX = mad(X,1);
        devX = abs(X - median(X));
        
        Y = EyeData.Pos_y;
        stdY = mad(Y,1);
        devY = abs(Y - median(Y));
        
        Remove = find(any([devX>Opt.NbSD*stdX devY>Opt.NbSD*stdY],2));
        
        EyeData.Blink(Remove) = 1;
        EyeData.Pos_y(Remove) = NaN;
        EyeData.Pos_x(Remove) = NaN;
        clear Remove X Y stdY devY stdX devX
        
        EyeData.Pos_x = EyeData.Pos_x-nanmean(EyeData.Pos_x);
        EyeData.Pos_y = EyeData.Pos_y-nanmean(EyeData.Pos_y);
        
        
        TrialTime = zeros(size(EyeData.Marker));
        for iMarker = 1:numel(TrialsStarts)
            
            iTrialStart = find(EyeData.Time>=EyeData.Time(TrialsStarts(iMarker)), 1, 'first');
            iTrialEnd = find(EyeData.Time>=(EyeData.Time(iTrialStart)+Opt.PreStimDur+Opt.StimDur+Opt.PostStimDur), 1, 'first');
            if isempty(iTrialEnd)
                iTrialEnd = numel(EyeData.Time);
            end
            
            %             NbBlkPoint = sum(EyeData.Blink(iTrialStart:iTrialEnd)>-1)
            NbBlkPoint = sum(EyeData.Blink(iTrialStart:iTrialEnd)>0);
            
            %We need a proportion of the data points to be valid to
            %continue otherwise the whole trial is considered like a blink
            if iTrialEnd-iTrialStart-NbBlkPoint<(Opt.DataPtsPerTrial*Opt.PropDataPtsPerTrial) || ...
                    (EyeData.Time(iTrialEnd)-EyeData.Time(iTrialStart))<1800
                
                if iMarker<numel(TrialsStarts)
                    iTrialEnd=TrialsStarts(iMarker+1);
                else
                    iTrialEnd=numel(EyeData.Time);
                end
                
                EyeData.Blink(iTrialStart:iTrialEnd) = 1;
                
                EyeData.Trials{iMarker,1} = [];
                EyeData.Saccades(iMarker,1) = NaN;
                
                EyeData.Fixation(iMarker,1) = NaN;
                
                
            else
                
                iTime = EyeData.Time(iTrialStart):EyeData.Time(iTrialEnd);
                CollectedTimes = ismember(iTime,EyeData.Time(iTrialStart:iTrialEnd));
                
                ValidTimePoints = CollectedTimes;
                ValidTimePoints(ValidTimePoints==1) = EyeData.Blink(iTrialStart:iTrialEnd)==0;
                
                % Interpolate the missing point so that we have a 1000 hz
                % resolution
                iPos_x = nan(size(iTime));
                iPos_x(CollectedTimes) = EyeData.Pos_x(iTrialStart:iTrialEnd);
                itmp = interp1( find(ValidTimePoints), iPos_x(find(ValidTimePoints)), ...
                    find(~ValidTimePoints),  'linear', 'extrap' ); %#ok<*FNDSB>
                iPos_x(find(~ValidTimePoints)) = itmp; clear itmp
                
                iPos_y = nan(size(iTime));
                iPos_y(CollectedTimes) = EyeData.Pos_y(iTrialStart:iTrialEnd);
                itmp = interp1( find(ValidTimePoints), iPos_y(find(ValidTimePoints)), ...
                    find(~ValidTimePoints),  'linear', 'extrap' );
                iPos_y(find(~ValidTimePoints)) = itmp; clear itmp
                
                clear CollectedTimes ValidTimePoints
                
                
                % Running average
                % running average filter length: 5th of the sampling rate
                % (200 ms)
                SmoothWinWidth = ceil(1000/Opt.SamplingFreq*5);
                X = nan(size(iPos_y));
                Y = nan(size(iPos_y));
                for i=1:length(iPos_x)-SmoothWinWidth+1
                    X(i)=nanmean(iPos_x(i:i+SmoothWinWidth-1));
                    Y(i)=nanmean(iPos_y(i:i+SmoothWinWidth-1));
                end
                iPos_x = X;
                iPos_y = Y;
                clear X Y
                
                
                % compute velocity on interpolated data
                iV_x=gradient(iPos_x, 1);
                iV_y=gradient(iPos_y, 1);
                iV=sqrt(iV_x.^2+iV_y.^2);
                
                
                % physical distance from fixation
                iDist = sqrt((iPos_x.^2 + iPos_y.^2));
                
                
                % compute acceleration
                iA_x=gradient(iV_x, 1);
                iA_y=gradient(iV_y, 1);
                iA=gradient(iV, 1);
                
                
                %% Saccade detection
                
                % Velocity larger than some threshold
                VelThres = double((iV>Opt.SaccVelThresh*(range(EyeData.X_CalibrationGrid)/8)));
                
                % Stimulus only appear after 1400 ms. We do not count
                % We do not count saccades that happened more than X ms
                % before the stimulus.
                VelThres(1:Opt.PreStimDur-Opt.PreStimWin) = 0;
                
                VelThres(Opt.PreStimDur+Opt.StimDur+Opt.PostStimWin:end) = 0;
                
                if sum(VelThres)==0
                    EyeData.Saccades(iMarker,1) = 0;
                    iSaccs = VelThres;
                else
                    
                    % Saccade duration must be more than a threshold
                    OnAndOff = diff(VelThres);
                    
                    ON = find(OnAndOff==1)';
                    OFF = find(OnAndOff==-1)';
                    
                    if any(size(ON)~=size(OFF))
                        if size(ON,1)<size(OFF,1)
                            ON = [1 ; ON]; %#ok<*AGROW>
                        end
                        if size(OFF,1)<size(ON,1)
                            OFF = [OFF ; numel(VelThres)]; %#ok<*AGROW>
                        end
                    end
                    
                    ActualSacc = diff([ON, OFF],[],2)>Opt.SaccDurThresh;
                    
                    % Saccade radial amplitude must be more than a threshold
                    for i = 1 : numel(ON)
                        RadAmp(i,1) = sqrt( (iPos_x(ON(i))-iPos_x(OFF(i))).^2 + (iPos_y(ON(i))-iPos_y(OFF(i))).^2); %#ok<*SAGROW>
                    end
                    
                    ActualSacc = all([ActualSacc RadAmp>(Opt.SaccRadAmp*range(EyeData.X_CalibrationGrid)/8)],2);
                    
                    
                    for i = 1: numel(ActualSacc)
                        if ActualSacc(i)==0
                            VelThres(ON(i):OFF(i));
                        end
                    end
                    
                    EyeData.Saccades(iMarker,1) = sum(ActualSacc);
                    iSaccs = VelThres;
                    
                    clear ActualSacc RadAmp ON OFF OnAndOff VelThres
                    
                end
                
                %% Label points outside of a 2 degree VA radius circle
                iFix = (iPos_x.^2+iPos_y.^2)>(Opt.FixThres*EyeData.PixPerDegX).^2;
                
                iFix(iSaccs==1) = 0;
                
                EyeData.Fixation(iMarker,1:2) = [sum(iFix) numel(iPos_y)];
                
                
                %%
                EyeData.Trials{iMarker,1} = [...
                    iPos_x;...
                    iPos_y;...
                    iV;...
                    iA;...
                    iSaccs;...
                    iFix];
                
                EyeData.iTime = [EyeData.iTime iTime];
                EyeData.iMarkers = [EyeData.iMarkers 1 zeros(1,size(iTime,2)-1)];
                EyeData.iPos_x = [EyeData.iPos_x iPos_x];
                EyeData.iPos_y = [EyeData.iPos_y iPos_y];
                
                clear iPos_x iPos_y iV iA iSaccs
                
            end
        end
        
        %% Valid trials
        EyeData.InvalidTrials = [EyeData.Saccades , ...
            (EyeData.Fixation(:,1)./EyeData.Fixation(:,2))>Opt.BadFixThres(1)];
        
        
        
        %% Overview cleaned trials
        figure('name', ['Overview cleaned trials: ' EyeData.Name], 'position', Opt.FigDim, 'visible', Opt.Visible)
        subplot(5,2,1)
        grid on
        hold on
        plot(EyeData.iTime , EyeData.iPos_x)
        plot(EyeData.iTime(find(EyeData.iMarkers)), EyeData.iPos_x(find(EyeData.iMarkers)),'or')
        
        set(gca, 'ytick', -100:50:100, 'yticklabel', -4:2:4,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        ylabel('X Position');
        xlabel('Time');
        
        Ax = axis;
        axis([Ax(1) Ax(2) -100 100])
        
        subplot(5,2,2)
        grid on
        hold on
        plot(EyeData.iTime, EyeData.iPos_y)
        plot(EyeData.iTime(find(EyeData.iMarkers)), EyeData.iPos_y(find(EyeData.iMarkers)),'or')
        
        set(gca, 'ytick', -100:50:100, 'yticklabel', -4:2:4,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        ylabel('Y Position');
        xlabel('Time');
        
        Ax = axis;
        axis([Ax(1) Ax(2) -100 100])
        
        MIN = 1900;
        
        for iTrial = 1:size(EyeData.Trials,1)
            if ~isempty(EyeData.Trials{iTrial,1})
                
                MIN = min([MIN numel(EyeData.Trials{iTrial,1}(1,:))]);
                
                subplot(5,2,3:4)
                hold on
                plot(EyeData.Trials{iTrial,1}(1,:),'color', [0.4 0.4 1])
                if sum(EyeData.Saccades(iTrial,1)>0)
                    plot(find(EyeData.Trials{iTrial,1}(5,:)==1), ...
                        EyeData.Trials{iTrial,1}(1,find(EyeData.Trials{iTrial,1}(5,:)==1)),'.r', ...
                        'MarkerFaceColor', [1 0 0])
                end
                
                subplot(5,2,5:6)
                hold on
                plot(EyeData.Trials{iTrial,1}(2,:),'color', [0.4 0.4 1])
                if sum(EyeData.Saccades(iTrial,1)>0)
                    plot(find(EyeData.Trials{iTrial,1}(5,:)==1), ...
                        EyeData.Trials{iTrial,1}(2,find(EyeData.Trials{iTrial,1}(5,:)==1)),'.r', ...
                        'MarkerFaceColor', [1 0 0])
                end
                
                subplot(5,2,7:8)
                hold on
                plot(EyeData.Trials{iTrial,1}(3,:),'color', [0.4 1 0.4])
                if sum(EyeData.Saccades(iTrial,1)>0)
                    plot(find(EyeData.Trials{iTrial,1}(5,:)==1), ...
                        EyeData.Trials{iTrial,1}(3,find(EyeData.Trials{iTrial,1}(5,:)==1)),'.r', ...
                        'MarkerFaceColor', [1 0 0])
                end
                
                subplot(5,2,9:10)
                hold on
                plot(EyeData.Trials{iTrial,1}(4,:),'color', [1 0.4 .4])
                
                
            end
        end
        
        subplot(5,2,3:4)
        set(gca, 'ytick', -100:50:100, 'yticklabel', -4:2:4,...
            'xtick', 0:100:2500, 'xticklabel', 0:100:2500,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        axis([Opt.PreStimDur-Opt.PreStimWin MIN -100 100])
        plot([Opt.PreStimDur Opt.PreStimDur], [-100 100], 'k')
        ylabel('X Position');
        
        
        subplot(5,2,5:6)
        set(gca, 'ytick', -100:50:100, 'yticklabel', -4:2:4,...
            'xtick', 0:100:2500, 'xticklabel', 0:100:2500,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        axis([Opt.PreStimDur-Opt.PreStimWin MIN -100 100])
        plot([Opt.PreStimDur Opt.PreStimDur], [-100 100], 'k')
        ylabel('Y Position');
        
        
        subplot(5,2,7:8)
        plot([0 MIN], [Opt.SaccVelThresh*(range(EyeData.X_CalibrationGrid)/8) ...
            Opt.SaccVelThresh*(range(EyeData.X_CalibrationGrid)/8)], '--k')
        Ax = axis;
        axis([Opt.PreStimDur-Opt.PreStimWin MIN Ax(3) Ax(4)])
        plot([Opt.PreStimDur Opt.PreStimDur], [Ax(3) Ax(4)], 'k')
        set(gca, 'xtick', 0:100:2500, 'xticklabel', 0:100:2500,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        ylabel('Velocity');
        
        subplot(5,2,9:10)
        Ax = axis;
        axis([Opt.PreStimDur-Opt.PreStimWin MIN Ax(3) Ax(4)])
        plot([Opt.PreStimDur Opt.PreStimDur], [Ax(3) Ax(4)], 'k')
        set(gca, 'xtick', 0:100:2500, 'xticklabel', 0:100:2500,...
            'tickdir', 'out', 'ticklength', [0.01 0.01], 'fontsize', 8);
        ylabel('Acceleration');
        xlabel('Time');
        
        
        if Opt.Print
            print(gcf, fullfile(FigDir, ['OverviewCleanedTrials_' EyeData.Name '.tif']), '-dtiff')
        end
        
        
        %%
        set(0,'units','pixels')
        Pix_SS = get(0,'screensize');
        
        figure('name', ['Trials ' EyeData.Name], 'Color', [1 1 1], 'position', ...
            [Pix_SS(1)+50 Pix_SS(2)+50 Pix_SS(3)-150 Pix_SS(4)-150], 'visible', Opt.Visible)
        
        Happy = imread(fullfile(StartDirectory,'Happy.jpg'));
        Neutral = imread(fullfile(StartDirectory,'Neutral.jpg'));
        Bad = imread(fullfile(StartDirectory,'Sad.jpg'));
        
        Green = [81 176 50]/255;
        Yellow = [255 238 0]/255;
        Red = [230 40 40]/255;
        
        
        subplot(131)
        hold on
        
        X = [];
        Y = [];
        PDF = [];
        Remove = [];
        
        rectangle('Position', [0-Opt.FixThres*EyeData.PixPerDegX 0-Opt.FixThres*EyeData.PixPerDegX ...
            2*Opt.FixThres*EyeData.PixPerDegX 2*Opt.FixThres*EyeData.PixPerDegX], 'Curvature', [1 1])
        
        for iTrial = 1:size(EyeData.Trials,1)
            
            if ~isempty(EyeData.Trials{iTrial,1})
                
                plot(EyeData.Trials{iTrial,1}(1,Opt.PreStimDur-Opt.PreStimWin:MIN),...
                    EyeData.Trials{iTrial,1}(2,Opt.PreStimDur-Opt.PreStimWin:MIN), 'color', [.4 .4 .4])
                
                if sum(EyeData.Fixation(iTrial,1)>0)
                    ToPlot = Opt.PreStimDur-Opt.PreStimWin:MIN;
                    id = find(EyeData.Trials{iTrial,1}(6,:));
                    id = intersect(id,ToPlot);
                    plot(EyeData.Trials{iTrial,1}(1,id), EyeData.Trials{iTrial,1}(2,id),'.b', ...
                        'MarkerFaceColor', [0 0 1])
                end
                
                if sum(EyeData.Saccades(iTrial,1)>0)
                    plot(EyeData.Trials{iTrial,1}(1,find(EyeData.Trials{iTrial,1}(5,:)==1)), ...
                        EyeData.Trials{iTrial,1}(2,find(EyeData.Trials{iTrial,1}(5,:)==1)),'.m', ...
                        'MarkerFaceColor', [1 0 0])
                end
                
                X = [X EyeData.Trials{iTrial,1}(1,Opt.PreStimDur-Opt.PreStimWin:MIN)];
                Y = [Y EyeData.Trials{iTrial,1}(2,Opt.PreStimDur-Opt.PreStimWin:MIN)];
                
            end
        end
        
        %         Remove = any([...
        %             X<floor(EyeData.X_CalibrationGrid(1));...
        %             Y<floor(EyeData.Y_CalibrationGrid(1))],1);
        %
        %         X(Remove) = [];
        %         Y(Remove) = [];
        %
        %         PDF = accumarray([1+round(X+abs(EyeData.X_CalibrationGrid(1)))' ...
        %             1+round(Y+abs(EyeData.Y_CalibrationGrid(1)))'], 1, ...
        %             round([range(EyeData.X_CalibrationGrid) range(EyeData.Y_CalibrationGrid)]));
        %
        %         PDF=PDF/max(PDF(:));
        %
        %         A=colormap('hot');
        %         A(1,:) = [1 1 1];
        %         colormap(A);
        %
        %         imagesc(PDF');
        
        
        %         [n,c] = hist3([round(X+abs(EyeData.X_CalibrationGrid(1)))' ...
        %             round(Y+abs(EyeData.Y_CalibrationGrid(1)))'], ...
        %             [10 10]) ;
        %         contour(c{1},c{2},n);
        
        
        %         for i=1:size(EyeData.X_CalibrationGrid,2)
        %             plot([(EyeData.FarLeft+i-1)*EyeData.Delta_X (EyeData.FarLeft+i-1)*EyeData.Delta_X], ...
        %                 [EyeData.Bottom*EyeData.Delta_Y -1*EyeData.Bottom*EyeData.Delta_Y], '-k', 'linewidth', 2)
        %         end
        %
        %         for i=1:size(EyeData.Y_CalibrationGrid,1)
        %             plot([EyeData.FarLeft*EyeData.Delta_X -1*EyeData.FarLeft*EyeData.Delta_X], ...
        %                 [(EyeData.Bottom+i-1)*EyeData.Delta_Y (EyeData.Bottom+i-1)*EyeData.Delta_Y], '-k', 'linewidth', 2)
        %         end
        
        %         scatter(round(X+abs(EyeData.X_CalibrationGrid(1))), ...
        %             round(Y+abs(EyeData.Y_CalibrationGrid(1))),'.');
        
        
        %         axis([0 EyeData.X_CalibrationGrid(end)+abs(EyeData.X_CalibrationGrid(1)) ...
        %             0 EyeData.Y_CalibrationGrid(end)+abs(EyeData.Y_CalibrationGrid(1))])
        %
        %         set(gca, 'ytick', (0:numel(EyeData.Y_CalibrationGrid))*EyeData.Delta_Y, 'yticklabel', -8:8:8, ...
        %             'xtick', (0:numel(EyeData.X_CalibrationGrid))*EyeData.Delta_X, 'xticklabel', -8:4:8)
        
        
        
        set(gca, 'ytick', EyeData.Y_CalibrationGrid, 'yticklabel', -8:8:8, ...
            'xtick', EyeData.X_CalibrationGrid, 'xticklabel', -8:4:8, ...
            'FontSize', 16);
        
        axis([min(EyeData.X_CalibrationGrid)-20 max(EyeData.X_CalibrationGrid)+20 ...
            min(EyeData.Y_CalibrationGrid)-20 max(EyeData.Y_CalibrationGrid)+20])
        
        axis square
        grid on
        
        BadFixation = mean(EyeData.Fixation(~isnan(EyeData.Fixation(:,1)),1)./...
            EyeData.Fixation(~isnan(EyeData.Fixation(:,1)),2));
        
        t=text(EyeData.PixPerDegX*-8, EyeData.PixPerDegX*9, ...
            sprintf('Percent data > %1.1f deg VA from fixation = %.2f', ...
            Opt.FixThres,100*BadFixation));
        set(t, 'fontsize', 11)
        
        
        subplot(132)
        hold on
        
        ToPlot = [...
            sum(EyeData.InvalidTrials(:,1)>0), ...
            sum(EyeData.InvalidTrials(:,2)>0)];
        ToPlot(end+1) = sum(~isnan(EyeData.InvalidTrials(:,1)))-sum(ToPlot);
        ToPlot = repmat(ToPlot,[2 1]);
        
        bar1 = bar(1:2, ToPlot, 'stacked');
        
        set(bar1(1),'FaceColor',[1 0 1],'EdgeColor',[1 1 1]);
        set(bar1(2),'FaceColor',[0 0 1],'EdgeColor',[1 1 1]);
        set(bar1(3),'FaceColor',[.4 .4 .4],'EdgeColor',[1 1 1]);
        
        plot([.5 1.5], [Opt.BadTrialsThres(1)*sum(ToPlot(1,:)) Opt.BadTrialsThres(1)*sum(ToPlot(1,:))], ...
            ':', 'color', Red,'linewidth', 4)
        plot([.5 1.5], [Opt.BadTrialsThres(2)*sum(ToPlot(1,:)) Opt.BadTrialsThres(2)*sum(ToPlot(1,:))], ...
            ':', 'color', Yellow,'linewidth', 4)
        
        set(gca,'XTick',1,'XTickLabel','',...
            'YTick',linspace(0,sum(ToPlot(1,:)),11), ...
            'YTickLabel',round(linspace(0,sum(ToPlot(1,:)),11)), ...
            'FontSize', 16);
        ylabel('Nb Trials')
        axis([.5 1.5 0 sum(ToPlot(1,:))])
        axis square
        
        BadTrials=sum(any(EyeData.InvalidTrials ,2))/sum(~isnan(EyeData.Saccades));
        t=text(0.5, sum(ToPlot(1,:)+3), ...
            sprintf(' %.2f percent invalid trials out of %i \n trials with enough data points.', ...
            BadTrials, sum(ToPlot(1,:))));
        set(t, 'fontsize', 12)
        

        subplot(133)
        hold on

        if BadTrials>Opt.BadTrialsThres(1)
            image(Bad)
        elseif BadTrials>Opt.BadTrialsThres(2)
            image(Neutral)
        else
            image(Happy)
        end
        axis('off')
        axis(gca,'tight');
        axis(gca,'ij');
        set(gca,'DataAspectRatio',[1 1 1]);
        
        if Opt.Print
            print(gcf, fullfile(FigDir, ['Trials_' EyeData.Name '.tif']), '-dtiff')
        end
        
        %%
        clear EyeData
        
    end
    
end
