classdef CatheterResponse < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
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
        function this = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            ncnt0 = max(this.dependentData);
            eps0 = 1e-6;
            map = containers.Map;
            map('alpha')  = struct('fixed', 0, 'min',     0.1, 'mean',     2,    'max',  10);
            map('alpha2') = struct('fixed', 0, 'min',     0.1, 'mean',     2,    'max',  10);
            map('beta')   = struct('fixed', 0, 'min',  eps0,   'mean',     0.3,  'max',  10);
            map('beta2')  = struct('fixed', 0, 'min',  eps0,   'mean',     0.3,  'max',  10);
            %map('c1')    = struct('fixed', 0, 'min',  -100,   'mean',     0,    'max', 100);
            %map('c2')    = struct('fixed', 0, 'min',  -100,   'mean',     0,    'max', 100);
            %map('c3')    = struct('fixed', 0, 'min',  -100,   'mean',     0,    'max', 100);
            %map('c4')    = struct('fixed', 0, 'min',  -100,   'mean',     0,    'max', 100);
            %map('delta') = struct('fixed', 0, 'min',  eps0,   'mean',     0.03, 'max',   1);
            map('eps')    = struct('fixed', 0, 'min',  eps0,   'mean', 0.05,     'max',   0.5);
            map('ncnt')   = struct('fixed', 0, 'min',  eps0,   'mean', 10*ncnt0, 'max',  50*ncnt0);
            map('t0')     = struct('fixed', 0, 'min',    10,   'mean',    15,    'max',  35);    
            map('tauRe')  = struct('fixed', 0, 'min',     1,   'mean',     5,    'max',  20);             
            this = this.runMcmc(map);
        end           
        function ed   = estimateData(this)
            ed = this.estimateTwoResponse;
        end
        function ed   = estimateDataFast(this, varargin)
            ed = this.estimateTwoResponseFast(varargin{:});
        end
        
  		function this = CatheterResponse(amatests_dccrv)
 			%% CATHETERRESPONSE 
 			%  Usage:  this = CatheterResponse(amatests_decoy_corrected_CRV) 
 			
            assert(isa(amatests_dccrv, 'mlpet.DecayCorrectedCRV'));
            this.dependentData = this.normalizeResponse( ...
                                 this.smoothPeristalsis( ...
                                 this.estimateResponseByDiff( ...
                                 this.smoothPeristalsis(amatests_dccrv.counts))));  
            this.independentData = 0:length(this.dependentData)-1;
 		end 
    end 
    
    methods (Access = 'protected')    
        function R  = estimateResponseByDiff(this, counts)
            %% ESTIMATERESPONSEBYDIFF is valid for Heaviside inflow of tracer into a cathether that leads to the blood-sucker detector
            %  f(t)  = [g  * R](t); g is Heaviside
            %  f'(t) = [g' * R](t)
            %  f'(t) = \int ds \delta(s) R(t - s) = R(t)

            tmp = diff(this.ensureRowVector(counts));
            R   = tmp(1)*ones(1, length(counts));
            R(2:end) = tmp;
        end        
        function c  = smoothPeristalsis(this, c)
            %% SMOOTHPERISTALSIS attempts to remove fluctuations associated with peristaltic pumps 
            
            c = this.ensureRowVector(smooth(c));
        end
        function R  = normalizeResponse(~, R)
            R = R / sum(R);
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
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

