classdef BetadcvCatheterResponse < mlaif.AbstractAifProblem & mlarbelaez.AbstractCatheterAnalysis 
	%% CATHETERRESPONSE estimates parameters of the betadcv kernel (ak1, e) by fitting 
    %  crv data with a Heaviside input and betadcv model for the catheter impulse response.

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
        betadcv
    end
    
    methods (Static)
        function k = createKernel()
            crv = mlpet.CRV.load('/Users/jjlee/Box/Chaojie/p7750ho1.crv');
            this = mlarbelaez.BetadcvCatheterResponse(crv);
            k = this.estimateKernel();
        end
    end
    
	methods 
        function this  = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            eps0 = 1e-6;
            ncnt0 = max(this.dependentData)*length(this.timeInterpolants);
            map = containers.Map;
            map('ak1')  = struct('fixed', 0, 'min',  eps0, 'mean',       0.195150,    'max',  1);
            map('e')    = struct('fixed', 0, 'min',  eps0, 'mean',       9.724002e-5, 'max',  1);
            map('ncnt') = struct('fixed', 0, 'min',  eps0,  'mean', 253243.52,        'max', 100*ncnt0);
            map('t0')   = struct('fixed', 0, 'min',     5,  'mean',     22.74890,     'max',  35);              
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
                this.finalParams('ak1'), this.finalParams('e'), this.finalParams('ncnt'), this.finalParams('t0'));
        end  
        function k = estimateKernel(this)
            k = this.estimateKernelFast( ...
                this.finalParams('ak1'), this.finalParams('e'), this.finalParams('t0'));
        end 
        
  		function this  = BetadcvCatheterResponse(amatest_crv)
 			%% CATHETERRESPONSE 
 			%  Usage:  this = CatheterResponse(amatests_decoy_corrected_CRV) 
 			
            assert(isa(amatest_crv, 'mlpet.CRV'));
            import mlarbelaez.* mlpet.*;
            this.betadcv         = Betadcv2(amatest_crv.fileprefix);
            dccrv                = DecayCorrectedCRV(amatest_crv);
            this.dependentData   = dccrv.counts; % this.smoothPeristalsis
            this.independentData = 0:length(this.dependentData)-1;
 		end 
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')    
        function dccrv = estimateDccrvFast(this, ak1, e, ncnt, t0)
            dccrv = conv(this.heavisideInput(ncnt), this.estimateKernelFast(ak1, e, t0));
            dccrv = this.ensureDccrvLength(dccrv);
        end        
        function hi = heavisideInput(this, ncnt)
            hi = ncnt * ones(size(this.timeInterpolants));
        end 
        function k = estimateKernelFast(this, ak1, e, t0)
            k = this.betadcv.tryKernel(t0, ak1, e);
        end         
        function c  = smoothPeristalsis(this, c)
            %% SMOOTHPERISTALSIS attempts to remove fluctuations associated with peristaltic pumps 
            
            c = this.ensureRowVector(smooth(c));
        end
        
    end
    
    %% PRIVATE
    
    methods (Access = 'private')
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

