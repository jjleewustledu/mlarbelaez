classdef TestDataSingleton < mlarbelaez.StudyDataSingleton
	%% TESTDATASINGLETON  

	%  $Revision$
 	%  was created 30-Jan-2016 18:02:44
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	
    
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
                instance_ = mlarbelaez.TestDataSingleton();
            end
            this = instance_;
        end
        function        register(varargin)
            %% REGISTER
            %  @param []:  if this class' persistent instance
            %  has not been registered, it will be registered via instance() call to the ctor; if it
            %  has already been registered, it will not be re-registered.
            %  @param ['initialize']:  any registrations made by the ctor will be repeated.
            
            mlarbelaez.TestDataSingleton.instance(varargin{:});
        end
    end  

    %% PROTECTED
    
	methods (Access = protected)
 		function this = TestDataSingleton(varargin)
 			this = this@mlarbelaez.StudyDataSingleton(varargin{:});
            
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
            mlpipeline.StudyDataSingletons.register('test_arbelaez', this);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

