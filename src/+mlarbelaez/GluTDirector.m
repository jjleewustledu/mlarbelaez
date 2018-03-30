classdef GluTDirector 
	%% GLUTDIRECTOR  

	%  $Revision$
 	%  was created 27-Jul-2017 18:37:16 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
    end
    
    methods (Static)
        function prod = instanceConstructKinetics
            gb = mlarbelaez.GluTBuilder;
            gb = gb.buildSessionData('sessionID', 'p8047_JJL', 'intervention', 1);
            gb = gb.buildClampingCondition;
            gb = gb.buildRegion('region', 'hypothalamus');
            gb = gb.buildModel;
            prod = gb.product;
        end
    end

	methods 
		  
 		function this = GluTDirector(varargin)
 			%% GLUTDIRECTOR
 			%  Usage:  this = GluTDirector()

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

