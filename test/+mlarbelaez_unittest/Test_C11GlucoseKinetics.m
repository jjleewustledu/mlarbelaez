classdef Test_C11GlucoseKinetics < matlab.unittest.TestCase
	%% TEST_C11GLUCOSEKINETICS 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_C11GlucoseKinetics)
 	%          >> result  = run(mlarbelaez_unittest.Test_C11GlucoseKinetics, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 29-Jun-2017 21:03:08 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		registry
 		testObj
 	end

	methods (Test)
		function test_afun(this)
 			import mlarbelaez.*;
 			this.assumeEqual(1,1);
 			this.verifyEqual(1,1);
 			this.assertEqual(1,1);
 		end
	end

 	methods (TestClassSetup)
		function setupC11GlucoseKinetics(this)
 			import mlarbelaez.*;
 			this.testObj_ = C11GlucoseKinetics;
 		end
	end

 	methods (TestMethodSetup)
		function setupC11GlucoseKineticsTest(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanFiles);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanFiles(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

