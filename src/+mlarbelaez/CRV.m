classdef CRV < mlarbelaez.AbstractCatheterCurve 
	%% CRV objectifies Snyder-Videen *.crv files, replacing the first two count measurements with the third

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	 

    properties (Constant)
        EXTENSION = '.crv'
    end 

    methods (Static)
        function crv = makeAveragedCRV(id, varargin)
            
            assert(length(varargin) > 1);
            for v = 1:length(varargin)
                assert(isa(varargin{v}, 'mlarbelaez.CRV'));
            end
            crv = mlarbelaez.CRV(id);
            crv.times = varargin{1}.times;
            crv.counts = varargin{1}.counts;
            for v = 2:length(varargin)
                crv.counts = crv.counts + varargin{v}.counts;
            end
            crv.counts = crv.counts/length(varargin);
        end
    end
    
	methods 
  		function this = CRV(varargin) 
 			%% CRV 
 			%  Usage:  this = CRV(studyId_string[, path_string]) 

            p = inputParser;
            addRequired(p, 'studyId',       @ischar);
            addOptional(p, 'pathname', pwd, @ischar);
            parse(p, varargin{:});
            
            this.studyId  = p.Results.studyId;
            this.pathname = p.Results.pathname;
            if (lexist(this.filename))
                this = this.readcrv;
            end
        end         
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function this = readcrv(this)
            tab = readtable(this.filename, 'FileType', 'text', 'ReadVariableNames', false, 'Delimiter', ' ','HeaderLines', 2);
            import mlarbelaez.*;
            this.times  = tab.Var1';
            this.counts = tab.Var2';
            this.counts(1) = this.counts(3);            
            this.counts(2) = this.counts(3);            
            
            this.scanDuration = this.times(end);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

