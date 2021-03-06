classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 02:06:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties 
        filetypeExt = '.nii.gz'
    end
    
	properties (Dependent)
        petBlur
    end
    
    methods %% GET
        function g = get.petBlur(~)
            g = mlsiemens.ECATRegistry.instance.petPointSpread;
        end
    end

	methods
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  @param [param-name, param-value[, ...]]
            %         'ac'          is logical
            %         'rnumber'     is numeric
            %         'sessionPath' is a path to the session data
            %         'studyData'   is a mlpipeline.StudyDataSingleton
            %         'snumber'     is numeric
            %         'tracer'      is char
            %         'vnumber'     is numeric
            %         'tag'         is appended to the fileprefix

 			this = this@mlpipeline.SessionData(varargin{:});
            this.ac_ = true;
            assert(isnumeric(this.intervention_));
            this.vnumber_ = this.intervention_;
            this.snumber_ = this.intervention_;
        end
        
        %% IMRData
        
        function loc = fourdfpLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.petLocation, '962_4dfp', ''));
        end        
        function loc = freesurferLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionLocation, 'freesurfer', ''));
        end
        function loc = fslLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.sessionLocation, 'fsl', ''));
        end
        function loc = mriLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = locationType(ip.Results.typ, ...
                fullfile(this.freesurferLocation, 'mri', ''));
        end
                
        %% IPETData        	
        
        function loc = hdrinfoLocation(this, varargin)
            loc = this.scanLocation(varargin{:});
        end
        function loc = petLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = imagingType(ip.Results.typ, ...
                fullfile(this.sessionLocation, 'PET', ''));
        end
        function loc = roiLocation(this, varargin)
            loc = this.scanLocation(varargin{:});
        end
        function loc = scanLocation(this, varargin)
            ip = inputParser;
            addOptional(ip, 'typ', 'path');
            parse(ip, varargin{:});
            
            loc = imagingType(ip.Results.typ, ...
                fullfile(this.petLocation, sprintf('scan%i', this.snumber)));
        end
        
        function obj = petAtlas(this)
            obj = mlpet.PETImagingContext( ...
                cellfun(@(x) this.petObject(x, 'fqfn'), {'oc' 'oo' 'ho' 'tr'}));
            obj = obj.atlas;
        end      
        function p   = petPointSpread(~)
            p = mlsiemens.ECATRegistry.instance.petPointSpread;
        end
        function [dt0_,date_] = readDatetime0(~)
            dt0_ = datetime;
            date_ = datetime(dt0_.Year, dt0_.Month, dt0_.Day);
        end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function obj = petObject(this, varargin)
            ip = inputParser;
            addRequired(ip, 'tracer', @ischar);
            addParameter(ip, 'tag', '', @ischar);
            addOptional(ip, 'typ', 'mlpet.PETImagingContext');
            parse(ip, varargin{:});
            
            obj = imagingType(ip.Results.typ, ...
                fullfile(this.scanLocation, ...
                         sprintf('%s%s%i_frames', this.pnumber, ip.Results.tracer, this.snumber), ...
                         sprintf('%s%s%i%s%s', this.pnumber, ip.Results.tracer, this.snumber, ip.Results.tag, this.filetypeExt)));
        end        
    end
    
    %% HIDDEN
    
    properties (Hidden)
        plasmaGlucose
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

