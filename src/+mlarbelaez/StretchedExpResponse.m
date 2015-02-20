classdef StretchedExpResponse < mlaif.AbstractAifProblem
	%% STRETCHEDEXPRESPONSE models responses ~ exp[-((t - t0)/tau)^beta] [1 + c1 (t - t0)/tau + c2 (t - t0)^2/tau^2, 0 < beta < 2.
    %  Trained against case p8425, subarachnoid hemorrhage

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 

    properties 
        showPlots = true
        baseTitle = 'PET AIF dispersed, delayed by catheter'
        xLabel    = 'time/s'
        yLabel    = 'counts'
        
        dccrv2
        dccrv1
    end
    
    methods (Static)
        function f = empiricalResponse(Hct, timeInterp)
            beta = -0.0097*Hct + 2.1148; % R^2 = 0.072
            c1   =  0.0343*Hct + 0.2538; % R^2 = 0.76
            c2   =  0.0256*Hct - 0.4123; % R^2 = 0.51
            t0   =  0.0672*Hct + 16.579; % R^2 = 0.013
            tau  =  0.4526*Hct - 8.7123; % R^2 = 0.99
            
            arg = (timeInterp - t0) / tau;
            f   = exp(-arg.^beta) .* (1 + c1*arg + c2*arg.^2);
            f   = abs(f);
            f   = f/sum(f);
        end
        function sers = findParameters
            sers     = cell(1,7);
            amatests = cell(1,7);
            heavis   = cell(1,7);
            load('AMAtest4_dccrv.mat');
            load('AMAtest5_dccrv.mat');
            load('AMAtest6_dccrv.mat');
            load('AMAtest7_dccrv.mat');
            load('Heaviside_dccrv.mat');
            amatests{4} = AMAtest4_dccrv;
            amatests{5} = AMAtest5_dccrv;
            amatests{6} = AMAtest6_dccrv;
            amatests{7} = AMAtest7_dccrv;
            for h = 4:7
                heavis{h} = Heaviside_dccrv;
                heavis{h}.counts = heavis{h}.counts * sum(amatests{h}.counts) / sum(Heaviside_dccrv.counts);
            end
            
            import mlarbelaez.*;
            parfor s = 4:7
                sers{s} = StretchedExpResponse(amatests{s}, heavis{s});
                sers{s} = sers{s}.estimateParametersAMAtest6;
            end
        end
    end
    
	methods 
  		function this = StretchedExpResponse(dccrv2, dccrv1)
 			%% STRETCHEDEXPRESPONSE 
 			%  Usage:  this = StretchedExpResponse(convoluted, unconvoluted) % DecayCorrectedCRVs
 			
            assert(isa(dccrv2, 'mlpet.DecayCorrectedCRV'));
            assert(isa(dccrv1, 'mlpet.DecayCorrectedCRV') || isa(dccrv1, 'mlpet.DCV'));
            assert(length(dccrv2.counts) == length(dccrv1.counts));
            
            this.dccrv2 = dccrv2;
            this.dccrv1 = dccrv1;
            this.dependentData = dccrv2.counts;  
            this.independentData = 0:length(this.dependentData)-1;
        end 
        
        
        
        function this = estimateParametersP8425(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing; trained against p8425ho2, subarachnoic hemorrhage, red catheter
            %  Usage:  this = this.estimateParametersP8425

            import mlbayesian.*;
            map = containers.Map;  
            map('beta') = struct('fixed', 0, 'min',    0.5, 'mean',  1.756294, 'max',  3);
            map('c0')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.109328, 'max',  1);
            map('c1')   = struct('fixed', 0, 'min',    1,   'mean',  1.995227, 'max',  3);
            map('c2')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.898744, 'max',  2);
            map('t0')   = struct('fixed', 0, 'min',    1,   'mean',  6.883026, 'max', 10);    
            map('tau')  = struct('fixed', 0, 'min',    1,   'mean',  4.389276, 'max', 10);
            this = this.runMcmc(map);
        end            
        function this = estimateParametersAMAtest6(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing; trained against AMAtest6, phantom experiment of Oct 17, and Heaviside input;
            %  cf. /Volumes/PassportStudio2/Arbelaez/deconvolution/data\ 2014jul17/GT\ Deconvolution\ Experiment\ 2014nov20.xlsx
            %  Usage:  this = this.estimateParametersAMAtest6

            import mlbayesian.*;
            map = containers.Map;
            map('beta') = struct('fixed', 0, 'min',    0.5, 'mean',  1.495955, 'max',  3);
            map('c0')   = struct('fixed', 0, 'min',    eps, 'mean',  0.038336, 'max',  1);
            map('c1')   = struct('fixed', 0, 'min',    1,   'mean',  1.636554, 'max',  3);
            map('c2')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.597322, 'max',  2);
            map('t0')   = struct('fixed', 0, 'min',    1,   'mean',  19.416755, 'max', 30);    
            map('tau')  = struct('fixed', 0, 'min',    1,   'mean',  7, 'max', 30);    
            this = this.runMcmc(map);
        end             
        function this = estimateParametersP8024ho1(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing; trained against CRV('p8024ho1') and DCV('p7153ho1')
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            map = containers.Map;
            map('beta') = struct('fixed', 0, 'min',    0.5, 'mean',  1.523190, 'max',  3);
            map('c0')   = struct('fixed', 0, 'min',    eps, 'mean',  0.011632, 'max',  1);
            map('c1')   = struct('fixed', 0, 'min',    1,   'mean',  1.883449, 'max',  3);
            map('c2')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.787454, 'max',  2);
            map('t0')   = struct('fixed', 0, 'min',    1,   'mean', 20.067452, 'max', 30);    
            map('tau')  = struct('fixed', 0, 'min',    1,   'mean', 11.084634, 'max', 30);    
            this = this.runMcmc(map);
        end     
        function this = estimateParametersP8024ho2(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing; trained against CRV('p8024ho2') and DCV('p7153ho1')
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            map = containers.Map;
            map('beta') = struct('fixed', 0, 'min',    0.5, 'mean',  1.034439, 'max',  3);
            map('c0')   = struct('fixed', 0, 'min',    eps, 'mean',  0.011591, 'max',  1);
            map('c1')   = struct('fixed', 0, 'min',    1,   'mean',  1.896479, 'max',  3);
            map('c2')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.768474, 'max',  2);
            map('t0')   = struct('fixed', 0, 'min',    1,   'mean', 11.621478, 'max', 30);    
            map('tau')  = struct('fixed', 0, 'min',    1,   'mean',  6.147388, 'max', 30);    
            this = this.runMcmc(map);
        end 
        function this = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            map = containers.Map;
            map('beta') = struct('fixed', 0, 'min',    0.5, 'mean',  1.523190, 'max',  3);
            map('c0')   = struct('fixed', 0, 'min',    eps, 'mean',  0.011632, 'max',  1);
            map('c1')   = struct('fixed', 0, 'min',    1,   'mean',  1.883449, 'max',  3);
            map('c2')   = struct('fixed', 0, 'min',    0.1, 'mean',  0.787454, 'max',  2);
            map('t0')   = struct('fixed', 0, 'min',    1,   'mean', 20.067452, 'max', 30);    
            map('tau')  = struct('fixed', 0, 'min',    1,   'mean', 11.084634, 'max', 30);    
            this = this.runMcmc(map);
        end  
        function ed = estimateData(this)
            ed = this.estimateConvolution;
        end
        function ed = estimateDataFast(this, varargin)
            ed = this.estimateConvolutionFast(varargin{:});
        end
        function c  = estimateConvolution(this)
            c = this.estimateConvolutionFast( ...
                this.finalParams('beta'), this.finalParams('c0'), this.finalParams('c1'), ...
                this.finalParams('c2'),   this.finalParams('t0'), this.finalParams('tau'));
        end
        function c  = estimateConvolutionFast(this, beta, c0, c1, c2, t0, tau)
            c = conv(this.stretchedExp(beta, c0, c1, c2, t0, tau), this.dccrv1.countInterpolants);
            c = c(1:this.length);
        end
        function se = estimateStretchedExp(this)
            se = this.stretchedExp( ...
                 this.finalParams('beta'), this.finalParams('c0'), this.finalParams('c1'), ...
                 this.finalParams('c2'),   this.finalParams('t0'), this.finalParams('tau'));
        end
        function se = stretchedExp(this, beta, c0, c1, c2, t0, tau)
            arg = (this.timeInterpolants - t0) / tau;
            se  = c0 * exp(-arg.^beta) .* (1 + c1*arg + c2*arg.^2);
            %se  = se/sum(se);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

