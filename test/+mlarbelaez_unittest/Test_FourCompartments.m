classdef Test_FourCompartments < matlab.unittest.TestCase 
	%% TEST_FOURCOMPARTMENTS  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_FourCompartments)
 	%          >> result  = run(mlarbelaez_unittest.Test_FourCompartments, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
 		 
 	end 

	methods (Test) 
 		function test_afun(this) 
 			import mlarbelaez.*; 
 		end 
 	end 

 	methods 
		  
 		function this = Test_FourCompartments(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:}); 
 		end 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

