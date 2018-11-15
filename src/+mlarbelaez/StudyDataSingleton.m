classdef StudyDataSingleton < handle & mlpipeline.StudyDataSingleton
	%% StudyDataSingleton  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:31
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

    methods (Static)
        function this = instance(varargin)
            persistent instance_
            if (~isempty(varargin))
                instance_ = [];
            end
            if (isempty(instance_))
                instance_ = mlarbelaez.StudyDataSingleton(varargin{:});
            end
            this = instance_;
        end
        function d    = subjectsDir
            d = fullfile(getenv('ARBELAEZ'), 'GluT', '');
        end
    end
    
    methods
        function        register(this, varargin)
            %% REGISTER this class' persistent instance with mlpipeline.StudyDataSingletons
            %  using the latter class' register methods.
            %  @param key is any registration key stored by mlpipeline.StudyDataSingletons; default 'derdeyn'.
            
            ip = inputParser;
            addOptional(ip, 'key', 'arbelaez', @ischar);
            parse(ip, varargin{:});
            mlpipeline.StudyDataSingletons.register(ip.Results.key, this);
        end
        function this = replaceSessionData(this, varargin)
            %% REPLACESESSIONDATA
            %  @param [parameter name,  parameter value, ...] as expected by mlarbelaez.SessionData are optional;
            %  'studyData' and this are always internally supplied.
            %  @returns this.

            this.sessionDataComposite_ = mlpatterns.CellComposite({ ...
                mlarbelaez.SessionData('studyData', this, varargin{:})});
        end
        function f    = subjectsDirFqdns(this)
            dt = mlsystem.DirTools(this.subjectsDir);
            f = {};
            for di = 1:length(dt.dns)
                e = regexp(dt.dns{di}, 'p\d{4}_JJL', 'match');
                if (~isempty(e))
                    f = [f dt.fqdns(di)]; %#ok<AGROW>
                end
            end
        end 
    end
    
    %% PROTECTED
    
	methods (Access = protected) 
 		function this = StudyDataSingleton(varargin)
 			this = this@mlpipeline.StudyDataSingleton(varargin{:});
 		end
        function this = assignSessionDataCompositeFromPaths(this, varargin)
            if (isempty(this.sessionDataComposite_))
                for v = 1:length(varargin)
                    if (ischar(varargin{v}) && isdir(varargin{v}))                    
                        this.sessionDataComposite_ = ...
                            this.sessionDataComposite_.add( ...
                                mlarbelaez.SessionData('studyData', this, 'sessionPath', varargin{v}));
                    end
                end
            end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

