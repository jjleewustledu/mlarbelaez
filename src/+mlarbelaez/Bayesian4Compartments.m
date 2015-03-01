classdef Bayesian4Compartments < mlbayesian.AbstractMcmcProblem 
	%% BAYESIAN4COMPARTMENTS   

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
        
        parmax
        avpar
 	end 
    
    properties (Dependent)
        baseTitle
        dt
        VB % fractional blood volume
        Ca % arterial tracer density
    end
    
    methods %% GET, SET
        function bt = get.baseTitle(this)
            bt = sprintf('%s', this.fileprefix);
        end
        function d = get.dt(this)
            d = this.simulator_.dt;
        end
        function d = get.VB(this)
            d = this.simulator_.VB;
        end
        function d = get.Ca(this)
            d = this.simulator_.Ca;
        end
    end	

    methods (Static)
        function this = runChecksAgainstSimulator
            %% PREPARESIMULATOR
            %  Usage:  this = runChecksAgainstSimulator
            
            import mlarbelaez.*;
            sim  = Bayesian4CompartmentsSimulator.simulateDefault;
            Q    = sim.Q;
            Q    = Q .* (Q > 0);
            this = Bayesian4Compartments(sim, sim.timeInterpolants, Q);
            this = this.estimateParameters;
        end
    end
    
	methods 		  
 		function this = Bayesian4Compartments(simulator, varargin) 
 			%% BAYESIAN4COMPARTMENTS 
 			%  Usage:  this = Bayesian4Compartments(Bayesian4CompartmentsSimulator_object, interpolated_times, interpolated_counts) 
                      
 			this = this@mlbayesian.AbstractMcmcProblem(varargin{:});
            this.simulator_ = simulator;
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
            map('t0' ) = struct('fixed', 1, 'min', eps, 'mean', eps, 'max', eps);
            %this = this.runMcmc(map);
            
            this.paramsManager = BayesianParameters(map);            
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [this.parmax,this.avpar,this.mcmc] = this.mcmc.runMcmc; 
        end
        function sse  = sumSquaredErrors(this, p)
            p   = num2cell(p);
            sse = norm(this.dependentData - this.estimateQFast(p{:}));
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

