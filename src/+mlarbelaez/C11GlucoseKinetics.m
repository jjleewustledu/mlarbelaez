classdef C11GlucoseKinetics < mlkinetics.AbstractC11GlucoseKinetics
	%% C11GLUCOSEKINETICS  

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:07 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

    methods (Static)
        function createDcv
        end
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
            
            studyDat.saveWorkspace;
            t2 = toc(t0);
            studyDat.diaryOff;
        end
        function [dt, ks,kmps] = regionalKinetics4(varargin)
            
            regions = {'amygdala' 'hippocampus' 'hypothalamus' 'large-hypothalamus' 'thalamus'};
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @isdir);
            parse(p, varargin{:}); 
            
            import mlarbelaez.*;
            pwd0 = pwd;            
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            
            cd(subjectsPth);
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2,length(regions));
            kmps = cell(length(dt.dns),2,length(regions));
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.log', datestr(now, 30)));
            diary(logFn);
            for d = 11:11 % 1:length(dt.dns)
                for s = 1:2
                    for r = 1:length(regions)
                        try
                            pth = fullfile(subjectsPth, dt.dns{d}, '');
                            cd(pth);
                            fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                            fprintf('GlutWorker.regionalKinetics4:  working in %s, region %s\n', pth, regions{r});
                            [ks{d,s,r},kmps{d,s,r}] = Kinetics4McmcProblem.runRegion( ...
                                                      pth, s, sprintf('%s_on_gluc%i', regions{r}, s));
                        catch ME
                            handwarning(ME)
                        end
                    end
                end                
            end
            cd(subjectsPth);
            save(sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.mat', datestr(now,30)));
            cd(p.Results.figFolder);
            save(sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.mat', datestr(now,30)));
            mlpet.AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
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

