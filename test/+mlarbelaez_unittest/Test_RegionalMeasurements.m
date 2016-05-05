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
        extendedTesting = true
 		registry
 		testObj
 	end

	methods (Test)
        function test_pnumber(this)
            this.verifyEqual(this.testObj.pnumber, 'p7991');
        end
        function test_scanIndex(this)
            this.verifyEqual(this.testObj.scanIndex, 2);
        end
        function test_region(this)
            this.verifyEqual(this.testObj.region, 'thalamus');
        end
        function test_plasmaGlucose(this)
            this.verifyEqual(this.testObj.plasmaGlucose, 61.922727, 'RelTol', 1e-4);
        end
        function test_hct(this)
            this.verifyEqual(this.testObj.hct, 36.3, 'RelTol', 1e-3);
        end
        function test_dta(this)
            this.verifyEqual(this.testObj.dta.times(1:10), ...
                [8 18 25 31 41 48 54 61 67 72]);
            this.verifyEqual(this.testObj.dta.counts(1:10), ...
                [6 7 9 6 10 11 270 7738 24830 39461]);
            this.verifyEqual(this.testObj.dta.wellCounts, this.testObj.dta.counts);
            this.verifyEqual(this.testObj.dta.becquerels, this.testObj.dta.counts);
        end
        function test_tsc(this)
            this.verifyEqual(this.testObj.tsc.times(1:10), ...
                [57 87 117 147 177 207 237 267 297 327] + 0.133, 'RelTol', 1e-4);
            this.verifyEqual(this.testObj.tsc.counts(1:10), ...
                [2245.67266225777 ...
                45422.2797350034 ...
                55076.6804033563 ...
                64349.9101689545 ...
                72171.9101968102 ...
                79071.7188252127 ...
                83407.2680485163 ...
                87932.3175120777 ...
                91941.4799514342 ...
                97132.0090286335], 'RelTol', 1e-10);
            this.verifyEqual(this.testObj.tsc.wellCounts, ...
                this.testObj.tsc.counts, 'RelTol', 1e-10);
            this.verifyEqual(this.testObj.tsc.becquerels, ...
                this.testObj.tsc.wellCounts ./ this.testObj.tsc.taus, 'RelTol', 1e-10)
        end
        function test_vFrac(this)
            this.verifyEqual(this.testObj.vFrac, 0.025571407750249, 'RelTol', 1e-10);
        end
        function test_fFrac(this)
            if (~this.extendedTesting)
                fprintf('Test_RegionalMeasurements.test_fFrac:  set this.extendedTesting to true to enable test');
                return;
            end
            this.verifyEqual(this.testObj.fFrac, 0.00742717035428257, 'RelTol', 5e-2);
        end
        function test_kinetics4(this)
            if (~this.extendedTesting)
                fprintf('Test_RegionalMeasurements.test_kinetics4:  set this.extendedTesting to true to enable test');
                return;
            end
            k4 = this.testObj.kinetics4;
            this.verifyEqual(k4.k04,     0.290448239174875, 'RelTol', 5e-2);
            this.verifyEqual(k4.k12frac, 0.174240215653389, 'RelTol', 5e-2);
            this.verifyEqual(k4.k21,     0.049073882226168, 'RelTol', 5e-2);
            this.verifyEqual(k4.k32,     0.010143674671435, 'RelTol', 5e-2);
            this.verifyEqual(k4.k43,     0.000299380300928, 'RelTol', 5e-2);
        end
        
        function test_ctor(this)
            this.verifyTrue(~isempty(this.testObj));
            disp(this.testObj);
        end
 	end

 	methods (TestClassSetup)
 		function setupRegionalMeasurements(this)
 			import mlarbelaez.*;
            this.registry = ArbelaezRegistry.instance;
            cd(fullfile(this.registry.testSubjectPath));
 			this.testObj = RegionalMeasurements(this.registry.testSubjectPath, 2, 'thalamus');
            this.testObj.vFracCached_ = 0.025571407750249;
            this.testObj.fFracCached_ = 0.00742717035428257;
 		end
 	end

 	methods (TestClassTeardown)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

