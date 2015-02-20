classdef FourCompartments < mlbayesian.AbstractMcmcProblem 
	%% FOURCOMPARTMENTS   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties  		 
        xLabel    = 'time/s'
        yLabel    = 'counts'
        fileprefix
        response
        showPlots = false
        
        VB
        Ca
 	end 
    
    properties (Dependent)
        baseTitle
        timeInterpolants
    end
    
    methods %% GET, SET
        function bt = get.baseTitle(this)
            bt = sprintf('%s', this.fileprefix);
        end
        function t = get.timeInterpolants(this)
            t = this.independentData;
        end
        function this = set.timeInterpolants(this, t)
            this.independentData = t;
        end        
    end	

	methods 
        function this  = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters;
            
            import mlbayesian.*;
            map = containers.Map;
            map('k04') = struct('fixed', 1, 'min', eps, 'mean', this.k04fixed, 'max', 10);
            map('k12') = struct('fixed', 0, 'min', eps, 'mean', 1, 'max', 10);
            map('k21') = struct('fixed', 0, 'min', eps, 'mean', 1, 'max', 10);
            map('k32') = struct('fixed', 0, 'min', eps, 'mean', 1, 'max', 10);
            map('k43') = struct('fixed', 0, 'min', eps, 'mean', 1, 'max', 10);
            this = this.runMcmc(map);
        end
        function ed    = estimateData(this)
            ed = this.estimateQ;
        end
        function ed    = estimateDataFast(this, varargin)
            ed = this.estimateQFast(varargin{:});
        end        
        function Q = estimateQ(this)
            Q = this.estimateQFast( ...
                this.finalParams('k04'), ...
                this.finalParams('k12'), this.finalParams('k21'), this.finalParams('k32'), this.finalParams('k43'));
        end
        function         plotOri(this)
            figure
            len = min(length(this.dependentData), length(this.response));
            plot( ...
                this.timeInterpolants(1:len), this.dependentData(1:len)/max(this.dependentData), 'k', ...
                this.timeInterpolants(1:len), this.response(1:len)     /max(this.response),      'k:');
            title(sprintf('%s, large catheter response', this.baseTitle))
            xlabel('time/s')
            ylabel(sprintf('counts rescaled by %f, %f', max(this.dependentData), max(this.response)))
            legend([this.fileprefix ' DCCRV'], 'catheter response')
        end
        function         plotEstimate(this)
            figure
            len   = min([length(this.dependentData) length(this.estimateDccrv) length(this.estimateDcv)]);
            dcv   = this.estimateDcv;
            dccrv = this.estimateDccrv;
            plot(this.timeInterpolants(1:len), this.dependentData(1:len), 'k', ...
                 this.timeInterpolants(1:len), dccrv(1:len), 'k--', ...
                 this.timeInterpolants(1:len), dcv(1:len),   'k:');
            title(sprintf('%s, Bayesian DCCRV, Bayesian DCV', this.baseTitle))
            xlabel('time/s')
            ylabel('counts')
            legend([this.fileprefix ' DCCRV'], 'Bayesian DCCRV', 'Bayesian DCV')
        end
		  
 		function this = FourCompartments(varargin) 
 			%% FOURCOMPARTMENTS 
 			%  Usage:  this = FourCompartments() 

 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:}); 
            p = inputParser;
            addRequired(p, 'dta', @(x) isa(x, 'mlpet.DTA'));
            addRequired(p, 'tsc', @(x) isa(x, 'mlpet.TSC'));
            addRequired(p, 'VB',  @(x) isnumeric(x) && x < 1);
            parse(p, varargin{:});
                      
            this.timeInterpolants = this.interpolateTimes(p.Results.dta, p.Results.tsc);
            this.Ca               = this.interpolateCounts(p.Results.dta);
            this.dependentData    = this.interpolateCounts(p.Results.tsc); % q_pet(t) = \Sum_i q_i(t)
 		end 
 	end 

    %% PROTECTED
    
    methods (Access = 'protected')   
        function k = this.k04fixed(this)
            k = 60 * 20.84 * (100*this.VB)^-0.329; % sec^-1
        end
        function Q = estimateQFast(this, k04, k12, k21, k32, k43)
            k22 = k12 + k32;
            t = this.timeInterpolants;
            
            q1 = this.VB * this.Ca;
            q2 = this.VB * k21 * conv(exp(-k22*t), this.Ca);
            q3 = this.VB * k21 * k32 * (k22 - k43)^-1 * conv(exp(-k43*t) - exp(-k22*t), this.Ca);
            q4 = this.VB * k21 * k32 * k43 * conv( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)), ...
                     this.Ca); 
            Q = q1 + q2(1:length(t)) + q3(1:length(t)) + q4(1:length(t));
        end   
        function t = interpolateTimes(~, dta, tsc)
            if (length(dta) < length(tsc))
                t = dta.times;
            else
                t = tsc.times;                
            end  
        end
        function c = interpolateCounts(this, countsObj)
            %% INTERPOLATECOUNTS supports DTA, TSC objects
            
            c = spline(countsObj.times, countsObj.counts, this.timeInterpolants);
            c = c(1:length(this.timeInterpolants));
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

