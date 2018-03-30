classdef DefaultModeRegions 
	%% DEFAULTMODEREGIONS  

	%  $Revision$
 	%  was created 01-Dec-2015 18:15:46
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	

	properties (Constant)
 		MPFC_IDS = [11106 12106 11107 12107]
    end
    
    properties
    end
    
    properties (Dependent)
        sessionPath
        aparcA2009s_fqfn
        mpfc_fqfn
        mpfc
    end
    
    methods %% GET
        function pth  = get.sessionPath(this)
            pth = this.sessionPath_;
        end
        function fqfn = get.aparcA2009s_fqfn(this)
            fqfn = fullfile(this.sessionPath, 'freesurfer', 'mri', 'aparc.a2009s+aseg.mgz');
        end
        function fqfn = get.mpfc_fqfn(this)
            fqfn = fullfile(this.sessionPath, 'rois', '001-mpfc_454552fwhh.nii.gz');
        end
        function nii  = get.mpfc(this)
            assert(~isa(this.mpfc_, 'mlfourd.INIfTId'));
            nii = this.mpfc_;
        end
    end

    methods (Static)
        function this = createMpfcRegion(sessPth)
            assert(lexist(sessPth, 'dir'));
            cd(sessPth);
            this = mlarbelaez.DefaultModeRegions(pwd);
            
            import mlfourd.*;
            aparcA2009s = NIfTId.load(this.aparcA2009s_fqfn);
            this.mpfc_ = MaskingNIfTId(aparcA2009s.zeros);
            for ididx = 1:length(this.MPFC_IDS)
                this.mpfc_.img = this.mpfc_.img + double(aparcA2009s.img == this.MPFC_IDS(ididx));
            end
            this.mpfc_ = this.mpfc_.binarized;
            this.mpfc_ = BlurringNIfTId(this.mpfc_, 'blur', mlpet.PETRegistry.instance.petPointSpread);
            this.mpfc_ = MaskingNIfTId(this.mpfc_);
            this.mpfc_ = this.mpfc_.thresh(0.05);
            this.mpfc_ = this.mpfc_.binarized;
            this.mpfc_.fqfilename = this.mpfc_fqfn;
            this.mpfc_.save;
        end
    end
    
	methods		  
 		function this = DefaultModeRegions(varargin)
 			%% DEFAULTMODEREGIONS
 			%  Usage:  this = DefaultModeRegions(session_path)

 			ip = inputParser;
            addOptional(ip, 'sessPth', pwd, @isdir);
            parse(ip, varargin{:});
            
            this.sessionPath_ = ip.Results.sessPth;
 		end
    end 

    %% PRIVATE
    
    properties (Access = 'private')
        sessionPath_
        mpfc_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

