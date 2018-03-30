classdef Test_RegionalDirector < matlab.unittest.TestCase
	%% TEST_REGIONALDIRECTOR 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_RegionalDirector)
 	%          >> result  = run(mlarbelaez_unittest.Test_RegionalDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 17-Oct-2015 12:33:52
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		registry
 		testObj
    end

    methods
        function p = scanSetPath(this, folder)
            p = fullfile(this.registry.sessionPath, 'PET', folder, '');
        end
        function fn = glucOnAtlas(this)
            fn = fullfile(this.registry.sessionPath, 'fsl', '');
        end
        function fn = maskOnAtlas(this)
            fn = fullfile(this.registry.sessionPath, 'fsl', '');
        end
        function fn = mask(this)
            fn = fullfile(this.registry.sessionPath, 'fsl', '');
        end
        function fn = xfm(this)
            fn = fullfile(this.registry.sessionPath, 'fsl', '');
        end
        function fn = mprage(this)
            fn = fullfile(this.registry.sessionPath, 'fsl', '');
        end
        function fn = petAtlas(this)
            fn = fullfile(this.registry.sessionPath, 'PET', '');
        end
    end
    
	methods (Test)
 		function test_report(this)
            rep = this.testObj.report();
            this.assertTrue(isa(rep,            'mlarbelaez.ReportingDirector'));
            this.assertTrue(isa(rep.cohortXlsx, 'mlarbelaez.CohortXlsx'));
            this.assertEqual(   rep.cohortXlsx.header{1,1}, '');
            this.assertEqual(   rep.cohortXlsx.data{  1,1}, []);
 		end
        function test_regionSampling(this)
            this.assertEqual( ...
                this.testObj.regionSampling(this.maskOnAtlas, this.glucOnAtlas), ...
                []);
        end
        function test_alignMask(this)            
            this.testObj = this.testObj.alignMask(this.mask, this.xfm);
        end
        function test_alignMR(this)            
            this.testObj = this.testObj.alignMR(this.mprage, this.petAtlas);
        end
        function test_alignPET(this)
            this.testObj = this.testObj.alignPETScanSet(this.scanSetPath('scan1'));
            this.testObj = this.testObj.alignPETScanSet(this.scanSetPath('scan2'));
            this.testObj = test.testObj.alignPET( ...
                { this.scanSetPath('scan1') this.scanSetPath('scan1')});
        end
        function test_measurements(this)
        end
        function test_estimations(this)
        end
 	end

 	methods (TestClassSetup)
 		function setupRegionalDirector(this)
 			import mlarbelaez.*;            
            this.registry = UnittestRegistry;
 			this.testObj  = RegionalDirector;
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

