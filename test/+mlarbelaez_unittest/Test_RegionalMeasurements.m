classdef Test_RegionalMeasurements < matlab.unittest.TestCase
	%% TEST_REGIONALMEASUREMENTS 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_RegionalMeasurements)
 	%          >> result  = run(mlarbelaez_unittest.Test_RegionalMeasurements, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 15-Oct-2015 17:17:32
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
        extendedTesting = false
 		registry
 		testObj
 	end

	methods (Test)
        function test_pnumber(this)
            this.assertEqual(this.testObj.pnumber, 'p7991');
        end
        function test_scanIndex(this)
            this.assertEqual(this.testObj.scanIndex, 2);
        end
        function test_region(this)
            this.assertEqual(this.testObj.region, 'hypothalamus');
        end
        function test_plasmaGlucose(this)
            this.assertEqual(this.testObj.plasmaGlucose, 61.922727, 'RelTol', 1e-4);
        end
        function test_hct(this)
            this.assertEqual(this.testObj.hct, 36.3, 'RelTol', 1e-3);
        end
        function test_dta(this)
            this.assertEqual(this.testObj.dta.times(1:10), ...
                [8 18 25 31 41 48 54 61 67 72]);
            this.assertEqual(this.testObj.dta.counts(1:10), ...
                [6 7 9 6 10 11 270 7738 24830 39461]);
            this.assertEqual(this.testObj.dta.wellCounts(1:10), ...
                [6 7 9 6 10 11 270 7738 24830 39461]);
        end
        function test_vFrac(this)
            this.assertEqual(this.testObj.vFrac, 0.0845101543763304, 'RelTol', 1e-4);
        end
        function test_fFrac(this)
            if (~this.extendedTesting)
                fprintf('Test_RegionalMeasurements.test_fFrac:  set this.extendedTesting to true to enable test');
                return;
            end
            this.assertEqual(this.testObj.fFrac, 0.00699280511496433, 'RelTol', 5e-2);
        end
        function test_kinetics4(this)
            if (~this.extendedTesting)
                fprintf('Test_RegionalMeasurements.test_kinetics4:  set this.extendedTesting to true to enable test');
                return;
            end
            k4 = this.testObj.kinetics4;
            this.assertEqual(k4.ks(1), [], 'RelTol', 5e-2);
        end
        
        function test_ctor(this)
            this.assertTrue(~isempty(this.testObj));
            disp(this.testObj);
        end
 	end

 	methods (TestClassSetup)
 		function setupRegionalMeasurements(this)
 			import mlarbelaez.*;
            this.registry = ArbelaezRegistry.instance;
            cd(fullfile(this.registry.testSubjectPath));
 			this.testObj = RegionalMeasurements(this.registry.testSubjectPath, 2, 'hypothalamus');
 		end
 	end

 	methods (TestClassTeardown)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

