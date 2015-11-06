classdef Test_GluTAlignmentDirector < matlab.unittest.TestCase
	%% TEST_GLUTALIGNMENTDIRECTOR 

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_GluTAlignmentDirector)
 	%          >> result  = run(mlarbelaez_unittest.Test_GluTAlignmentDirector, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$
 	%  was created 16-Oct-2015 23:38:20
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/test/+mlarbelaez_unittest.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties
        extended = false
 		registry
        scanFolder = 'scan2'
        
 		testObj
    end
    
    properties (Dependent)
        sessionPath
        sessionFolder
        sessionAtlasFilename
        sessionAnatomyFilename
        mprFilename
        regionFilename
    end
    
    methods % GET
        function g = get.sessionPath(this)
            g = this.registry.testSubjectPath;
        end
        function g = get.sessionFolder(this)
            [~,g] = fileparts(this.registry.testSubjectPath);
        end
        function g = get.sessionAtlasFilename(this)
            g = fullfile(this.sessionPath, 'PET', 'p7991atlas_session.nii.gz');
        end
        function g = get.sessionAnatomyFilename(this)
            g = fullfile(this.sessionPath, 'PET', 'p7991mpr_session.nii.gz');
        end
        function g = get.mprFilename(this)
            g = fullfile(this.sessionPath, 'rois', '001.nii.gz');
        end
        function g = get.regionFilename(this)
            g = fullfile(this.sessionPath, 'rois', '001-large-hypothalamus.nii.gz');
        end
    end

	methods (Test)
        function test_regionImagingContext(this)
            
        end
        function test_alignRegion(this)
            glucIC = this.testObj.builder.get_gluc('scan', 1);
            regionIC = this.testObj.alignRegion(this.regionFilename, glucIC);
            this.assertClass(regionIC.niftid, 'mlfourd.NIfTId');
            if (this.extended)
                regionIC.niftid.freeview;
            end
        end
        function test_sessionAnatomy(this)            
            anat = this.testObj.sessionAnatomy;
            this.verifyEqual(anat.filepath, fullfile(this.sessionPath, 'PET', ''));
            this.verifyEqual(anat.fqfilename, this.sessionAnatomyFilename);
        end
        function test_sessionAtlas(this)            
            atl = this.testObj.sessionAtlas;
            this.verifyEqual(atl.filepath, fullfile(this.sessionPath, 'PET', ''));
            this.verifyEqual(atl.fqfilename, this.sessionAtlasFilename);
        end
        function test_createAllAligned(this)
            if (~this.extended); return; end
            this.testObj = mlarbelaez.GluTAlignmentDirector.createAllAligned(this.sessionPath);
            this.assertClass(this.testObj, 'mlarbelaez.GluTAlignmentDirector');
        end
        function test_loadUntouched(this)
 			obj = mlarbelaez.GluTAlignmentDirector.loadUntouched(this.sessionPath);
            this.assertClass(obj, 'mlarbelaez.GluTAlignmentDirector');
            this.assertEqual(obj.sessionPath, this.sessionPath);
            this.assertClass(obj.sessionAtlas, 'mlfourd.ImagingContext');
            this.assertClass(obj.sessionAnatomy, 'mlfourd.ImagingContext');
            glucIC = obj.builder.get_gluc('scan', 1);
            this.assertClass(glucIC, 'mlfourd.ImagingContext');
            this.assertEqual(glucIC.fileprefix, 'p7991gluc1');
        end
        function test_loadTouched(this)
            this.assertClass(this.testObj, 'mlarbelaez.GluTAlignmentDirector');
            this.assertEqual(this.testObj.sessionPath, this.sessionPath);
            this.assertClass(this.testObj.sessionAtlas, 'mlfourd.ImagingContext');
            this.assertClass(this.testObj.sessionAnatomy, 'mlfourd.ImagingContext');
            glucIC = this.testObj.builder.get_gluc('scan', 1);
            this.assertClass(glucIC, 'mlfourd.ImagingContext');
            this.assertEqual(glucIC.fileprefix, 'p7991gluc1_454552fwhh_mcf');
        end
 	end

 	methods (TestClassSetup)
 		function setupGluTAlignmentDirector(this)
 			import mlarbelaez.*;
            this.registry = ArbelaezRegistry.instance;
 			this.testObj  = GluTAlignmentDirector.loadTouched(this.sessionPath);
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

