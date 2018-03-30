classdef HoBuilder < mlpet.TracerKineticsBuilder
	%% HOBUILDER  

	%  $Revision$
 	%  was created 05-Jul-2017 18:08:15 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
    end
    
    properties (Dependent)
    end 

	methods 
        
        %% GET/SET
        
		  
        %%
        
 		function this = HoBuilder(varargin)
 			%% HOBUILDER
            %  @param named 'logger' is an mlpipeline.AbstractLogger.
            %  @param named 'product' is the initial state of the product to build.
            %  @param named 'sessionData' is an mlarbelaez.SessionData.
 			%  @param named 'buildVisitor' is an mlfourdfp.FourdfpVisitor.
            %  @param named 'roisBuild' is an mlrois.IRoisBuilder.
            %  @param named 'kinetics' is an mlkinetics.AbstractHoKinetics.

 			this = this@mlpet.TracerKineticsBuilder(varargin{:});
            ip = inputParser;
            ip.KeepUnmatched = true;
            addParameter(ip, 'sessionData', mlarbelaez.SessionData, @(x) isa(x, 'mlarbelaez.SessionData'));
            addParameter(ip, 'kinetics', [], @(x) isa(x, 'mlkinetics.AbstractHoKinetics') || isempty(x));
            parse(ip, varargin{:});
            
            this.sessionData_.tracer = 'HO';
            this.sessionData_.attenuationCorrected = true;
            if (isempty(this.kinetics_))
                this.kinetics_ = mlarbelaez.HoKinetics( ...
                    'scanData', mlarbelaez.ScanData('sessionData', this.sessionData), ...
                    'roisBuild', this.roisBuilder);
            end
 		end
 	end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
    end
        
    %% PRIVATE
    
    properties (Access = private)
    end 
    

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

