classdef Test_GluTAlignmentBuilder < matlab.unittest.TestCase
	%% TEST_GLUTALIGNMENTBUILDER 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_GluTAlignmentBuilder)
 	%          >> result  = run(mlarbelaez_unittest.Test_GluTAlignmentBuilder, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 18-Oct-2015 00:39:02
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
        sessionFolder = 'p7991_JJL'
 		sessionPath
 		testObj
 	end

	methods (Test)
        function test_concatXfms(this)
            bldr  = mlarbelaez.GluTAlignmentBuilder(this.sessionPath);
            xfm21 = fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan2_pass3_on_atlas_scan1_pass3.mat');
            bldr  = bldr.set_hoXfms( ...
                    fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan1_pass3_on_atlas_scan2_pass3.mat'), 'scan', 1);
            xfm   = bldr.concatXfms({xfm21 bldr.get_hoXfms('scan', 1)});
            bldr  = bldr.set_hoXfms(xfm, 'scan', 1);
            this.verifyEqual(bldr.get_hoXfms('scan', 1), fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan2_pass3_on_atlas_scan2_pass3.mat'));
        end
 	end

 	methods (TestClassSetup)
 		function setupGluTAlignmentBuilder(this)
 			import mlarbelaez.*;
            this.sessionPath = fullfile(getenv('MLUNIT_TEST_PATH'), 'Arbelaez', 'GluT', this.sessionFolder);
 			this.testObj = GluTAlignmentBuilder('sessionPath', this.sessionPath);
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

