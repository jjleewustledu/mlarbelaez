classdef Test_ReportingDirector < matlab.unittest.TestCase
	%% TEST_REPORTINGDIRECTOR 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_ReportingDirector)
 	%          >> result  = run(mlarbelaez_unittest.Test_ReportingDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 17-Oct-2015 12:57:01
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
 		registry
 		testObj
        xlsFileprefix = 'ReportingDirector_xlswrite'
    end
    
    properties (Dependent)        
        xlsFilename
    end
    
    methods % GET
        function g = get.xlsFilename(this)
            g = fullfile(getenv('MLUNIT_TEST_PATH'), 'Arbelaez', 'GluT', ...
                         sprintf('%s_%s.xlsx', this.xlsFileprefix, datestr(now,30)));
        end
    end

	methods (Test)
 		function test_(this)
 		end
 		function test_cohortMaps(this)
 		end
 		function test_cohortBars(this)
 		end
 		function test_cohortScatters(this)
 		end
 		function test_cohortXlsx(this)
            this.assertTrue(isa(this.testObj.cohortXlsx, 'mlarbelaez.CohortXlsx'));
            this.assertEqual(this.testObj.cohortXlsx.header{1,1}, '');
            this.assertEqual(this.testObj.cohortXlsx.data{  1,1}, []);
 		end
 		function test_xlswrite(this)
            this.testObj.xlswrite(this.xlsfilename);
            [~,~,raw] = xlsread(this.xlsfilenaem);
            this.assertEqual(raw{1,1}, '');
            this.assertEqual(raw{2,1}, []);
 		end
 	end

 	methods (TestClassSetup)
 		function setupReportingDirector(this)
 			import mlarbelaez.*;
            this.registry = UnittestRegistry;
 			this.testObj  = ReportingDirector;
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

