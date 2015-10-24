classdef ReportingDirector 
	%% REPORTINGDIRECTOR  

	%  $Revision$
 	%  was created 17-Oct-2015 12:57:01
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
        header
        data
 	end

	methods
        function [stat,mess] = xlswrite(this, fname)
            x = this.cohortXlsx;
            [stat,mess] = x.xlswrite(fname);
        end
        function x = cohortXlsx(this)
            import mlarbelaez.*;
            x = CohortXlsx(this.header, this.data);
        end
 		function this = ReportingDirector(reggionalDir)
 			%% REPORTINGDIRECTOR
 			%  Usage:  this = ReportingDirector(regionalDirectorObject)

            assert(isa(regionalDir, 'mlarbelaez.RegionalDirector'));
            
            this.header = ;
            this.data   = ;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

