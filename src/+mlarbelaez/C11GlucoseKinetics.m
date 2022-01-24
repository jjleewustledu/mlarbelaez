classdef C11GlucoseKinetics < mlkinetics.AbstractC11GlucoseKinetics
	%% C11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function [output,t2] = loopRegionsLocally
            studyDat = mlpipeline.StudyDataSingleton.instance('arbelaez:GluT');            
            t0 = tic;
            studyDat.diaryOn;
            sessPths = studyDat.sessionPaths;
            regions = studyDat.regionNames;            
            output = cell(length(sessPths), length(studyDat.numberOfScans), length(regions));
            
            for p = 1:length(sessPths)
                for s = 1:length(studyDat.numberOfScans)
                    for r = 1:length(regions)
                        try
                            t1 = tic;
                            fprintf('%s:  is working with %s scanIndex %i region %s\n', mfilename, sessPths{d}, s, regions{r});
                            rm = RegionalMeasurements(fullfile(sDir, sessPths{d}, ''), s, regions{r});
                            [v,rm] = rm.vFrac;
                            [f,rm] = rm.fFrac;
                            k = rm.kinetics4; 
                            k = k.parameters;
                            output{d,s,r} = struct('v', v, 'f', f, 'k4parameters', k);
                            fprintf('Elapsed time:  %g seconds\n\n\n\n', toc(t1));
                        catch ME
                            handwarning(ME);
                        end
                    end
                end
            end
            
            t2 = toc(t0);
            studyDat.diaryOff;
        end
 	end 

	methods 
		  
 		function this = C11GlucoseKinetics(varargin)
 			%% C11GLUCOSEKINETICS
 			%  Usage:  this = C11GlucoseKinetics()

 			this = this@mlkinetics.AbstractC11GlucoseKinetics(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

