classdef DecayCorrectedCRV < mlarbelaez.CRV
	%% DECAYCORRECTEDCRV provides [15O] decay-correction to CRV objects.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
 	 
    properties (Constant)        
        FILENAME_SUFFIX = '_decayCorrect'
    end
    
	properties  		 
        halfLife = 122.1 % of [15O] in sec
        wellMatrix
    end 
    
    properties (Dependent)
        wellFactor
    end
    
    methods %% GET
        function w = get.wellFactor(this)
            w = this.wellMatrix(5,1); 
            assert(~isnan(w));
        end
    end
    
	methods 
        function l    = length(this)
            l = length(this.counts);
        end
  		function this = DecayCorrectedCRV(crv) 
 			%% DECAYCORRECTEDCRV 
 			%  Usage:  this = DecayCorrectedCRV(CRV_object) 
          
            this = this@mlarbelaez.CRV([crv.studyId mlarbelaez.DecayCorrectedCRV.FILENAME_SUFFIX]);
            assert( isa(crv, 'mlarbelaez.CRV'));
            assert(~isa(crv, 'mlarbelaez.DecayCorrectedCRV'));
            assert(lexist(crv.filename, 'file'));
            this.times = crv.times;
            this.counts = crv.counts;
            
            this = this.readWellMatrix;
            lambda = log(2) / this.halfLife;
            this.counts = this.wellFactor * this.counts .* exp(lambda * this.times);
 		end 
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')
        function this = readWellMatrix(this)
            wfname = fullfile(this.pathname, sprintf('%s.wel', this.studyId(1:5)));
            assert(lexist(wfname, 'file'), ...
                   'mlarbelaez.DecayCorrectedCRV.readWellMatrix could not find %s\n', wfname);
            fid = fopen(  wfname);
            tmp = textscan(fid, '%f %f %f %f %f');
            this.wellMatrix = cell2mat(tmp);
            fclose(fid);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

