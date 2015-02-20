classdef ExpCatheterResponse < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
	%% CATHETERRESPONSE   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 

    properties 
        baseTitle = 'Catheter response from AMAtests5-7'
        xLabel    = 'time/s'
        yLabel    = 'counts'
    end
    
	methods 
        function this  = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            eps0 = 1e-6;
            ncnt0 = max(this.dependentData)*length(this.timeInterpolants);
            map = containers.Map;
            map('delta')  = struct('fixed', 0, 'min',  eps0, 'mean',     0.3, 'max',  10);
            map('ncnt')   = struct('fixed', 0, 'min',  eps0,  'mean', ncnt0,   'max', 100*ncnt0);
            map('t0')     = struct('fixed', 0, 'min',    10,  'mean',    15,   'max',  35);              
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
                this.finalParams('delta'), this.finalParams('ncnt'), this.finalParams('t0'));
        end  
        function dccrv = estimateExpBetadcv(this)
            dccrv = this.estimateExpBetadcvFast( ...
                this.finalParams('delta'), this.finalParams('t0'));
        end
        
  		function this  = ExpCatheterResponse(amatest_dccrv)
 			%% CATHETERRESPONSE 
 			%  Usage:  this = CatheterResponse(amatests_decoy_corrected_CRV) 
 			
            assert(isa(amatest_dccrv, 'mlpet.DecayCorrectedCRV'));
            this.dependentData   = this.smoothPeristalsis(amatest_dccrv.counts);  
            this.independentData = 0:length(this.dependentData)-1;
 		end 
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')    
        function dccrv = estimateDccrvFast(this, delta_, ncnt, t0)
            dccrv = conv(this.heavisideInput(ncnt), this.estimateExpBetadcvFast(delta_, t0));
            dccrv = this.ensureDccrvLength(dccrv);
        end        
        function hi = heavisideInput(this, ncnt)
            hi = ncnt * ones(size(this.timeInterpolants));
        end 
        function er = estimateExpBetadcvFast(this, delta_, t0)
            er = this.expFast(delta_, t0);
            er = er / sum(er);
        end         
        function c  = smoothPeristalsis(this, c)
            %% SMOOTHPERISTALSIS attempts to remove fluctuations associated with peristaltic pumps 
            
            c = this.ensureRowVector(smooth(c));
        end
        
        function er = estimateResponse(this)
            er = this.estimateResponseFast( ...
                this.finalParams('alpha'), this.finalParams('beta'), this.finalParams('ncnt'), this.finalParams('t0'));
        end
        function er = estimateResponseFast(   this, alpha_, beta_, ncnt, t0)
            er = ncnt * this.gammaVariateFast(alpha_, beta_, t0);
        end        
        function er = estimateTwoResponse(this)
            er = this.estimateTwoResponseFast( ...
                this.finalParams('alpha'), this.finalParams('alpha2'), ...
                this.finalParams('beta'), this.finalParams('beta2'), ...
                this.finalParams('eps'), ...
                this.finalParams('ncnt'), ...
                this.finalParams('t0'),   this.finalParams('tauRe'));
        end
        function er = estimateTwoResponseFast(this, alpha_, alpha2_, beta_, beta2_, eps_, ncnt, t0, tauRe)
            c1  = (1 - eps_)  * this.gammaVariateFast(alpha_,  beta_,  t0);
            c2  = eps_        * this.gammaVariateFast(alpha2_, beta2_, t0 + tauRe);
            er  = ncnt * (c1 + c2);
        end
        function er = estimateExpResponse(this)
            er = this.estimateExpResponseFast( ...
                 this.finalParams('c1'), ...
                 this.finalParams('c2'), ...
                 this.finalParams('c3'), ...
                 this.finalParams('c4'), ...
                 this.finalParams('delta'), ...
                 this.finalParams('ncnt'), ...
                 this.finalParams('t0'));
        end
        function er = estimateExpResponseFast(this, c1, c2, c3, c4, delta_, ncnt, t0)
            er = ncnt * this.expPolyFast(c1, c2, c3, c4, delta_, t0);
        end
    end
    
    %% PRIVATE
    
    methods (Access = 'private')
        function R  = estimateResponseByDiff(this, counts)
            %% ESTIMATERESPONSEBYDIFF is valid for Heaviside inflow of tracer into a cathether that leads to the blood-sucker detector
            %  f(t)  = [g  * R](t); g is Heaviside
            %  f'(t) = [g' * R](t)
            %  f'(t) = \int ds \delta(s) R(t - s) = R(t)

            tmp = diff(this.ensureRowVector(counts));
            R   = tmp(1)*ones(1, length(counts));
            R(2:end) = tmp;
        end    
        function R  = normalizeResponse(~, R)
            R = R / sum(R);
        end                 
        function x  = ensureDccrvLength(this, x)
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

