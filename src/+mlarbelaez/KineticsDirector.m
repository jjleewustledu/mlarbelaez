classdef KineticsDirector 
	%% KINETICSDIRECTOR  

	%  $Revision$
 	%  was created 19-Oct-2015 21:55:01
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties (Dependent)
        parameters
 		product
    end
    
    methods % GET
        function p = get.product(this)
            p = this.builder_;
        end
        function p = get.parameters(this)
            p = this.builder_.parameters;
        end
    end
    
    methods (Static)
        function this = loadRegionalKinetics4(regMeas)
            assert(isa(regMeas, 'mlarbelaez.RegionalMeasurements'));
            import mlarbelaez.*;
            
            this = KineticsDirector(regMeas);
        end
    end

	methods 
        function this = estimateAll(this)
            this.builder_ = this.builder_.estimateParameters(this.builder_.map);
        end
 		function this = KineticsDirector(regMeas)
 			%% KINETICSDIRECTOR
 			%  Usage:  this = KineticsDirector()

            assert(isa(regMeas, 'mlarbelaez.RegionalMeasurements'));
            
            import mlarbelaez.*;
            this.builder_ = RegionalKinetics4(regMeas);
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        builder_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

