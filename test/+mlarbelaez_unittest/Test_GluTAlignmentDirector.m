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
        extended = true
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
        function test_alignedRegion(this)
            regionIC = this.testObj.alignRegion(this.regionFilename);
            regionIC.niftid.fslview(this.mprFilename);
        end
        function test_alignAnat(this)
            xfmFromAnat = this.testObj.alignAnat(this.mprFilename, this.testObj.sessionAtlas);
            this.verifyTrue(lexist(xfmFromAnat, 'file'));
        end
        function test_viewSessionAtlas(this)
            if (~this.extended); return; end
            this.testObj.sessionAtlas.fslview;
        end
        function test_concatXfms(this)
            bldr  = mlarbelaez.GluTAlignmentBuilder(this.sessionPath);
            xfm21 = fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan2_pass3_on_atlas_scan1_pass3.mat');
            bldr  = bldr.set_hoXfms( ...
                    fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan1_pass3_on_atlas_scan2_pass3.mat'), 'scan', 1);
            xfm   = bldr.concatXfms({xfm21 bldr.get_hoXfms('scan', 1)});
            bldr  = bldr.set_hoXfms(xfm, 'scan', 1);
            this.verifyEqual(bldr.get_hoXfms('scan', 1), fullfile(this.sessionPath, 'PET', 'scan1', 'atlas_scan2_pass3_on_atlas_scan2_pass3.mat'));
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
 	end

 	methods (TestClassSetup)
 		function setupGluTAlignmentDirector(this)
 			import mlarbelaez.*;
            this.registry = ArbelaezRegistry.instance;
 			this.testObj  = GluTAlignmentDirector( ...
                            GluTAlignmentBuilder(this.sessionPath));
 		end
 	end

 	methods (TestClassTeardown)
 	end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

