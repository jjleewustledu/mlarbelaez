classdef StudyDataSingleton < mlpipeline.StudyDataSingleton
	%% StudyDataSingleton  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:31
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    properties (SetAccess = private)
        arbelaezTrunk = '/Volumes/SeagateBP4/Arbelaez'

        mriFolder = 'freesurfer/mri'
        fslFolder = 'fsl'
    end
    
	properties (Dependent)
        subjectsDirs
        loggingPath
    end
    
    methods %% GET
        function g = get.subjectsDirs(this)
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
        function f = hdrinfoFolder(this, sessDat)
            f = this.petFolder(sessDat);
        end   
        function f = petFolder(~, sessDat)
            f = sprintf('PET/scan%i', sessDat.snumber);
        end            
    end
    
    %% PRIVATE

	methods (Access = private)	 
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:}); 
            
            dt = mlsystem.DirTools(this.subjectsDirs);
            fqdns = {};
            for di = 1:length(dt.dns)
                if (strcmp(dt.dns{di}(1), 'p') && strcmp(dt.dns{di}(end-3:end), '_JJL'))
                    fqdns = [fqdns dt.fqdns(di)];
                end
            end
            this.sessionDataComposite_ = ...
                mlpatterns.CellComposite( ...
                    cellfun(@(x) mlpipeline.SessionData('studyData', this, 'sessionPath', x), ...
                    fqdns, 'UniformOutput', false));
            
            mlpipeline.StudyDataSingletons.register('arbelaez', this);
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

