classdef DTA < mlarbelaez.AbstractCatheterCurve
	%% DTA objectifies Videen *.dta files.  Counts are decay-corrected.
    %  cf. man dta

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 

    properties (Constant)
        EXTENSION = '.dta'
    end
    
    properties
        headerString
        numberFrames
    end
    
	methods 
  		function this = DTA(varargin) 
 			%% CRV 
 			%  Usage:  this = DTA(studyId_string[, path_string]) 

            p = inputParser;
            addRequired(p, 'studyId',       @ischar);
            addOptional(p, 'pathname', pwd, @ischar);
            parse(p, varargin{:});
            
            this.studyId  = p.Results.studyId;
            this.pathname = p.Results.pathname;
            if (lexist(this.filename))
                this = this.readdta;
            end
        end         
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readdta(this)
            fid = fopen(this.filename);
            tmp = textscan(fid, '%s', 1, 'Delimiter', '\n');
            this.headerString = tmp{1};
            tmp = textscan(fid, '%d', 1, 'Delimiter', '\n');
            this.numberFrames = tmp{1};
            ts = textscan(fid, '%f %f %f %f %f %f %f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times = ts{1}';
            this.counts = ts{2}';
            
            this.scanDuration = this.times(end);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end


