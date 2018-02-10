classdef Test_ADA2018 < matlab.unittest.TestCase
	%% TEST_ADA2018 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_ADA2018)
 	%          >> result  = run(mlarbelaez_unittest.Test_ADA2018, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 26-Jan-2018 16:04:45 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
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
        function test_prepareRandomized1STT(this)
            ada.prepareBaseline;
            for g = 1:3; ada.prepareRandomized1STT(ada.t1dmIds, 1, g, 't1dm'); end
            for g = 1:4; ada.prepareRandomized1STT(ada.controlsIds, 1, g, 'controls'); end
            for g = 1:4; ada.prepareRandomized1STT(ada.controlsIds, 2, g, 'controls'); end
        end
	end

 	methods (TestClassSetup)
		function setupADA2018(this)
 			import mlarbelaez.*;
 			this.testObj_ = ADA2018;
 		end
	end

 	methods (TestMethodSetup)
		function setupADA2018Test(this)
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

