classdef Test_CatheterSavitzkyGolay < matlab.unittest.TestCase 
	%% TEST_CATHETERSAVITZKYGOLAY  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_CatheterSavitzkyGolay)
 	%          >> result  = run(mlarbelaez_unittest.Test_CatheterSavitzkyGolay, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 

	properties 
 		testObj 
        workDir = fullfile(getenv('HOME'), 'MATLAB-Drive/mlarbelaez/test/+mlarbelaez_unittest')
 	end 

	methods (Test) 
 		function test_deconv(this)
            figure;
            plot(this.testObj.deconv);
            hold on
            plot(smooth(this.testObj.deconv, 33, 'sgolay', 9));
            hold off
        end 
        function test_smoothedCounts(this)
            figure;
            plot(this.testObj.smoothedCounts/max(abs(this.testObj.smoothedCounts)))
        end
        function test_kernel(this)
            figure;
            plot(this.testObj.kernel/max(abs(this.testObj.kernel)))
        end
        function test_exploreSmoothed(this)
            this.testObj.exploreSmoothed([15 23 33 43 53 63], [5 9 13]);
        end
        function test_exploreKernels(this)
            this.testObj.exploreKernels([15 23 33 43 53 63], [5 9 13]);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupCatheterSavitzkyGolay(this) 
            cd(this.workDir);
 			this.testObj = mlarbelaez.CatheterSavitzkyGolay('AMAtest4.crv', 'times', 1:120);
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

