classdef CohortXlsx 
	%% COHORTXLSX  

	%  $Revision$
 	%  was created 17-Oct-2015 14:08:54
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
            union = cell(size(this.header,1) + size(this.data,1), ...
                         size(this.header,2) + size(this.data,2));
            rowsHead = size(this.header,1);
            for h = 1:rowsHead
                union{h,:} = this.header{h,:};
            end
            rowsData = size(this.data,1);
            for d = 1:rowsData
                union{rowsHead+d,:} = this.data{d,:};
            end
            [stat,mess] = xlswrite(fname, union);
        end        
 		function this = CohortXlsx(varargin)
 			%% COHORTXLSX
 			%  Usage:  this = CohortXlsx()

 			ip = inputParser;
            addRequired(ip, 'header', {}, @iscell);
            addRequired(ip, 'data',   {}, @(x) iscell(x) || isnumeric(x));
            parse(ip, varargin{:});
            
            this.header = ip.Results.header;
            this.data   = ip.Results.data;
            if (isnumeric(this.data))
                this.data = num2cell(this.data);
            end
            
            assert(size(this.header,2) == size(this.data,2));
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

