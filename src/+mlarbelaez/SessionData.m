classdef SessionData < mlpipeline.SessionData
	%% SESSIONDATA  

	%  $Revision$
 	%  was created 15-Feb-2016 02:06:04
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	

	properties (Dependent)
        aparcA2009sAseg_fqfn
        ep2d_fqfn
        gluc_fqfn
        ho_fqfn
        mpr_fqfn
        oc_fqfn
        orig_fqfn
        pet_fqfns
        petfov_fqfn
        tof_fqfn
        toffov_fqfn
        tr_fqfn
        T1_fqfn
        wmparc_fqfn
    end
    
    methods %% GET
        function g = get.aparcA2009sAseg_fqfn(this)
            g = fullfile(this.mriPath, 'aparc.a2009s+aseg.mgz');
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.ep2d_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.ep2d_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.gluc_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.gluc_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.ho_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.ho_fn(this, this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.mpr_fqfn(this)
            g = fullfile(this.fslPath, this.studyData_.mpr_fn(this));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.oc_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.oc_fn(this, this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.orig_fqfn(this)
            g = fullfile(this.mriPath, 'orig.mgz');
        end
        function g = get.pet_fqfns(this)
            fqfns = { this.fdg_fqfn this.gluc_fqfn this.ho_fqfn this.oc_fqfn this.oo_fqfn this.tr_fqfn };
            g = {};
            for f = 1:length(fqfns)
                if (2 == exist(fqfns{f}, 'file'))
                    g = [g fqfns{f}];
                end
            end
        end
        function g = get.petfov_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.petfov_fn(this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.tof_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.tof_fn(this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.toffov_fqfn(this)
            g = fullfile(this.petPath, 'fdg', 'pet_proc', this.studyData_.toffov_fn(this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.tr_fqfn(this)
            g = fullfile(this.petPath, this.studyData_.tr_fn(this, this.suffix));
            if (2 ~= exist(g, 'file'))
                g = '';
                return
            end
        end
        function g = get.T1_fqfn(this)
            g = fullfile(this.mriPath, 'T1.mgz');
        end
        function g = get.wmparc_fqfn(this)
            g = fullfile(this.mriPath, 'wmparc.mgz');
        end
    end

	methods 
        function g = aparcA2009sAseg(this)
            g = mlmr.MRImagingContext(this.aparcA2009sAseg_fqfn);
        end
        function g = ep2d(this)
            g = mlmr.MRImagingContext(this.ep2d_fqfn);
        end
        function g = gluc(this)
            g = mlpet.PETImagingContext(this.gluc_fqfn);
        end
        function g = ho(this)
            g = mlpet.PETImagingContext(this.ho_fqfn);
        end
        function g = mpr(this)
            g = mlmr.MRImagingContext(this.mpr_fqfn);
        end
        function g = oc(this)
            g = mlpet.PETImagingContext(this.oc_fqfn);
        end
        function g = orig(this)
            g = mlmr.MRImagingContext(this.orig_fqfn);
        end
        function g = petAtlas(this)
            g = mlpet.PETImagingContext(this.pet_fqfns);
            g = g.atlas;
        end
        function g = petfov(this)
            g = mlfourd.ImagingContext(this.petfov_fqfn);
        end
        function g = tof(this)
            g = mlmr.MRImagingContext(this.tof_fqfn);
        end
        function g = toffov(this)
            g = mlfourd.ImagingContext(this.toffov_fqfn);
        end
        function g = tr(this)
            g = mlpet.PETImagingContext(this.tr_fqfn);
        end
        function g = T1(this)
            g = mlmr.MRImagingContext(this.T1_fqfn);
        end
        function g = wmparc(this)
            g = mlmr.MRImagingContext(this.wmparc_fqfn);
        end
        		  
 		function this = SessionData(varargin)
 			%% SESSIONDATA
 			%  Usage:  this = SessionData()

 			this = this@mlpipeline.SessionData(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

