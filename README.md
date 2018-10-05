# AVT_eye_tracker

Analysis code for the eyetracking data for the participant screnning of the AVT study at 7T. 

`AnalyzeCalibData.m` will only analyze the calibration part of a run. 

`FeedbackTobiiEyeX_AVT_fMRI.m` will only analyze the calibration and the trial part of a run and will both plot results and provide feedback. Can loop through subjects and runs.

Both call the `SubFun\TobiiEyeXTrackCalib.m` function to analyze the calibration data.

A data sample can be found in the `Subjects_Data` folder.