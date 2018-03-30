classdef ExpCatheterDeconvolution < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
	%% CATHETERDECONVOLUTION   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
 	 
    properties 
        xLabel = 'time/s'
        yLabel = 'counts'
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
            ncnt0 = max(this.dependentData)/max(this.response);
            eps0 = 1e-6;
            map = containers.Map;
            map('alpha')  = struct('fixed', 0, 'min', eps0,    'mean',  0.45, 'max',   5);
            map('beta')   = struct('fixed', 0, 'min',    0.01, 'mean',  0.23, 'max',  10);
            map('c1')     = struct('fixed', 0, 'min', -100,    'mean',  0,    'max', 100);
            map('c2')     = struct('fixed', 0, 'min', -100,    'mean',  0,    'max', 100);
            map('c3')     = struct('fixed', 0, 'min', -100,    'mean',  0,    'max', 100);
            map('c4')     = struct('fixed', 0, 'min', -100,    'mean',  0,    'max', 100);
            map('delta')  = struct('fixed', 1, 'min', eps0,    'mean',  0.03, 'max',   1);
            map('fracSS') = struct('fixed', 0, 'min', eps0,    'mean',  0.08, 'max',   0.2);
            map('gamma')  = struct('fixed', 0, 'min',    1,    'mean', 16,    'max',  50);
            map('ncnt')   = struct('fixed', 0, 'min', ncnt0,   'mean',  1.5*ncnt0, 'max', 20*ncnt0);
            map('t0')     = struct('fixed', 0, 'min',    1,    'mean',  7.9,  'max',  35); 
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
                this.finalParams('alpha'),  this.finalParams('beta'), ...
                this.finalParams('c1'),     this.finalParams('c2'),    this.finalParams('c3'),   this.finalParams('c4'), this.finalParams('delta'), ...
                this.finalParams('fracSS'), this.finalParams('gamma'), this.finalParams('ncnt'), this.finalParams('t0'));
        end
        function dcv   = estimateDcv(this)
            dcv = this.estimateDcvFast( ...
                this.finalParams('alpha'),  this.finalParams('beta'), ...
                this.finalParams('c1'),     this.finalParams('c2'),    this.finalParams('c3'),   this.finalParams('c4'), this.finalParams('delta'), ...
                this.finalParams('fracSS'), this.finalParams('gamma'), this.finalParams('ncnt'), this.finalParams('t0'));
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
        
  		function this  = ExpCatheterDeconvolution(varargin)
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
        function dccrv = estimateDccrvFast(this, alpha_, beta_, c1, c2, c3, c4, delta_, fracSS, gamma_, ncnt, t0)
            dccrv = conv(this.estimateDcvFast(alpha_, beta_, c1, c2, c3, c4, delta_, fracSS, gamma_, ncnt, t0), this.response);
            dccrv = this.ensureDccrvLength(dccrv);
        end
        function dcv   = estimateDcvFast(  this, alpha_, beta_, c1, c2, c3, c4, delta_, fracSS, gamma_, ncnt, t0)
            bp1 = this.gammaVariatePolyFast(alpha_, beta_, c1, c2, c3, c4, t0);
            c   = (1 - fracSS) * bp1;
            css =      fracSS  * max(c) * this.bolusSteadyStateFast(gamma_, t0);
            dcv = ncnt * (c + css);
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

