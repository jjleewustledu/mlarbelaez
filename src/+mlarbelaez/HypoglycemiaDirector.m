classdef HypoglycemiaDirector 
	%% HYPOGLYCEMIADIRECTOR  

	%  $Revision$
 	%  was created 05-Jan-2018 19:15:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
 		
 	end

	methods 
        
        function this = prepareAbstractADA2018(this)
            ada2018 = mlarbelaez.ADA2018;
            ada2018.prepareAbstract;
        end
		  
 		function this = HypoglycemiaDirector(varargin)
 			%% HYPOGLYCEMIADIRECTOR
 			%  Usage:  this = HypoglycemiaDirector()

 			
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

