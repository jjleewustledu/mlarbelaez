classdef UnittestRegistry < mlpatterns.Singleton
	%% UNITTESTREGISTRY  

	%  $Revision$
 	%  was created 16-Oct-2015 11:01:19
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlsystem/src/+mlsystem.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties
        sessionFolder = 'p7991_JJL'
        scanFolder = 'scan2'
        ocFilename = 'p7991oc2_333fwhh_on_gluc.nii.gz'
        ocHdrinfoFilename = 'p7991oc2_g3.hdrinfo'
        ocMaskFilename = 'hypothalamus_on_gluc2.nii.gz'
    end
    
	properties (Dependent)
 		sessionPath
 		ocFqfilename
        ocHdrinfoFqfilename
        ocMaskFqfilename
    end
    
    methods % GET
        function g = get.sessionPath(this)
            g = fullfile(getenv('MLUNIT_TEST_PATH'), 'Arbelaez', 'GluT', this.sessionFolder, '');
        end
        function g = get.ocFqfilename(this)
            g = fullfile(this.sessionPath, 'PET', this.scanFolder, this.ocFilename);
        end
        function g = get.ocHdrinfoFqfilename(this)
            g = fullfile(this.sessionPath, 'PET', this.scanFolder, this.ocHdrinfoFilename);
        end
        function g = get.ocMaskFqfilename(this)
            g = fullfile(this.sessionPath, 'PET', this.scanFolder, this.ocMaskFilename);
        end
    end

    methods (Static)
        function this = instance(qualifier)
            %% INSTANCE uses string qualifiers to implement registry behavior that
            %  requires access to the persistent uniqueInstance
            persistent uniqueInstance
            
            if (exist('qualifier','var') && ischar(qualifier))
                if (strcmp(qualifier, 'initialize'))
                    uniqueInstance = [];
                end
            end
            
            if (isempty(uniqueInstance))
                this = mlarbelaez.UnittestRegistry();
                uniqueInstance = this;
            else
                this = uniqueInstance;
            end
        end
    end 
    
	methods (Access = 'private')		  
 		function this = UnittestRegistry(varargin)
 			this = this@mlpatterns.Singleton(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

