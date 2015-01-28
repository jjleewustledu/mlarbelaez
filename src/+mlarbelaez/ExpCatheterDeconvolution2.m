classdef ExpCatheterDeconvolution2 < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
	%% CATHETERDECONVOLUTION   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
 	 
    properties 
        xLabel    = 'time/s'
        yLabel    = 'counts'
        studyId
        response
    end
    
    properties (Dependent)
        baseTitle
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            bt = sprintf('%s DCCRV', this.studyId);
        end
    end
	
	methods 
        function this  = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters;
            
            import mlbayesian.*;
            ncnt0 = max(this.dependentData)/max(this.response);
            eps0 = 1e-6;
            map = containers.Map;
            map('alpha')  = struct('fixed', 0, 'min', eps0, 'mean',  0.45, 'max',  5);
            map('alpha2') = struct('fixed', 0, 'min', eps0, 'mean',  0.45, 'max',  5);
            map('beta')   = struct('fixed', 0, 'min', eps0, 'mean',  0.23, 'max', 10);
            map('beta2')  = struct('fixed', 0, 'min', eps0, 'mean',  0.23, 'max', 10);
            map('eps')    = struct('fixed', 0, 'min', eps0, 'mean',  0.1,  'max',  0.33);
            map('fracSS') = struct('fixed', 0, 'min', eps0, 'mean',  0.1,  'max',  0.33);
            map('gamma')  = struct('fixed', 0, 'min', eps0, 'mean', 16,    'max', 50);
            map('ncnt')   = struct('fixed', 0, 'min', ncnt0, 'mean', 1.5*ncnt0, 'max', 20*ncnt0);
            map('t0')     = struct('fixed', 0, 'min', 1,    'mean',  7.9,  'max', 35); 
            map('tauRe')  = struct('fixed', 0, 'min', 1,    'mean', 10,    'max', 20);
            this = this.runMcmc(map);
        end            
        function ed    = estimateData(this)
            ed = this.estimateDccrv;
        end
        function ed    = estimateDataFast(this, varargin)
            ed = this.estimateDccrvFast(varargin{:});
        end        
        function dccrv = estimateDccrv(this)
            dccrv = this.estimateDccrvFast( ...
                this.finalParams('alpha'), this.finalParams('alpha2'), this.finalParams('beta'), this.finalParams('beta2'), ...
                this.finalParams('eps'),   this.finalParams('fracSS'), this.finalParams('gamma'), ...
                this.finalParams('ncnt'),  this.finalParams('t0'),     this.finalParams('tauRe'));
        end
        function dcv   = estimateDcv(this)
            dcv = this.estimateDcvFast( ...
                this.finalParams('alpha'), this.finalParams('alpha2'), this.finalParams('beta'), this.finalParams('beta2'), ...
                this.finalParams('eps'),   this.finalParams('fracSS'), this.finalParams('gamma'), ...
                this.finalParams('ncnt'),  this.finalParams('t0'),     this.finalParams('tauRe'));
        end
        function         plotOri(this)
            if (~this.PLOT_ORI)
                return; end
            figure
            plot( ...
                this.timeInterpolants, this.dependentData/max(this.dependentData), 'k', ...
                this.timeInterpolants, this.response/max(this.response),           'k:');
            title(sprintf('%s, large catheter response', this.baseTitle))
            xlabel('time/s')
            ylabel(sprintf('counts rescaled by %f, %f', max(this.dependentData), max(this.response)))
            legend([this.studyId ' DCCRV'], 'catheter response')
        end
        function         plotEstimate(this)
            if (~this.PLOT_ESTIMATE)
                return; end
            figure
            plot(this.timeInterpolants, this.dependentData, 'k', ...
                 this.timeInterpolants, this.estimateDccrv, 'k--', ...
                 this.timeInterpolants, this.estimateDcv,   'k:');
            title(sprintf('%s, Bayesian DCCRV, Bayesian DCV', this.baseTitle))
            xlabel('time/s')
            ylabel('counts')
            legend([this.studyId ' DCCRV'], 'Bayesian DCCRV', 'Bayesian DCV')
        end
        
  		function this  = ExpCatheterDeconvolution2(varargin)
 			%% CATHETERDECONVOLUTION 
 			%  Usage:  this = CatheterDeconvolution([dccrv,response]) 
 			
            p = inputParser;
            addRequired(p, 'dccrv',    @(x) isa(x, 'mlarbelaez.DecayCorrectedCRV'));
            addRequired(p, 'response', @isnumeric);
            parse(p, varargin{:});
            
            this.dependentData   = p.Results.dccrv.counts;
            this.studyId         = p.Results.dccrv.studyId;
            this.independentData = 0:length(this.dependentData)-1;
            this.response        = this.ensureNormalizedResponse(p.Results.response);             
 		end 
    end     
    
    %% PROTECTED
    
    methods (Access = 'protected')        
        function dccrv = estimateDccrvFast(this, alpha_, alpha2_, beta_, beta2_, eps_, fracSS, gamma_, ncnt, t0, tauRe)
            dccrv = conv(this.estimateDcvFast(alpha_, alpha2_, beta_, beta2_, eps_, fracSS, gamma_, ncnt, t0, tauRe), this.response);
            dccrv = this.ensureDccrvLength(dccrv);
        end
        function dcv   = estimateDcvFast(  this, alpha_, alpha2_, beta_, beta2_, eps_, fracSS, gamma_, ncnt, t0, tauRe)
            bp1 = this.gammaVariateFast(alpha_, beta_, t0);
            bp2 = this.gammaVariateFast(alpha2_, beta2_, t0 + tauRe);
            c1  = (1 - fracSS) * (1 - eps_)  * bp1;
            c2  = (1 - fracSS) * eps_ * bp2;
            css =      fracSS  * max(c1) * this.bolusSteadyStateFast(gamma_, t0);
            dcv = ncnt * (c1 + c2 + css);
            dcv = this.ensureRowVector(dcv);
        end        
    end
    
    %% PRIVATE
    
    methods (Access = 'private')
        function n = ensureNormalizedResponse(~, n)
            assert(isnumeric(n));
            n = n/sum(n);
        end
        function x = ensureDccrvLength(this, x)
            x = this.ensureRowVector(x);
            L = length(this.timeInterpolants);
            if (length(x) < L)
                tmp = zeros(1, L);
                tmp(1:L)     = x;
                tmp(L+1:end) = x(end);
                x              = tmp;
            elseif (length(x) > L)
                x = x(1:L);
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

