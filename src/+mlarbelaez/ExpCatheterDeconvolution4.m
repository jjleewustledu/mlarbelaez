classdef ExpCatheterDeconvolution4 < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
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
        fileprefix
        response
    end
    
    properties (Dependent)
        baseTitle
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            bt = sprintf('%s DCCRV', this.fileprefix);
        end
    end
	
	methods 
        function this  = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters;
            
            import mlbayesian.*;
            ncnt0 = max(this.dependentData);
            eps0 = 1e-6;
            map = containers.Map;
            map('alpha')  = struct('fixed', 0, 'min',   -1, 'mean',  4,    'max', 10);
            map('alpha2') = struct('fixed', 0, 'min',   -1, 'mean',  4,    'max', 10);
            map('beta')   = struct('fixed', 0, 'min', eps0, 'mean',  4,    'max', 10);
            map('beta2')  = struct('fixed', 0, 'min', eps0, 'mean',  4,    'max', 10);
            map('eps')    = struct('fixed', 0, 'min',    0, 'mean',  0,    'max',  1);
            map('fracSS') = struct('fixed', 0, 'min',    0, 'mean',  0.1,  'max',  0.33);
            map('gamma')  = struct('fixed', 0, 'min',    0, 'mean', 16,    'max', 50);
            map('ncnt')   = struct('fixed', 0, 'min',    0.01*ncnt0, 'mean', ncnt0, 'max', 100*ncnt0);
            map('t0')     = struct('fixed', 0, 'min',    1, 'mean',  8,    'max', 35); 
            map('tau')    = struct('fixed', 0, 'min',    0, 'mean',  0,    'max', 20);
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
                this.finalParams('ncnt'),  this.finalParams('t0'),     this.finalParams('tau'));
        end
        function dcv   = estimateDcv(this)
            dcv = this.estimateDcvFast( ...
                this.finalParams('alpha'), this.finalParams('alpha2'), this.finalParams('beta'), this.finalParams('beta2'), ...
                this.finalParams('eps'),   this.finalParams('fracSS'), this.finalParams('gamma'), ...
                this.finalParams('ncnt'),  this.finalParams('t0'),     this.finalParams('tau'));
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
            legend([this.fileprefix ' DCCRV'], 'catheter response')
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
            legend([this.fileprefix ' DCCRV'], 'Bayesian DCCRV', 'Bayesian DCV')
        end
        
  		function this  = ExpCatheterDeconvolution4(varargin)
 			%% CATHETERDECONVOLUTION 
 			%  Usage:  this = CatheterDeconvolution([dccrv,response]) 
 			
            p = inputParser;
            addRequired(p, 'dccrv',    @(x) isa(x, 'mlpet.DecayCorrectedCRV'));
            addRequired(p, 'response', @isnumeric);
            parse(p, varargin{:});
            
            this.dependentData   = p.Results.dccrv.counts;
            this.fileprefix         = p.Results.dccrv.fileprefix;
            this.independentData = 0:length(this.dependentData)-1;
            this.response        = this.ensureNormalizedResponse(p.Results.response);             
 		end 
    end     
    
    %% PROTECTED
    
    methods (Access = 'protected')        
        function dccrv = estimateDccrvFast(this, a, a2, b, b2, e, fracSS, g, ncnt, t0, tau)
            dccrv = conv(this.estimateDcvFast(   a, a2, b, b2, e, fracSS, g, ncnt, t0, tau), this.response);
            dccrv = this.ensureDccrvLength(dccrv);
        end
        function dcv   = estimateDcvFast(  this, a, a2, b, b2, e, fracSS, g, ncnt, t0, tau)
            gv1 = (1 - fracSS) * (1 - e)  * this.gammaVariateFast(a,  b,  t0);
            gv2 = (1 - fracSS) *      e   * this.gammaVariateFast(a2, b2, t0 + tau);
            ss  =      fracSS                * max(gv1) * this.bolusSteadyStateFast(g, t0);
            dcv = ncnt * (gv1 .* gv2 + ss);
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

