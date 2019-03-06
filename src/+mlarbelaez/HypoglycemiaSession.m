classdef HypoglycemiaSession < mlpipeline.Session
	%% HypoglycemiaSession  

	%  $Revision$
 	%  was created 15-Feb-2016 02:06:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	    
	methods
        
        %%
        
        function loc  = sessionLocation(this, varargin)
            ip = inputParser;
            addParameter(ip, 'typ', 'path', @ischar);
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, this.sessionPath);
        end
        
 		function this = HypoglycemiaSession(varargin)
 			%% HYPOGLYCEMIASESSION

 			this = this@mlpipeline.Session(varargin{:});
        end        
    end 
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

