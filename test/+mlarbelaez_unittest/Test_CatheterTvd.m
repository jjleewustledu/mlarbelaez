classdef Test_CatheterTvd < matlab.unittest.TestCase 
	%% TEST_CATHETERTVD  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_CatheterTvd)
 	%          >> result  = run(mlarbelaez_unittest.Test_CatheterTvd, 'test_dt')
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
        workHome = '/Volumes/InnominateHD2/Arbelaez/deconvolution/data 2014jul17'
        crvFilename = 'AMAtest4.crv'
 	end 

	methods (Test)  		
        function test_tvdip(this)
            dccrv = mlpet.DecayCorrectedCRV.load(this.crvFilename);
            y = dccrv.counts(1:107);
            lratio = 0.002;
            lmax = this.testObj.tvdiplmax(y);
            [x, E, status] = this.testObj.tvdip(y, lratio); %#ok<ASGLU>
            
            % Plots - display original test signal y, and TVD results
            figure;
            plot(y,'-','Color',0.8*[1 1 1]);
            hold on;
            plot(x,'k-');
            hold off;
            axis tight;
            title(sprintf('Test CatheterTvd.test_tvdip: \\lambda=%5.2e, \\lambda/\\lambda_{max}=%5.2e', ...
                          lmax*lratio,lratio));
            xlabel('n');
            legend({'Input y_n','TVD x_n'});            
        end
 	end 

 	methods (TestClassSetup) 
 		function setupCatheterTvd(this) 
            cd(this.workHome);
 			this.testObj = mlarbelaez.CatheterTvd; 
 		end 
 	end 

 	methods (TestClassTeardown) 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
 end 

