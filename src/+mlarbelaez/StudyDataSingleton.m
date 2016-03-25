classdef StudyDataSingleton < mlpipeline.StudyDataSingleton
	%% StudyDataSingleton  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:31
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties (SetAccess = protected)
        arbelaezTrunk = getenv('ARBELAEZ')
    end
    
	properties (Dependent)
        subjectsDir
        loggingPath
    end
    
    methods %% GET
        function g = get.subjectsDir(this)
            g = fullfile(this.arbelaezTrunk, 'GluT', '');
        end
        function g = get.loggingPath(this)
            g = this.arbelaezTrunk;
        end
    end

    methods (Static)
        function this = instance(qualifier)
            persistent instance_            
            if (exist('qualifier','var'))
                assert(ischar(qualifier));
                if (strcmp(qualifier, 'initialize'))
                    instance_ = [];
                end
            end            
            if (isempty(instance_))
                instance_ = mlarbelaez.StudyDataSingleton();
            end
            this = instance_;
        end
        function        register(varargin)
            %% REGISTER
            %  @param []:  if this class' persistent instance
            %  has not been registered, it will be registered via instance() call to the ctor; if it
            %  has already been registered, it will not be re-registered.
            %  @param ['initialize']:  any registrations made by the ctor will be repeated.
            
            mlarbelaez.StudyDataSingleton.instance(varargin{:});
        end
    end
    
    methods
        function f = fslFolder(~, ~)
            f = 'fsl';
        end
        function f = hdrinfoFolder(this, sessDat)
            f = this.petFolder(sessDat);
        end   
        function f = mriFolder(~, ~)
            f = 'freesurfer/mri';
        end
        function f = petFolder(~, sessDat)
            f = sprintf('PET/scan%i', sessDat.snumber);
        end
        
        function fn = gluc_fn(~, sessDat, varargin)            
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            try
                fp = sprintf('%sgluc%i', sessDat.pnumber, sessDat.snumber);
                fn = fullfile([fp ip.Results.suff '.nii.gz']);
            catch ME
                handwarning(ME);
                fn = '';
            end
        end
        function fn = ho_fn(~, sessDat, varargin)            
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            try
                fp = sprintf('%sho%i', sessDat.pnumber, sessDat.snumber);
                fn = fullfile([fp ip.Results.suff '.nii.gz']);
            catch ME
                handwarning(ME);
                fn = '';
            end
        end
        function fn = oc_fn(~, sessDat, varargin)            
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            try
                fp = sprintf('%soc%i', sessDat.pnumber, sessDat.snumber);
                fn = fullfile([fp ip.Results.suff '.nii.gz']);
            catch ME
                handwarning(ME);
                fn = '';
            end
        end
        function fn = tr_fn(~, sessDat, varargin)            
            ip = inputParser;
            addOptional(ip, 'suff', '', @ischar);
            parse(ip, varargin{:})
            try
                fp = sprintf('%str%i', sessDat.pnumber, sessDat.snumber);
                fn = fullfile([fp ip.Results.suff '.nii.gz']);
            catch ME
                handwarning(ME);
                fn = '';
            end
        end
    end
    
    %% PROTECTED
    
	methods (Access = protected) 
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:}); 
            
            dt = mlsystem.DirTools(this.subjectsDir);
            fqdns = {};
            for di = 1:length(dt.dns)
                if (strcmp(dt.dns{di}(1), 'p') && strcmp(dt.dns{di}(end-3:end), '_JJL'))
                    fqdns = [fqdns dt.fqdns(di)];
                end
            end
            this.sessionDataComposite_ = ...
                mlpatterns.CellComposite( ...
                    cellfun(@(x) mlarbelaez.SessionData('studyData', this, 'sessionPath', x), ...
                    fqdns, 'UniformOutput', false));
             this.registerThis;
 		end
        function registerThis(this)
            mlpipeline.StudyDataSingletons.register('arbelaez', this);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

