classdef GlucoseThresholdResults < mlglucose.AbstractSolvedResults
	%% GLUCOSETHRESHOLDRESULTS composites mlhemodynamics.HemodynamicsDirector and mlglucose.GlucoseKineticsDirector,
    %  providing separable construction and get-product methods.  HemodynamicsDirector is configured with:
    %      mlhemodynamics.HemodynamicsBuilder,
    %      mlpet.IScannerDataBuilder, 
    %      mlpet.IAifDataBuilder, 
    %      mlarbelaez.BlindedData, 
    %      mlhemodynamics.HemodynamicsModel.
    %  GlucoseKineticsDirector is configured with:
    %      mlglucose.GlucoseKineticsBuilder,
    %      mlpet.IScannerDataBuilder, 
    %      mlpet.IAifDataBuilder, 
    %      mlarbelaez.BlindedData, 
    %      mlglucose.F18DeoxyGlucoseKineticsBuilder.
    %  The ctor specifies run-time-specific configurations for session data, solver, ROIs.   
    %  HyperglycemiaResults is the client of a builder design pattern.  It creates results needed for publications.  

	%  $Revision$
 	%  was created 04-Dec-2017 12:16:32 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2017 John Joowon Lee.

	methods 
        
        %%
        
        function this = constructHemodynamicMetrics(this)
            this.oxygenDirector_ = this.oxygenDirector_.constructCbf;
            this.oxygenDirector_ = this.oxygenDirector_.constructCbv;
            this.oxygenDirector_ = this.oxygenDirector_.constructPhysiological;
        end
        function prd  = getHemodynamicMetrics(this)
            prd = this.oxygenDirector_.product;
        end
        function this = constructGlucoseMetrics(this)
            this.glucoseDirector_ = this.glucoseDirector_.constructRates;
            this.glucoseDirector_ = this.glucoseDirector_.constructPhysiological;
        end
        function prd  = getGlucoseMetrics(this)
            prd = this.glucoseDirector_.product;
        end
		  
 		function this = GlucoseThresholdResults(varargin)
 			%% GLUCOSETHRESHOLDRESULTS
 			%  @param sessionData is an mlarbelaez.SessionData
 			%  @param solver is an mlkinetics.IKineticsSolver
 			%  @param roisBuilder is an mlrois.IRoisBuilder
            
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', @(x) isa(x, 'mlarbelaez.SessionData'));
            addParameter(ip, 'solver',      @(x) isa(x, 'mlkinetics.IKineticsSolver'));
            addParameter(ip, 'roisBuilder', @(x) isa(x, 'mlrois.IRoisBuilder'));
            parse(ip, varargin{:});
            ipr = ip.Results;
            sessd = ipr.sessionData;
            solver = ipr.solver;
            
            import mlsiemens.* mlvideen.* mlhemodynamics.*;
            sessd.tracer = {'HO' 'OC'};
            scanb  = EcatExactHRPlusBuilder('sessionData', sessd, 'roisBuilder', ipr.roisBuilder);
            bsb    = BloodSuckerBuilder('sessionData', sessd);
            blindd = mlarbelaez.BlindedData('sessionData', sessd);
            hemo   = HemodynamicsModel( ...
                'scannerBuilder', scanb, 'aifBuilder', bsb, 'blindedData', blindd);
            solver.model = hemo;
            this.oxygenDirector_ = HemodynamicsDirector( ...
                HemodynamicsBuilder('solver', solver), 'model', hemo);
            
            import mlglucose.*;
            sessd.tracer = 'GLC';
            scanb  = EcatExactHRPlusBuilder('sessionData', sessd, 'roisBuilder', ipr.roisBuilder);
            wellb  = TSCBuilder('sessionData', sessd);
            blindd = mlarbelaez.BlindedData('sessionData', sessd);
            glc    = C11GlucoseModel( ...
                'scannerBuilder', scanb, 'aifBuilder', wellb, 'blindedData', blindd);
            solver.model = glc;
            
            
            
            this.glucoseDirector_ = GlucoseKineticsDirector([]);
 		end
    end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
end

