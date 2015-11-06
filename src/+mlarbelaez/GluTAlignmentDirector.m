classdef GluTAlignmentDirector 
	%% GLUTALIGNMENTDIRECTOR  

	%  $Revision$
 	%  was created 16-Oct-2015 23:38:20
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
	properties (Dependent) 	
        sessionPath
        sessionAtlas
        sessionAnatomy
        sessionAtlasFilename
        sessionAnatomyFilename
        atlasCheckpointFilename
        anatomyCheckpointFilename
        
        builder
        header
        data 		
    end

    methods % GET
        function g = get.builder(this)
            g = this.builder_;
        end
        function g = get.sessionAtlas(this)
            g = this.sessionAtlas_;
        end
        function g = get.sessionAnatomy(this)
            g = this.sessionAnatomy_;
        end
        function g = get.sessionPath(this)
            g = this.builder_.sessionPath;
        end
        function g = get.sessionAtlasFilename(this)
            if (~isempty(this.sessionAtlasFilename_))
                g = this.sessionAtlasFilename_;
                return
            end
            g = fullfile(this.sessionPath, 'PET', ...
                         sprintf('%satlas_session.nii.gz', this.builder_.pnumber));
        end
        function g = get.sessionAnatomyFilename(this)
            if (~isempty(this.sessionAnatomyFilename_))
                g = this.sessionAnatomyFilename_;
                return
            end
            g = fullfile(this.sessionPath, 'PET', ...
                         sprintf('%smpr_session.nii.gz', this.builder_.pnumber));
        end
        function g = get.atlasCheckpointFilename(this)
            g = fullfile(this.sessionPath, 'GlutAlignmentDirector.directBuildingSessionAtlas_checkpoint.mat');
        end
        function g = get.anatomyCheckpointFilename(this)
            g = fullfile(this.sessionPath, 'GlutAlignmentDirector.directBuildingSessionAnatomy_checkpoint.mat');
        end
    end
    
    methods (Static)
        function this = createAllAligned(sessPth)
            import mlarbelaez.*;
            this = GluTAlignmentDirector(GluTAlignmentBuilder.loadUntouched(sessPth));             
            this = this.ensureSessionAtlas(this.sessionAtlasFilename);
            this = this.ensureSessionAnatomy(this.sessionAnatomyFilename);         
        end
        function this = loadUntouched(varargin)
            import mlarbelaez.*;
            this = GluTAlignmentDirector(GluTAlignmentBuilder.loadUntouched(varargin{:}));
        end
        function this = loadTouched(varargin)
            import mlarbelaez.*;
            this = GluTAlignmentDirector(GluTAlignmentBuilder.loadTouched(varargin{:}));
        end
    end
    
	methods        
        function p = str2pnum(this, str)
            p = this.registry_.str2pnum(str);
        end
        function s = str2sidx(this, str)
            s = this.registry_.str2sidx(str);
        end
        
        function regionOnPet = alignRegion(this, region, petTarg, varargin)
            %  Usage:  aligned = this.alignRegion(region, pet_target[, 'fslview'/'freeview'])
            %                                     ^ ImagingContext object for mask on MR anatomy or string
            %                                       or support string ('thalamus' 'amygdala', etc.)
            %                                             ^ ImagingContext object for the target PET image data
            %    ^ ImagingContext object for aligned region mask
            
            ip = inputParser;
            addRequired(ip, 'region',  @(x) ischar(x) || isa(x, 'mlfourd.ImagingContext'));
            addRequired(ip, 'petTarg', @(x) isa(x, 'mlfourd.ImagingContext'));
            addOptional(ip, 'viewer',  '', @ischar);
            parse(ip, region, petTarg, varargin{:});
            
            import mlfourd.*;            
            ic  = this.regionImagingContext(region, mlpet.PETRegistry.instance.petPointSpread);
            xfm = this.findXfmForTarget(petTarg);
            regionOnPet = this.builder_.applyXfmNN(xfm, ic, petTarg);
            if (~isempty(ip.Results.viewer))
                if (lstrfind(ip.Results.viewer, 'fsl'))
                    petTarg.niftid.fslview(regionOnPet.fqfilename);
                else                    
                    petTarg.niftid.freeview(regionOnPet.fqfilename);
                end
            end
        end
        function ic   = regionImagingContext(this, fp, varargin)
            ip = inputParser;
            addRequired(ip, 'fp',       @ischar);
            addOptional(ip, 'blur', [], @isnumeric); 
            parse(ip, fp, varargin{:});
            
            assert(ischar(fp));
            if (lstrfind(fp, 'amygdala'))
                fp = '001-amygdala';
                ic = mlfourd.ImagingContext(fullfile(this.sessionPath, 'rois', [fp '_454552fwhh.nii.gz']));
                return
            end
            if (lstrfind(fp, 'hippocampus'))
                fp = '001-hippocampus';
                ic = mlfourd.ImagingContext(fullfile(this.sessionPath, 'rois', [fp '_454552fwhh.nii.gz']));
                return
            end
            if (lstrfind(fp, 'hypothalamus'))
                fp = '001-large-hypothalamus';
                ic = mlfourd.ImagingContext(fullfile(this.sessionPath, 'rois', [fp '_454552fwhh.nii.gz']));
                return
            end
            if (lstrfind(fp, 'large-hypothalamus'))
                fp = '001-large-hypothalamus';
                ic = mlfourd.ImagingContext(fullfile(this.sessionPath, 'rois', [fp '_454552fwhh.nii.gz']));
                return
            end
            if (lstrfind(fp, 'thalamus'))
                fp = '001-thalamus';
                ic = mlfourd.ImagingContext(fullfile(this.sessionPath, 'rois', [fp '_454552fwhh.nii.gz']));
                return
            end
            
            %if (~isempty(ip.Results.blur))
            %    ic = this.blurThenBinarize(ic, ip.Results.blur);
            %end
        end
        function xfm  = findXfmForTarget(this, petTarg)
            assert(isa(petTarg, 'mlfourd.ImagingContext'));
            if (lstrfind(petTarg.fileprefix, 'ho1'))
                xfm = sprintf('001_on_%sho1_sumt.mat', this.builder_.pnumber);
            end
            if (lstrfind(petTarg.fileprefix, 'ho2'))
                xfm = sprintf('001_on_%sho2_sumt.mat', this.builder_.pnumber);
            end
            if (lstrfind(petTarg.fileprefix, 'gluc1'))
                xfm = sprintf('001_on_%sgluc1_sumt.mat', this.builder_.pnumber);
            end
            if (lstrfind(petTarg.fileprefix, 'gluc2'))
                xfm = sprintf('001_on_%sgluc2_sumt.mat', this.builder_.pnumber);
            end
            if (lstrfind(petTarg.fileprefix, 'oc1'))
                xfm = '001_on_atlas_scan1_pass3.mat';
            end
            if (lstrfind(petTarg.fileprefix, 'oc2'))
                xfm = sprintf('001_on_%satlas_session.mat', this.builder_.pnumber);
            end
            xfm = fullfile(this.sessionPath, 'PET', xfm);
        end
        function vec  = regionDynamicSampling(this, region, petTarg, varargin)
            %  Usage:  vector = this.regionDynamicSampling( ...
            %                        region, pet_target[, 'fslview'/'freeview'])
            %                        ^ ImagingContext object for mask on MR anatomy or string
            %                          or support string ('thalamus' 'amygdala', etc.)
            %                                ^ ImagingContext object for the target PET image data
            %          ^ numeric vector in time
            
            ip = inputParser;
            addRequired(ip, 'region',  @(x) ischar(x) || isa(x, 'mlfourd.ImagingContext'));
            addRequired(ip, 'petTarg', @(x) isa(x, 'mlfourd.ImagingContext'));
            addOptional(ip, 'viewer',  '', @ischar);
            parse(ip, region, petTarg, varargin{:});
            
            regionOnPet = this.alignRegion(region, petTarg, varargin{:});
            assert    (petTarg.niftid.rank == 4);
            assert(regionOnPet.niftid.rank == 3);
            duration    = size(petTarg.niftid, 4);
            regionImg   = regionOnPet.niftid.img;
            petImg      = petTarg.niftid.img;
            
            vec = zeros(duration,1);
            for t = 1:duration
                petVol = petImg(:,:,:,t);
                vec(t) = sum(sum(sum(petVol(regionImg > eps))));
            end
        end
        function this = ensureSessionAtlas(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfn', this.sessionAtlasFilename, @ischar);
            parse(ip, varargin{:});
            
            this.sessionAtlasFilename_ = ip.Results.fqfn;
            this = this.directBuildingSessionAtlas;
        end 
        function this = ensureSessionAnatomy(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfn', this.sessionAnatomyFilename, @ischar);
            parse(ip, varargin{:});
            
            this = this.ensureSessionAtlas;
            
            this.sessionAnatomyFilename_ = ip.Results.fqfn;
            this = this.directBuildingSessionAnatomy;
        end        
        
 		function this = GluTAlignmentDirector(bldr)
 			%% GLUTALIGNMENTDIRECTOR
 			%  Usage:  this = GluTAlignmentDirector(GluTAlignmentBuilder_object)

            assert(isa(bldr, 'mlarbelaez.GluTAlignmentBuilder'));
            this.builder_  = bldr;
            if (lexist(this.sessionAtlasFilename))
                this.sessionAtlas_ = mlfourd.ImagingContext(this.sessionAtlasFilename);
                %load(this.atlasCheckpointFilename);
            end
            if (lexist(this.sessionAnatomyFilename))
                this.sessionAnatomy_ = mlfourd.ImagingContext(this.sessionAnatomyFilename);
                %load(this.anatomyCheckpointFilename);
            end
 		end
 	end 

    %% PRIVATE
    
    properties (Access = 'private')
        builder_
        sessionAtlasFilename_
        sessionAtlas_
        sessionAnatomyFilename_
        sessionAnatomy_
    end

    methods (Access = 'private')
        function this = directBuildingSessionAtlas(this)
            import mlfourd.*;            
                        
            % align session PET scans
            [tr,oc,ho,gluc] = this.get_tohg;            
            [this,tr,oc,ho,gluc,atlas] = this.align_tohg(tr, oc, ho, gluc);
            this = this.set_tohg(tr, oc, ho, gluc);
            
            % assemble session PET atlas
            this.sessionAtlas_ = this.builder_.add( ...
                                 gzfileparts(this.sessionAtlasFilename), atlas{1}, atlas{2});
            this.sessionAtlas_.fqfilename = this.sessionAtlasFilename;
            this.sessionAtlas_.save;     
            
            this.checkSanitySessionAtlas(tr, oc, ho, gluc);
            %save(this.atlasCheckpointFilename, 'this');
        end
        function [t,o,h,g] = get_tohg(this)
            bldr = this.builder_;
            for s = 1:2
                t{s} = bldr.get_tr(  'scan', s);
                o{s} = bldr.get_oc(  'scan', s);
                h{s} = bldr.get_ho(  'scan', s);
                g{s} = bldr.get_gluc('scan', s);
            end
        end
        function [this,tr,oc,ho,gluc,atlas] = align_tohg(this, tr, oc, ho, gluc)
            bldr      = this.builder_;
            atlas     = cell(size(tr));
            xfm_pass1 = cell(size(tr));
            xfm_1ssap = cell(size(tr));
            xfm_pass2 = cell(size(tr));
            xfm_2ssap = cell(size(tr));
            
            % align each scan
            for s = 2:-1:1                

                % aufbau atlas_pass1 for ho
                ho_sumt      = bldr.squeezeTime(ho{s});
                atlas{s}     = bldr.add( ...
                               sprintf('atlas_scan%i_pass1', s), tr{s}, oc{s}, ho_sumt); % 1st pass
                ho{s}        = bldr.motionCorrect(ho{s}, ho_sumt); % align dynamic ho
                xfm_pass1{s} = bldr.flirtPET(ho_sumt, atlas{s});
                ho{s}        = bldr.applyXfm(xfm_pass1{s}, ho{s}, atlas{s});               
                atlas{s}     = bldr.add( ...
                               sprintf('atlas_scan%i_pass2', s), tr{s}, oc{s}, ho{s}); % rebuild with aligned ho
                        
                % adjust inverse-xfms for atlas_pass1 for ho                
                xfm_1ssap{s} = bldr.invertXfm(xfm_pass1{s});                 
                bldr         = bldr.set_hoXfms(xfm_1ssap{s}, 'scan', s);
                
                % aufbau atlas_pass2 for gluc
                gluc_sumt    = bldr.squeezeTime(gluc{s});
                gluc{s}      = bldr.motionCorrect(gluc{s}, gluc_sumt); % align dynamic gluc
                xfm_pass2{s} = bldr.flirtPET(gluc_sumt, atlas{s});
                gluc{s}      = bldr.applyXfm(xfm_pass2{s}, gluc{s}, atlas{s});
                atlas{s}     = bldr.add( ...
                               sprintf('atlas_scan%i_pass3', s), atlas{s}, gluc{s}); % rebuild with gluc  
                
                % adjust inverse-xfms for atlas_pass2 for gluc                
                xfm_2ssap{s} = bldr.invertXfm(xfm_pass2{s});                 
                bldr         = bldr.set_glucXfms(xfm_2ssap{s}, 'scan', s);
                                 
            end            

            % align euglycemia images to hypoglycemia images       
            xfm12    = bldr.flirtPET(atlas{1}, atlas{2}); % in atlas{1} ref atlas{2}
            tr{1}    = bldr.applyXfm(xfm12, tr{1},   atlas{2});
            oc{1}    = bldr.applyXfm(xfm12, oc{1},   atlas{2});
            ho{1}    = bldr.applyXfm(xfm12, ho{1},   atlas{2});
            gluc{1}  = bldr.applyXfm(xfm12, gluc{1}, atlas{2});
            atlas{1} = bldr.applyXfm(xfm12, atlas{1},atlas{2}); % atlas{1} and atlas{2} available for high SNR sum
            
            % adjust inverse-xfms for euglycemia images
            xfm21 = bldr.invertXfm(xfm12);            
            bldr  = bldr.set_ocXfms( xfm21, 'scan', 1);
            bldr  = bldr.set_hoXfms( ...
                    bldr.concatXfms({xfm21 bldr.get_hoXfms(  'scan', 1)}), 'scan', 1); 
            bldr  = bldr.set_glucXfms( ...
                    bldr.concatXfms({xfm21 bldr.get_glucXfms('scan', 1)}), 'scan', 1);
            
            this.builder_ = bldr;
        end
        function this = set_tohg(this, t, o, h, g)
            bldr = this.builder_;
            for s = 1:2
                bldr = bldr.set_tr(  t{s}, 'scan', s);
                bldr = bldr.set_oc(  o{s}, 'scan', s);
                bldr = bldr.set_ho(  h{s}, 'scan', s);
                bldr = bldr.set_gluc(g{s}, 'scan', s);
            end
            this.builder_ = bldr;
        end
        function this = checkSanitySessionAtlas(this, varargin)
            for s = 1:2
                for v = 1:length(varargin)
                    assert(lexist(varargin{v}{s}.fqfilename, 'file'));  
                end
            end
        end        
        
        function this = directBuildingSessionAnatomy(this)
            import mlfourd.*;
            
            % align session anatomy, xfms
            [mpr,oxfms,hxfms,gxfms] = this.get_mohg;
            [this,mpr,oxfms,hxfms,gxfms] = this.align_mprage(mpr,oxfms,hxfms,gxfms);
            this = this.set_mohg(mpr, oxfms, hxfms, gxfms);
            
            % assemble session anatomy
            this.sessionAnatomy_ = mpr;
            this.sessionAnatomy_.fqfilename = this.sessionAnatomyFilename;
            this.sessionAnatomy_.save;
            
            this.checkSanitySessionAnatomy
            %save(this.anatomyCheckpointFilename, 'this');
        end
        function [m,o,h,g] = get_mohg(this)
            bldr = this.builder_;
            m = bldr.mprage;
            o{1} = bldr.get_ocXfms(  'scan', 1);
            for s = 1:2
                h{s} = bldr.get_hoXfms(  'scan', s);
                g{s} = bldr.get_glucXfms('scan', s);
            end
        end
        function [this,mpr,oxfms,hxfms,gxfms] = align_mprage(this, mpr, oxfms, hxfms, gxfms)
            bldr = this.builder_;
            
            % align low information image to high information image, then invert xfm;
            % viz., align anatomy to session atlas for PET
            p2m_xfm = bldr.flirtMultimodal(this.sessionAtlas_, mpr);
            m2p_xfm = bldr.invertXfm(p2m_xfm);
            mpr     = bldr.applyXfm(m2p_xfm, mpr, this.sessionAtlas_);
            
            % align anatomy to oc, ho, gluc by concatention of xfms
            oxfms{1} = bldr.concatXfms({m2p_xfm oxfms{1}});
            for s = 1:2
                hxfms{s} = bldr.concatXfms({m2p_xfm hxfms{s}});
                gxfms{s} = bldr.concatXfms({m2p_xfm gxfms{s}});
            end
            
            this.builder_ = bldr;
        end
        function [this,mpr,oxfms,hxfms,gxfms] = align_mprage_direct(this, mpr, oxfms, hxfms, gxfms)
            bldr = this.builder_;
            
            % directly align anatomy to session atlas for PET
            m2p_xfm = bldr.flirtMultimodal(mpr, this.sessionAtlas_);
            mpr     = bldr.applyXfm(m2p_xfm, mpr, this.sessionAtlas_);
            
            % align anatomy to oc, ho, gluc by concatention of xfms
            oxfms{1} = bldr.concatXfms({m2p_xfm oxfms{1}});
            for s = 1:2
                hxfms{s} = bldr.concatXfms({m2p_xfm hxfms{s}});
                gxfms{s} = bldr.concatXfms({m2p_xfm gxfms{s}});
            end
            
            this.builder_ = bldr;
        end
        function this = set_mohg(this, m, o, h, g)
            bldr = this.builder_;            
            bldr.mprage = m;  
            bldr = bldr.set_ocXfms(  o{1}, 'scan', 1);
            for s = 1:2
                bldr = bldr.set_hoXfms(  h{s}, 'scan', s);
                bldr = bldr.set_glucXfms(g{s}, 'scan', s);
            end
            this.builder_ = bldr;
        end
        function this = checkSanitySessionAnatomy(this)
            assert(lexist(this.builder_.mprage.fqfilename));
            assert(lexist(this.builder_.get_ocXfms( 'scan', 1)));
            for s = 1:2
                assert(lexist(this.builder_.get_hoXfms(  'scan', s)));
                assert(lexist(this.builder_.get_glucXfms('scan', s)));
            end
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

