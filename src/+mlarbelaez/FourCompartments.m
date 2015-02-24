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
        xLabel = 'time/s'
        yLabel = 'counts'
        fileprefix = 'four_compartments'
        response
        showPlots = false
        
        VB % fractional blood volume
        Ca % arterial tracer density
 	end 
    
    properties (Dependent)
        baseTitle
        dt
        timeInterpolants
    end
    
    methods %% GET, SET
        function bt = get.baseTitle(this)
            bt = sprintf('%s', this.fileprefix);
        end
        function d = get.dt(this)
            d = this.simulator_.dt;
        end
        function t = get.timeInterpolants(this)
            t = this.simulator_.timeInterpolants;
        end
    end	

    methods (Static)
        function this = prepareSimulator
            %% PREPARESIMULATOR
            %  Usage:  this = prepareSimulator
            %          this.estimateParameters
            %          this.estimateData
            
            import mlarbelaez.*;            
            sim     = FourCompartmentsSimulator;            
            this    = FourCompartments(sim.timeInterpolants, sim.Q);
            this.VB = sim.VB;
            this.Ca = sim.Ca;
        end
        function this = prepareGlucnoflow(varargin)
            %% PREPAREGLUCNOFLOW
            %  Usage:  this = FourCompartments.prepareGlucnoflow(dta_object, tsc_object, VB)
            %          this.estimateParameters
            %          this.estimateData
            
            p = inputParser;
            addRequired(p, 'dta', @(x) isa(x, 'mlpet.DTA'));
            addRequired(p, 'tsc', @(x) isa(x, 'mlpet.TSC'));
            addRequired(p, 'VB',  @(x) isnumeric(x) && x < 1);
            parse(p, varargin{:});
            
            import mlarbelaez.FourCompartments;
            timeInterpolants = interpolateTimes(p.Results.dta.times, p.Results.tsc.times);
            this             = FourCompartments(timeInterpolants, p.Results.tsc.counts);
            this.VB          = p.Results.VB;
            this.Ca          = interpolateCounts(p.Results.dta.times, p.Results.dta.counts, timeInterpolants);
        end
    end
    
	methods 		  
 		function this = FourCompartments(varargin) 
 			%% FOURCOMPARTMENTS 
 			%  Usage:  this = FourCompartments(times, counts) 
                      
 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:});
        end 
        
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
            map('t0' ) = struct('fixed', 1, 'min',   0, 'mean', 0, 'max',  0);
            this = this.runMcmc(map);
        end
        function ed    = estimateData(this)
            ed = this.estimateQ;
        end
        function ed    = estimateDataFast(this, varargin)
            ed = this.estimateQFast(varargin{:});
        end        
        function         plotOri(this)
            figure
            len = min(length(this.dependentData), length(this.Ca));
            plot( ...
                this.timeInterpolants(1:len), this.dependentData(1:len)/max(this.dependentData), 'k', ...
                this.timeInterpolants(1:len), this.Ca(1:len)           /max(this.Ca),            'k:');
            title(sprintf('%s, arterial tracer density', this.baseTitle))
            xlabel('time/s')
            ylabel(sprintf('counts rescaled by %f, %f', max(this.dependentData), max(this.Ca)))
            legend([this.fileprefix ' Q'], 'arterial tracer density')
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
 	end 

    %% PROTECTED
    
    properties (Access = 'protected')
        simulator_
    end
    
    methods (Static, Access = 'protected')        
        function [t,dt] = interpolateTimes(dtaTimes, tscTimes)
            %% INTERPOLATETIMES to linear raster, as required for convolution
            
            t_last  = min(dtaTimes(end), tscTimes(end));
            %dtaTaus = dtaTimes(2:end) - dtaTimes(1:end-1);
            %tscTaus = tscTimes(2:end) - tscTimes(1:end-1);
            %dt      = min([dtaTaus tscTaus])/2;            
            dt      = 1;
            t       = 0:dt:t_last; 
        end
        function c = interpolateCounts(times, counts, timeInterpolants)
            c = spline(times, counts, timeInterpolants);
            c = c(1:length(timeInterpolants));
        end
    end
    
    methods (Access = 'protected')   
        function k = k04fixed(this)
            k = 60 * 20.84 * (100*this.VB)^-0.329; % sec^-1
        end
        function Q = estimateQ(this)
            Q = this.estimateQFast( ...
                this.finalParams('k04'), ...
                this.finalParams('k12'), this.finalParams('k21'), this.finalParams('k32'), this.finalParams('k43'), ...
                this.finalParams('t0'));
        end
        function Q = estimateQFast(this, k04, k12, k21, k32, k43, t0)
            Q = this.simulator_.estimateQFast(k04, k12, k21, k32, k43, t0);
        end   
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

