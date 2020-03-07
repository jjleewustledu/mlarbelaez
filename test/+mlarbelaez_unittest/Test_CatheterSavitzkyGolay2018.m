classdef Test_CatheterSavitzkyGolay2018 < matlab.unittest.TestCase
	%% TEST_CATHETERSAVITZKYGOLAY2018 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_CatheterSavitzkyGolay2018)
 	%          >> result  = run(mlarbelaez_unittest.Test_CatheterSavitzkyGolay2018, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 26-Aug-2018 00:39:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        dataDir = fullfile(getenv('HOME'), 'MATLAB-Drive/mlarbelaez/data')
        degree = 19
 		registry
        span = 127
        testNum = 6
 		testObj
        workDir = fullfile(getenv('HOME'), 'MATLAB-Drive/mlarbelaez/test/+mlarbelaez_unittest')
    end
    
    properties (Dependent)
        AMAtestfile
    end
    
    methods
        
        %% GET
        
        function g = get.AMAtestfile(this)
            g = sprintf('AMAtest%i.crv', this.testNum);
        end
    end

	methods (Test)
		function test_ctor(this)
            disp(this.testObj)
 		end
        function test_exploreSmoothed(this)
%            this.testObj.exploreSmoothed([63 95 109 119 127], this.degree);
            
            this.testObj.exploreSmoothed([15 23 33 43 53 63], [5 9 13]);
            this.testObj.exploreSmoothed([25 33 43 53 63 73], [11 15 19]); 
            this.testObj.exploreSmoothed([35 43 53 63 73 83], [17 23 31]); 
        end
        function test_exploreKernels(this)
 %           this.testObj.exploreKernels([63 95 109 119 127], this.degree);
            
            this.testObj.exploreKernels([15 23 33 43 53 63], [5 9 13]);
            this.testObj.exploreKernels([25 33 43 53 63 73], [11 15 19]);
            this.testObj.exploreKernels([35 43 53 63 73 83], [17 23 31]); 
        end
        function test_exploreKernel(this)
            this.testObj.exploreKernels(this.span, this.degree);
        end
        function test_plots(this)
            testNum_ = [4 5 6 7];
            for f = 1:length(testNum_)
                crv = mlpet.CRV.load(fullfile(this.dataDir, sprintf('AMAtest%i.crv', testNum_(f))));
                testobj = mlarbelaez.CatheterSavitzkyGolay2018(crv, 'span', this.span, 'degree', this.degree);
                figure; 
                plot(testobj);
            end
        end
        function test_plot(this)
            crv = mlpet.CRV.load(fullfile(this.dataDir, sprintf('AMAtest%i.crv', this.testNum)));
            testobj = mlarbelaez.CatheterSavitzkyGolay2018(crv, 'span', this.span, 'degree', this.degree);
            figure; 
            plot(testobj);
        end
        function test_recoveredCrv(this)            
            crv     = mlpet.CRV.load(fullfile(this.dataDir, sprintf('AMAtest%i.crv', this.testNum)));
            testobj = mlarbelaez.CatheterSavitzkyGolay2018(crv, 'span', this.span, 'degree', this.degree);
            K       = testobj.kernel;
            t       = 0:length(K)-1; 
            
            decayingH = testobj.decayingHeavi(length(K));
            recCrv    = testobj.recoveredCrv;
            recCrv    = recCrv * max(crv.counts) / max(recCrv);
            dcCrv     = recCrv .* testobj.decayCorrection(length(K));
            figure;
            plot(t, K         * max(dcCrv) / max(K), ...
                 t, decayingH * max(dcCrv) / max(decayingH), ...
                 crv.times, crv.counts, ...
                 t, recCrv, ...
                 t, dcCrv);
        end
        function test_save(this)
            plot(this.testObj.kernel);
            save(this.testObj);
            saveas(this.testObj, fullfile(this.dataDir, 'kernelBest.mat'));
        end
	end

 	methods (TestClassSetup)
		function setupCatheterSavitzkyGolay2018(this)
 			import mlarbelaez.*;
            cd(this.workDir);
 			this.testObj_ = CatheterSavitzkyGolay2018(fullfile(this.dataDir, this.AMAtestfile));
 		end
	end

 	methods (TestMethodSetup)
		function setupCatheterSavitzkyGolay2018Test(this)
 			this.testObj = this.testObj_;
 			this.addTeardown(@this.cleanTestMethod);
 		end
	end

	properties (Access = private)
 		testObj_
 	end

	methods (Access = private)
		function cleanTestMethod(this)
 		end
	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

