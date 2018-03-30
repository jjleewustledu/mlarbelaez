classdef Test_FourCompartmentsSimulator < matlab.unittest.TestCase 
	%% TEST_FOURCOMPARTMENTSSIMULATOR  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_FourCompartmentsSimulator)
 	%          >> result  = run(mlarbelaez_unittest.Test_FourCompartmentsSimulator, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 

	properties 
        unittest_home = '/Volumes/PassportStudio2/Arbelaez/GluT/jjlee/np15/p5661'
 		testObj 
 	end 

	methods (Test) 
 		function test_plot(this)
            this.testObj.plot;
        end 
        function test_varyParameters(this)
            this.testObj.varyParameters('k21');
        end
        function test_loadSession(this)            
            import mlpet.* mlarbelaez.*;
            dta_  = DTA.load('p5661g.dta');
            tsc_  = TSC.import('p5661wb.tsc');
 			obj   = FourCompartmentsSimulator(dta_, tsc_);
            this.assertEqual(this.testObj, obj);
        end
 	end 

 	methods (TestClassSetup) 
 		function setupFourCompartmentsSimulator(this) 
            cd(this.unittest_home);
            import mlpet.* mlarbelaez.*;
            dta_ = DTA.load('p5661g.dta');
            tsc_ = TSC.import('p5661wb.tsc');
 			this.testObj = FourCompartmentsSimulator(dta_, tsc_);
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

