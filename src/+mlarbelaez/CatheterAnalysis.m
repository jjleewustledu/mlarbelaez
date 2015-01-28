classdef CatheterAnalysis < mlarbelaez.AbstractCatheterAnalysis 
	%% CATHETERANALYSIS is designed for catheters used with blood-sucker devices in the Barnes NNICU.
    %  Bayesian parameter estimation is used preferentially.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
    
    properties (Constant)
        pwdSrc = '/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez'
        pwdAmaTests = '/Volumes/PassportStudio2/Arbelaez/deconvolution/data 2014jul17'
        timeInterpolants = 0:119;
    end
    
	methods (Static)
        function data  = modelGluTByBayes
            assertFolder('GluT');
            dt = mlfourd.DirTool('p*_JJL');
            hctsScan1 = [36 39 33 34.2 39.6 37.6 36   38.5 35.7 33.2 34.5 36.1 36.9 42.1 35.7 40.2 38.6 43.8];
            hctsScan2 = [34 36 30 35.8 40.5 37.4 34.5 40.7 36   35   36.3 37.1 36.6 42.6 34.8 42.1 37.8 43.4];
            assert(length(hctsScan1) == dt.length);
            assert(length(hctsScan2) == dt.length);            
            data = cell(1,dt.length);
            
            import mlarbelaez.*;
            dns = dt.dns;
            fqdns = dt.fqdns;
            parfor d = 1:dt.length
                data{d} = struct('scan1', [], 'scan2', []);
                try
                    fprintf('CatheterAnalysis.modelGluTByBayes:  running %sho1.....\n', dns{d});
                    data{d}.scan1 = CatheterAnalysis.modelDeconvByBayes( ...
                        hctsScan1(d), ...
                        CatheterAnalysis.getStudyId(dns{d}, 'ho1'), ...
                        fullfile(fqdns{d}, 'PET/scan1', ''));
                catch ME
                    handwarning(ME);
                end
                try
                    fprintf('CatheterAnalysis.modelGluTByBayes:  running %sho2.....\n', dns{d});
                    data{d}.scan2 = CatheterAnalysis.modelDeconvByBayes( ...
                        hctsScan2(d), ...
                        CatheterAnalysis.getStudyId(dns{d}, 'ho2'), ...
                        fullfile(fqdns{d}, 'PET/scan2', ''));
                catch ME
                    handwarning(ME);
                end
            end     
            matFilename = sprintf('CatheterAnalysis.modelGluTByBayes.data%s.mat', appendDatestr(''));
            fprintf('CatheterAnalysis.modelGluTByBayes:  saving data to %s\n', matFilename);
            save(matFilename, 'data');
        end
        
        function data  = recoverHeavisides
            assertFolder('data 2014jul17');
            studyIds = {'AMAtest4' 'AMAtest5' 'AMAtest6' 'AMAtest7'};
            hctsScan = [34 38 44 44];
            %doseScan = [41 84 85 85];           
            data = cell(1,length(studyIds));
            
            import mlarbelaez.*;
            parfor d = 1:length(studyIds)
                try
                    fprintf('CatheterAnalysis.recoverHeavisides:  running %s.....\n', studyIds{d});
                    data{d} = CatheterAnalysis.modelDeconvByBayes( ...
                        hctsScan(d), ...
                        studyIds{d});
                catch ME
                    handwarning(ME);
                end
            end     
            matFilename = sprintf('CatheterAnalysis.recoverHeavisides.data%s.mat', appendDatestr(''));
            fprintf('CatheterAnalysis.recoverHeavisides:  saving data to %s\n', matFilename);
            save(matFilename, 'data');
        end
        function cathd = modelDeconvByBayes(varargin)
            %% MODELDECONVBYBAYES creates dcv files by Bayesian deconvolution.
            %  Uses classes CatheterDeconvolution, StretchedExpResponse.
            %  Usage:  object_CatheterDeconvolution = CatheterAnalysis.modelDeconvByBayes(hematocrit, study_id[, directory_name])
            %                                                                             ^ numeric   ^ char     ^ char
             
            p = inputParser;
            addRequired(p, 'Hct',           @isnumeric);
            addRequired(p, 'studyId',       @ischar);
            addOptional(p, 'pathname', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});
            
            import mlarbelaez.*;
            pwd0 = pwd;
            cd(p.Results.pathname);
            assert(lexist([p.Results.studyId '.crv']));
            dccrv = DecayCorrectedCRV( ...
                    CRV(p.Results.studyId));
            assert(lexist([p.Results.studyId '.dcv']));
            dcv = DCV(p.Results.studyId);
            system(sprintf('mv -f %s.dcv %s.dcv.bak', p.Results.studyId, p.Results.studyId));                 
            response = StretchedExpResponse.empiricalResponse(p.Results.Hct, CatheterAnalysis.timeInterpolants);
                 
            cathd = CatheterDeconvolution(dccrv, response); 
            cathd = cathd.estimateParameters;
            
            counts = cathd.estimateDcv;
            dcv.counts(1:length(counts)) = counts;
            dcv.save;
            cd(pwd0);
        end 
    end
    
    methods
        function [r, modeledResponses] = modelBetadcvByBayes(this)
            %% MODELEXPRESPONSESBYBAYES
            %  Usage:  [cell_responses, cell_ExpCatheterResponse_objects] = this.modelExpResponsesByBayes;
            
            amatests         = cell(7,1);
            modeledResponses = cell(7,1);
            r                = cell(7,1);
            
            pwd0 = pwd;
            cd(this.pwdAmaTests);
            import mlarbelaez.*;
            for t = 4:7
                amatests{t} = CRV(sprintf('AMAtest%i', t));
                bcr = BetadcvCatheterResponse(amatests{t});
                modeledResponses{t} = bcr.estimateParameters;
                r{t} = modeledResponses{t}.estimateData;
            end
            save('modelBetadcvByBayes.mat');
            fprintf('workspace within CatheterAnalysis.modelBetadcvByBayes saved to %s/modelBetadcvByBayes.mat\n', pwd);
            cd(pwd0);
        end
        function [dccrv, dcv, modeledDeconv] = modelBetadcvDeconvByBayes(this, varargin)
            
            p = inputParser;
            addRequired(p, 'studyId',       @ischar);
            addOptional(p, 'pathname', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:});
            
            import mlarbelaez.*;
            dccrv0 = DecayCorrectedCRV( ...
                     CRV(p.Results.studyId, p.Results.pathname));
            assert(lexist(fullfile(this.pwdAmaTests, 'ecr7.mat')));
            load(         fullfile(this.pwdAmaTests, 'ecr7.mat'));            
            cathd         = BetadcvCatheterDeconvolution(dccrv0, ecr7.estimateExpBetadcv); 
            modeledDeconv = cathd.estimateParameters;
            
            dccrv         = dccrv0;
            dccrv.studyId = sprintf('%s_bayes', dccrv0.studyId);
            dccrv.counts  = modeledDeconv.estimateDccrv;
            
            dcv           = DCV(p.Results.studyId);
            dcv.studyId   = sprintf('%s_bayes', dcv.studyId);
            counts        = dcv.counts;
            counts2       = modeledDeconv.estimateDcv;
            counts(1:modeledDeconv.length-4) = counts2(1:modeledDeconv.length-4);
            dcv.counts    = counts;
            dcv.save;
        end   
        function f = deconvByFFT(this, fR, R)
            %% DECONVBYFFT
            
            fR  = this.ensureRowVector(fR)/max(fR);
            R   = this.ensureRowVector(R)/max(R);
            len = max(length(fR), length(R));
            f   = ifft(fft(fR, 2*len) ./ fft(R, 2*len));
            f   = f(1:len);
            if (any(isnan(f)))
                error('mlarbelaez:NaN', 'CatheterAnalysis.estimateResidueByDiff.R had NaNs; check fft(g)');
            end
        end
    end 
    
    methods (Static, Access = 'private')
        function sid = getStudyId(folder, suffix)
            sid = [folder(1:5) suffix];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

