classdef LegacyCatheterAnalysis < mlarbelaez.AbstractCatheterAnalysis 
	%% LEGACYCATHETERANALYSIS is designed for legacy, calibrated catheters used with blood-sucker devices in the Barnes NNICU.
    %  Bayesian parameter estimation is used preferentially.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	 

    properties (Constant)
        DCV_START   = 15;
        DCV_END     = 115;
        DCCRV_START = 20;
        DCCRV_END   = 120;
    end
    
    properties
        pwdSrc = '/Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez'
        pwdAmaTests = '/Volumes/PassportStudio2/Arbelaez/deconvolution/data 2014jul17'
        pwdLegacyPET = '/Volumes/PassportStudio2/cvl/np755/mm01-021_p7413_2009apr24/ECAT_EXACT/pet' %% mild disease
        modeledResponseMat = 'modeledResponse.mat';
        responseMat = 'response.mat';
    end
    
	methods
        function [dcv, modeledResponse]      = modelResponseByBayes(this)
            %% MODELRESPONSEBYBAYES
            %  Usage:  [response, CatheterResponse_object] = this.modelResponseByBayes;
            
            import mlarbelaez.* mlpet.*;
            cd(this.pwdLegacyPET);
            cr = mlarbelaez.LegacyCatheterResponse( ...
                DCV('p7413ho1'), ...
                DecayCorrectedCRV(CRV('p7413ho1')));
            modeledResponse = cr.estimateParameters;
            dcv = modeledResponse.estimateData;
            save('modeledResponse.mat', 'modeledResponse');
            fprintf('modeledResponse saved to %s/%s\n', pwd, this.modeledResponseMat);
        end
        function [r, modeledResponses]       = modelBetadcvByBayes(this)
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
        function [dccrv, dcv, modeledDeconv] = modelDeconvByBayes(this, varargin)
            
            p = inputParser;
            addRequired(p, 'fileprefix',    @ischar);
            addOptional(p, 'pathname', pwd, @isdir);
            parse(p, varargin{:});
            
            import mlarbelaez.* mlpet.*;
            dccrv0 = DecayCorrectedCRV( ...
                     CRV(p.Results.fileprefix, p.Results.pathname));
            assert(lexist(fullfile(this.pwdSrc, this.modeledResponseMat)));
            load(         fullfile(this.pwdSrc, this.modeledResponseMat));            
            cathd         = CatheterDeconvolution(dccrv0, modeledResponse.estimateData); 
            modeledDeconv = cathd.estimateParameters;
            
            dccrv         = dccrv0;
            dccrv.fileprefix = sprintf('%s_bayes', dccrv0.fileprefix);
            dccrv.counts  = modeledDeconv.estimateDccrv;
            
            dcv           = DCV(p.Results.fileprefix);
            dcv.fileprefix   = sprintf('%s_bayes', dcv.fileprefix);
            counts        = dcv.counts;
            counts2       = modeledDeconv.estimateDcv;
            counts(1:modeledDeconv.length-4) = counts2(1:modeledDeconv.length-4);
            dcv.counts    = counts;
            dcv.save;
        end 
        function [dccrv, dcv, modeledDeconv] = modelBetadcvDeconvByBayes(this, varargin)
            
            p = inputParser;
            addRequired(p, 'fileprefix',    @ischar);
            addOptional(p, 'pathname', pwd, @isdir);
            parse(p, varargin{:});
            
            import mlarbelaez.* mlpet.*;
            dccrv0 = DecayCorrectedCRV( ...
                     CRV(p.Results.fileprefix, p.Results.pathname));
            assert(lexist(fullfile(this.pwdAmaTests, 'ecr7.mat')));
            load(         fullfile(this.pwdAmaTests, 'ecr7.mat'));            
            cathd         = BetadcvCatheterDeconvolution(dccrv0, ecr7.estimateExpBetadcv); 
            modeledDeconv = cathd.estimateParameters;
            
            dccrv         = dccrv0;
            dccrv.fileprefix = sprintf('%s_bayes', dccrv0.fileprefix);
            dccrv.counts  = modeledDeconv.estimateDccrv;
            
            dcv           = DCV(p.Results.fileprefix);
            dcv.fileprefix   = sprintf('%s_bayes', dcv.fileprefix);
            counts        = dcv.counts;
            counts2       = modeledDeconv.estimateDcv;
            counts(1:modeledDeconv.length-4) = counts2(1:modeledDeconv.length-4);
            dcv.counts    = counts;
            dcv.save;
        end   
        function response                    = estimateResponseByFFT(this)
            
            import mlarbelaez.* mlpet.*;            
            cd(this.pwdLegacyPET);
            
            dcv   = DCV('p7413ho1');
            dccrv = DecayCorrectedCRV(CRV('p7413ho1'));
            response = this.responseByFFT( ...
                       dccrv.counts(this.DCCRV_START:this.DCCRV_END), dcv.counts(this.DCV_START:this.DCV_END));
            save(   'response.mat', 'response');
            fprintf('response saved to %s/%s\n', pwd, this.responseMat);
        end
        function [response, fR]              = testResponseByFFT(this)
            
            time      = 0:99;
            tau       = 10;
            response0 = exp(-time/tau);
            [time,response0] = shiftVector(time, response0, 10);
            f         = exp(-time.^2/(2*tau^2)); 
            fR        = conv(f, response0); fR = fR(1:100);
            response  = this.responseByFFT(fR, f);
        end
        function step = testStepRecovery(this)
            
            time      = 0:99;
            tau       = 30;
            response0 = exp(-(time-tau)/tau); 
            response0 = response0/sum(response0);
            step0     = ones(1,100); step0(1) = 0; step0(2) = 0.5;
            stepR     = conv(step0, response0); stepR = stepR(1:100); 
            stepR     = stepR + 0.05*rand(size(stepR));
            step      = this.deconvByFFT(stepR, response0);
            plot(step);
        end
        function response                    = responseByFFT(this, fR, f)
            
            BUF = 2^18;
            fR  = smooth(this.ensureRowVector(fR));
            f   = smooth(this.ensureRowVector(f));
            len = max(length(fR), length(f));
            response   = ifft(fft(fR, BUF) ./ fft(f, BUF));
            response   = response(1:len);
            if (any(isnan(response)))
                error('mlarbelaez:NaN', 'CatheterAnalysis.estimateResidueByDiff.R had NaNs; check fft(g)');
            end
        end
        function f                           = deconvByFFT(this, fR, R)
            
            fR  = this.ensureRowVector(fR);
            R   = this.ensureRowVector(R);
            len = max(length(fR), length(R));
            wid = length(fR) + length(R) - 1;
            f   = ifft(fft(fR, wid) ./ fft(R, wid));
            f   = f(1:len);
            if (any(isnan(f)))
                error('mlarbelaez:NaN', 'CatheterAnalysis.estimateResidueByDiff.R had NaNs; check fft(g)');
            end
        end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

