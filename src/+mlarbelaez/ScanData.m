classdef ScanData < mlpipeline.ScanData
	%% SCANDATA  

	%  $Revision$
 	%  was created 11-Jun-2017 15:11:35 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties 		
 		tube
        timeDrawn
        timeCounted
        Ge68
        massSample
        apertureCorrGe68
        decayApertureCorrGe68
        
 	end

	methods 
		  
 		function this = ScanData(varargin)
 			%% SCANDATA
 			%  Usage:  this = ScanData()

 			this = this@mlpipeline.ScanData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

