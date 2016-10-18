classdef Test_T4ResolveBuilder < matlab.unittest.TestCase
	%% TEST_T4RESOLVEBUILDER 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_T4ResolveBuilder)
 	%          >> result  = run(mlarbelaez_unittest.Test_T4ResolveBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 21-Apr-2016 10:34:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	

	properties
        gluc
        logFilename = 'p7861gluc1r1_T4ResolveBuilder_frameReg_20160429T041144.log'
        %'p7861gluc1r2_T4ResolveBuilder_frameReg_20160429T063931.log' 
 		studyd
        sessd
 		testObj
        ipresults
        
        view = true
        quick = true
 	end

	methods (Test)
		function test_report(this)
            r = this.reporter_.report;
            r.pcolor('z(etas)',   this.reporter_);
            %r.pcolor('z(curves)', this.reporter_);
        end
        function test_report1(this)          
            r = this.reporter_.report;
            t4r = mlraichle.T4Resolve('sessionData', this.testObj.sessionData);
            t4r = t4r.parseLog( ...
                fullfile(t4r.sessionData.sessionPath, this.logFilename), ...
                'frameLength', 40);
            t4r = t4r.shiftFrames(4);
            r.pcolor('z(etas)',   t4r);
            %r.pcolor('z(curves)', t4r);
        end
        function test_report2(this)          
            r = this.reporter_.report;
            t4r = mlraichle.T4Resolve('sessionData', this.testObj.sessionData);
            t4r = t4r.parseLog( ...
                fullfile(t4r.sessionData.sessionPath, this.logFilename), ...
                'frameLength', 44);
            t4r = t4r.shiftFrames(4);
            r.pcolor('z(etas)',   t4r);
            %r.pcolor('z(curves)', t4r);
        end
        
        function test_msktgenInitial(this)
            cd(fullfile(this.sessd.sessionPath, 'PET', 'scan1', 'GLUC1', ''));
            this.testObj = this.testObj.msktgenInitial(this.ipresults);
            [s,r] = mlbash(sprintf('freeview T1.4dfp.img %s_on_T1_g11.4dfp.img', this.ipresults.dest));
            this.verifyEqual(s, 0);
            fprintf(r);
        end
        function test_msktgenResolved(this)
        end
		function test_t4ResolvePET0(this)
            if (this.quick)
                return
            end
            fprintf('Test_T4ResolveBuilder.test_t4ResolvePET0:\n'); 
            fprintf('\trunning t4ResolvePET which may requires hours of processing time..........\n');
            this.testObj  = this.testObj.t4ResolvePET;
            this.verifyTrue(~isempty(this.testObj.product));            
            if (this.view)
                this.testObj.product.gluc.view;
            end
        end
        function test_t4ResolvePET(this)
            this.testObj = this.testObj.t4ResolvePET;
            this.verifyTrue(~isempty(this.testObj.product));            
            if (this.view)
                for p = 1:length(this.testObj.product)
                    try
                        [s,r] = mlbash(sprintf('freeview %s', this.testObj.product{p}));
                    catch ME
                        fprintf('s->%i; r->%s\n', s, r)
                        handwarning(ME);
                    end
                end
            end
        end
        function test_maskBoundaries(this)
            cd(fullfile(this.sessd.petPath, 'GLUC1', ''));
            msk = this.testObj.maskBoundaries([this.ipresults.source '_sumt']);
            mlbash(sprintf('freeview %s.4dfp.img', msk));
        end
	end

 	methods (TestClassSetup)
		function setupT4ResolveBuilder(this)
 			import mlarbelaez.*;       
            this.studyd = mlpipeline.StudyDataSingletons.instance('test_arbelaez');
            this.sessd  = SessionData( ...
                'studyData', this.studyd, ...
                'sessionPath', fullfile(this.studyd.subjectsDir, 'p7861_JJL', ''), ...
                'snumber', 1); 
            cd(fullfile(this.sessd.sessionPath));
            this.testObj_ = T4ResolveBuilder('sessionData', this.sessd);
            this.ipresults = struct( ...
                'source',  this.sessd.gluc.fileprefix, ...
                'dest',  this.sessd.gluc.fileprefix, ...
                'mprage', 'T1', ...
                'frame0',  4, ...
                'frameF',  44, ...
                'firstCrop',    1, ...
                'atlas',  'TRIO_Y_NDC', ...
                'blur',    max(mlpet.PETRegistry.instance.petPointSpread));
            setenv('DEBUG', '');            
            
 			%this.reporter_ = mlraichle.T4Resolve('sessionData', this.sessd);
            %this.reporter_ = this.reporter_.parseLog( ...
            %    fullfile(this.testObj_.sessionData.sessionPath, this.logFilename), ...
            %    'frameLength', 44);   
 		end
	end

 	methods (TestMethodSetup)
		function setupT4ResolveBuilderTest(this)
 			this.testObj = this.testObj_;
            cd(fullfile(this.sessd.sessionPath));
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
        reporter_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

