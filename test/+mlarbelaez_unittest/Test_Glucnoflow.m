classdef Test_Glucnoflow < matlab.unittest.TestCase 
	%% TEST_GLUCNOFLOW  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_Glucnoflow)
 	%          >> result  = run(mlarbelaez_unittest.Test_Glucnoflow, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014a.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
        pnumPath 
        procPath
        tscFqfilename 
 	end 

	methods (Test) 
        function test_printTsc(this)
            gnf = mlarbelaez.Glucnoflow(this.pnumPath, 1);
            label = 'Test_Glucnoflow.test_printTsc';
            counts = gnf.plotPet(gnf.petGluc_decayCorrect, gnf.mask);
            gnf.printTsc(this.tscFqfilename, label, counts, gnf.mask);
            
            ca = mlio.TextIO.textfileToCell(this.tscFqfilename);
            this.assertTrue(strcmp('Test_Glucnoflow.test_printTsc', ca{1}));
            this.assertTrue(strcmp('    43,    3', ca{2}));
            this.assertTrue(strcmp('      3258.9        180.0      727936.19', ca{45}));
        end
    end 
    
	methods 
  		function this = Test_Glucnoflow(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:});
            this.pnumPath = fullfile(getenv('UNITTESTS'), 'Arbelaez/GluT/p8047_JJL', '');
            this.procPath = fullfile(this.pnumPath, 'jjl_proc', '');
            this.tscFqfilename = fullfile(this.procPath, 'p8047wb1.tsc');
 		end 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

