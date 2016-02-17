classdef GluTAlignmentBuilder 
	%% GLUTALIGNMENTBUILDER  

	%  $Revision$
 	%  was created 18-Oct-2015 00:39:02
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties (Constant)
        ALWAYS_SAVE = false
    end

    properties 
        product        % needed by FlirtVisitor
        referenceImage % "
        sourceImage    % "
        xfm            % "
        sourceWeight
        referenceWeight
    end
    
	properties (Dependent)
        sessionPath
        pnumber        
        mprage
    end 
    
    methods % GET/SET
        function g = get.sessionPath(this)
            g = this.sessionPath_;
        end
        function g = get.pnumber(this)
            g = this.registry_.str2pnum(this.sessionPath);
        end        
        function g = get.mprage(this)
            g = this.mprage_;
        end        
        function this = set.mprage(this, s)
            assert(isa(s, 'mlfourd.ImagingContext'));
            assert(lexist(s.fqfilename));
            this.mprage_ = s;
        end
        
        
        function tr = get_tr(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            tr = this.tr_{ip.Results.scan};
        end
        function oc = get_oc(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            oc = this.oc_{ip.Results.scan};
        end
        function ho = get_ho(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            ho = this.ho_{ip.Results.scan};
        end
        function gluc = get_gluc(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            gluc = this.gluc_{ip.Results.scan};
        end
        
        function this = set_tr(this, tr, varargin)
            ip = inputParser;
            addRequired( ip, 'tr', @(x) isa(x, 'mlfourd.ImagingContext'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, tr, varargin{:});
            
            this.tr_{ip.Results.scan} = tr;
        end
        function this = set_oc(this, oc, varargin)
            ip = inputParser;
            addRequired( ip, 'oc', @(x) isa(x, 'mlfourd.ImagingContext'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, oc, varargin{:});
            
            this.oc_{ip.Results.scan} = oc;
        end
        function this = set_ho(this, ho, varargin)
            ip = inputParser;
            addRequired( ip, 'ho', @(x) isa(x, 'mlfourd.ImagingContext'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, ho, varargin{:});
            
            this.ho_{ip.Results.scan} = ho;
        end
        function this = set_gluc(this, gluc, varargin)
            ip = inputParser;
            addRequired( ip, 'gluc', @(x) isa(x, 'mlfourd.ImagingContext'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, gluc, varargin{:});
            
            this.gluc_{ip.Results.scan} = gluc;
        end
        
                
        function g = get_mprageXfms(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            g = this.mprageXfms_{ip.Results.scan};
        end
        function g = get_ocXfms(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            g = this.ocXfms_{ip.Results.scan};
        end
        function g = get_hoXfms(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            g = this.hoXfms_{ip.Results.scan};
        end
        function g = get_glucXfms(this, varargin)
            ip = inputParser;
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, varargin{:});
            
            g = this.glucXfms_{ip.Results.scan};
        end
        
        function this = set_mprageXfms(this, mprage, varargin)
            ip = inputParser;
            addRequired( ip, 'mprage', @(x) lexist(x, 'file'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, mprage, varargin{:});
            
            this.ocXfms_{ip.Results.scan} = ip.Results.mprage;
        end
        function this = set_ocXfms(this, oc, varargin)
            ip = inputParser;
            addRequired( ip, 'oc', @(x) lexist(x, 'file'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, oc, varargin{:});
            
            this.ocXfms_{ip.Results.scan} = ip.Results.oc;
        end
        function this = set_hoXfms(this, ho, varargin)
            ip = inputParser;
            addRequired( ip, 'ho', @(x) lexist(x, 'file'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, ho, varargin{:});
            
            this.hoXfms_{ip.Results.scan} = ip.Results.ho;
        end
        function this = set_glucXfms(this, gluc, varargin)
            ip = inputParser;
            addRequired( ip, 'gluc', @(x) lexist(x, 'file'));
            addParameter(ip, 'scan', 1, @isnumeric);
            parse(ip, gluc, varargin{:});
            
            this.glucXfms_{ip.Results.scan} = ip.Results.gluc;
        end      
    end
    
    methods (Static)
        function this = loadUntouched(varargin)
            this = mlarbelaez.GluTAlignmentBuilder(varargin{:});
        end
        function this = loadTouched(varargin)
            import mlfourd.*;
            this = mlarbelaez.GluTAlignmentBuilder(varargin{:});
            for s = 1:2
                this.tr_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%str%i.nii.gz', this.pnumber, s)));
                this.oc_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%soc%i_141414fwhh.nii.gz', this.pnumber, s)));
                this.ho_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%sho%i_454552fwhh.nii.gz', this.pnumber, s)));
                this.gluc_{s} = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%sgluc%i_454552fwhh_mcf.nii.gz', this.pnumber, s)));
                this.hoXfms_{s} = ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('001_on_%sho%i_sumt.mat', this.pnumber, s));
                this.glucXfms_{s} = ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('001_on_%sgluc%i_sumt.mat', this.pnumber, s));
            end
            this.mprage_ = ImagingContext( ...
                           fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('001_on_%satlas_session.nii.gz', this.pnumber)));  
            this.ocXfms_{1} = ...
                           fullfile(this.sessionPath, 'PET', sprintf('001_on_atlas_scan1_pass3.mat'));
            this.ocXfms_{2} = ...
                           fullfile(this.sessionPath, 'PET', sprintf('001_on_%satlas_session.mat', this.pnumber));
        end
    end
    
    methods
        function ic  = add(this, fprefix, varargin)
            import mlfourd.*;
            ic  = this.squeezeTime(varargin{1});
            img = zeros(ic.niftid.size);
            for v = 1:length(varargin)
                try
                    ic = this.squeezeTime(varargin{v});
                    img  = img + double(ic.niftid.img);
                catch ME
                    handexcept(ME);
                end
            end
            niid = varargin{1}.niftid;
            niid.img = img;
            niid.fileprefix = fprefix;
            niid.save;
            ic = ImagingContext(niid);
        end
        function ic  = squeezeTime(~, ic)
            %% SQUEEZETIME will change both input/output because they are handle objects
            
            import mlfourd.*;
            assert(isa(ic, 'mlfourd.ImagingContext'));
            niid = ic.niftid;
            if (niid.rank > 3)
                ndec = DynamicNIfTId(niid, 'timeSum', true);
                ic = ImagingContext(ndec.component);
            end
        end
        function ic  = motionCorrect(this, ic, icRef)
            import mlfourd.* mlpet.*;
            this.ensureSaved(ic);
            this.ensureSaved(icRef);
            ndec = DynamicNIfTId(ic.niftid);
            ndec = ndec.mcflirtedAfterBlur(PETRegistry.instance.petPointSpread, 'reffile', icRef.fqfilename);
            %ndec = ndec.withRevertedFrames(ic.niftid, 1:5);
            ic = ImagingContext(ndec.component);
        end
        function xfm = flirtPET(this, ic, icRef)
            import mlfourd.* mlpet.*;
            this.ensureSaved(ic);
            this.ensureSaved(icRef);
            ic                  = this.squeezeTime(ic);
            bniid               = BlurringNIfTId(ic.niftid,    'blur', PETRegistry.instance.petPointSpread);
            ic                  = ImagingContext(bniid.component);
            bniidRef            = BlurringNIfTId(icRef.niftid, 'blur', PETRegistry.instance.petPointSpread);
            icRef               = ImagingContext(bniidRef.component);
            this.sourceImage    = ic;
            this.referenceImage = icRef;
            this.sourceWeight       = this.createWeight(ic);   
            this.referenceWeight      = this.createWeight(icRef);            
            visit               = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            [~,xfm]             = visit.alignSmallAnglesGluT(this);
        end
        function xfm = flirtMultimodal(this, ic, icRef)
            this.ensureSaved(ic);
            this.ensureSaved(icRef);
            this.sourceImage    = this.squeezeTime(ic);
            this.referenceImage = icRef; 
            this.sourceWeight       = [];   
            this.referenceWeight      = [];
            visit               = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            [~,xfm]             = visit.alignMultispectral(this);
        end
        function ic  = applyXfm(this, xfm, ic, icRef)
            this.ensureSaved(ic);
            this.ensureSaved(icRef);
            this.xfm            = xfm;          
            this.sourceImage    = ic;
            this.referenceImage = icRef;
            visit               = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            this                = visit.transformGluT(this);
            ic                  = this.product;
        end
        function ic  = applyXfmNN(this, xfm, ic, icRef)
            this.ensureSaved(ic);
            this.ensureSaved(icRef);
            this.xfm            = xfm;          
            this.sourceImage    = ic;
            this.referenceImage = icRef;
            visit               = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            this                = visit.transformNearestNeighbor(this);
            ic                  = this.product;
        end
        function xfm = invertXfm(this, xfm)
            assert(lexist(xfm, 'file'));
            this.xfm = xfm;
            visit    = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            this     = visit.invertTransform(this);
            xfm      = this.xfm;
        end
        function xfm = concatXfms(this, xfms)
            %% CONCATXFMS 
            %  Usage: xfms = {<mat_AtoB> <mat_BtoC> <mat_CtoD>}
            %         builder = this.visitConcatXfm(builder, xfms)
            %         builder.xfm will contain <mat_AtoD>
            
            assert(iscell(xfms));
            visit = mlfsl.FlirtVisitor('sessionPath', this.sessionPath);
            this  = visit.concatTransforms(this, xfms); 
            xfm   = this.xfm;
        end
        
 		function this = GluTAlignmentBuilder(varargin)
 			%% GLUTALIGNMENTBUILDER
 			%  Usage:  this = GluTAlignmentBuilder()

            ip = inputParser;
            addOptional(ip, 'sessionPath', pwd, @isdir);
            parse(ip, varargin{:});
            
            this.registry_    = mlarbelaez.ArbelaezRegistry.instance;
            this.sessionPath_ = ip.Results.sessionPath;
            
            import mlfourd.*;
            for s = 1:2
                this.tr_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%str%i.nii.gz', this.pnumber, s)));
                this.oc_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%soc%i.nii.gz', this.pnumber, s)));
                this.ho_{s}   = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%sho%i.nii.gz', this.pnumber, s)));
                this.gluc_{s} = ImagingContext( ...
                                fullfile(this.sessionPath, 'PET', sprintf('scan%i', s), sprintf('%sgluc%i.nii.gz', this.pnumber, s)));
            end
            this.mprage_ = ImagingContext( ...
                           fullfile(this.sessionPath, 'rois', '001.nii.gz'));
                 
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        registry_
        sessionPath_
        tr_
        oc_
        ho_
        gluc_        
        mprage_
        mprageXfms_
        ocXfms_
        hoXfms_
        glucXfms_
    end
    
    methods (Access = 'private')
        function      ensureSaved(this, ic)
            if (~lexist(ic.fqfilename, 'file') || this.ALWAYS_SAVE)
                ic.niftid;
                ic.save;
            end
        end
        function ic = createWeight(~, ic)
            niid                   = ic.niftid;
            sz                     = niid.size;
            img                    = ones(sz);
            img(:,:,1:4)           = zeros(sz(1), sz(2), 4);
            img(:,:,sz(3)-1:sz(3)) = zeros(sz(1), sz(2), 2);
            niid.img               = img;
            niid.fileprefix        = 'GluTAlignmentBuilder_createInweight';
            niid.save;
            ic                     = mlfourd.ImagingContext(niid);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

