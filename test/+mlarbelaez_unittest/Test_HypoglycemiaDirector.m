classdef Test_HypoglycemiaDirector < matlab.unittest.TestCase
	%% TEST_HYPOGLYCEMIADIRECTOR 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_HypoglycemiaDirector)
 	%          >> result  = run(mlarbelaez_unittest.Test_HypoglycemiaDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 05-Jan-2018 19:15:34 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
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
        function test_prepareAbstractADA2018(this)
            this.testObj.prepareAbstractADA2018;
        end
	end

 	methods (TestClassSetup)
		function setupHypoglycemiaDirector(this)
 			import mlarbelaez.*;
 			this.testObj_ = HypoglycemiaDirector;
 		end
	end

 	methods (TestMethodSetup)
		function setupHypoglycemiaDirectorTest(this)
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

