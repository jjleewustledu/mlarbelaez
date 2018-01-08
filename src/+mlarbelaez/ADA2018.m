classdef ADA2018 
	%% ADA2018  

	%  $Revision$
 	%  was created 05-Jan-2018 19:26:25 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        maxCbf      = 200
        subjectsDir
 		controlsIds = {'05' '07' '09' '14' '21' '24' '29'}
        t1dmIds     = {'10' '19' '20' '22' '25' '26' '27' '28' '31'}
        t1dmGly4Ids = {'10' '19' '20'           '26' '27'      '31'}
        muCbfs
        verboseView = false
 	end

	methods 
        
        function ic = dCBF(this, id, v, gly)
            ic = mlfourd.ImagingContext( ...
                [this.fqfileprefixAaron(id, v, gly, this.cbfKind('dCBF')) '.4dfp.ifh']);
        end
        function ic = wCBFavg(this, id, v, gly)
            ic = mlfourd.ImagingContext( ...
                [this.fqfileprefixAaron(id, v, gly, 'wCBFavg') '.4dfp.ifh']);
        end
        function ic = dfnd(this, id, v, gly)
            ic = mlfourd.ImagingContext( ...
                [this.fqfileprefixAaron(id, v, gly, 'dfnd') '.4dfp.ifh']);
        end
        function ic = dfndm2(this, id, v, gly)
            ic = mlfourd.ImagingContext( ...
                [this.fqfileprefixAaron(id, v, gly, 'dfndm2') '.4dfp.ifh']);
        end
        function ic = mskt(~)
            ic = mlfourd.ImagingContext( ...
                fullfile(getenv('HOME'), 'Local', 'atlas', 'TRIO_Y_NDC_333_mskt.4dfp.ifh'));
        end
        function [ic,nn] = prepareBrainMask(this, id, v, gly)
            pwd0 = pushd(this.cbfPath(id, v));
            
            m = this.mskt;
            d = this.dfnd(id, v, gly);
            nn = d.numericalNiftid .* m.numericalNiftid;              
            assert(~isempty(nn.img));
            nn = nn.binarized;
            nn.filepath = this.cbfPath(id, v);
            nn.fileprefix = this.fileprefixAaron(id, v, gly, 'dfndm2');
            nn.filesuffix = '.4dfp.ifh';
            ic = mlfourd.ImagingContext(nn);
            
            popd(pwd0);
        end
        function [ic,nn,bmsknn,this] = prepareCBF(this, id, v, gly, varargin)
            ip = inputParser;
            addParameter(ip, 'kind', 'wCBF', @ischar);
            parse(ip, varargin{:});
            pwd0 = pushd(this.cbfPath(id, v));
            
            fprintf('prepareCBF.id->%s, kind->%s\n', id, ip.Results.kind);
            bmsk = this.prepareBrainMask(id, v, gly);
            bmsknn = bmsk.numericalNiftid;
            nn   = this.wCBFavg(id, v, gly);
            nn = nn.numericalNiftid .* bmsknn;
            nn.img = nn.img .* (nn.img > 0) .* (abs(nn.img) < this.maxCbf);
            assert(~isempty(nn.img));
            nn.fileprefix = this.fileprefixAaron(id, v, gly, this.cbfKind(ip.Results.kind));
            nn.filesuffix = '.4dfp.ifh';
            ic = mlfourd.ImagingContext(nn);
            
            popd(pwd0);
        end
        function this = prepareControls(this, varargin)
            %% PREPARECONTROLS
            %  @param named 'doDiff' is logical and creates analyses subtracting out mean CBF
            
            for v = 1:2
                for gly = 1:4
                    this = this.prepareGroup(this.controlsIds, v, gly, 'controls', varargin{:});
                end
            end
        end
        function this = prepareT1DM(this, varargin)
            %% PREPARET1DM
            %  @param named 'doDiff' is logical and creates analyses subtracting out mean CBF
            
            for gly = 1:4
                this = this.prepareGroup(this.t1dmIds, 1, gly, 't1dm', varargin{:});
            end
        end
        function this = prepareDeltaDeltas(this)
            this = this.prepareT1DM('doDiff', true);
            this.prepareDD('t1dm', 1);
            
            this = this.prepareControls('doDiff', true);
            this.prepareDD('controls', 1);
            this.prepareDD('controls', 2);
        end
        function this = prepareRandomisedDesigned(this, ids, v, gly, label)
            mlbash(sprintf( ...
                'randomise -i %s -o %s -d %s -t %s -m %s -T', ...
                this.inputData4D(ids, v, gly, label), ...
                this.outputRootname(v, gly, label), ...
                this.designMat(ids, v, gly, label), ...
                this.contrastCon(v, gly, label), ...
                this.maskImage(v, gly, label)));
        end
        function nn   = prepareDD(this, label, v)
            assert(ischar(label));
            
            import mlfourd.*;
            nn = NumericalNIfTId.load( ...
                [this.fqfileprefixGroup(label, v, 1, this.cbfKind('dCBF')) '.4dfp.ifh']);
            nn.fileprefix = ...
                this.fileprefixGroup(label, v, 1:4, this.cbfKind('ddCBF'));
            img__ = nn.img;
            for gly = 2:4
                nn__ = NumericalNIfTId.load( ...
                    [this.fqfileprefixGroup(label, v, gly, this.cbfKind('dCBF')) '.4dfp.ifh']);
                img__(:,:,:,gly) = nn__.img - img__(:,:,:,1);
            end
            nn.img = img__;
            nn.view;
            nn.save;
        end
		  
 		function this = ADA2018(varargin)
 			%% ADA2018
 			%  Usage:  this = ADA2018()

 			this.subjectsDir = fullfile(getenv('ARBELAEZ'), 'jjlee', 'BOLDHypo', '');
            warning('off', 'mlfourd:possibleMaskingError');
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
        function c    = cbfKind(this, kind)
            assert(ischar(kind));
            c = sprintf('%slt%g', kind, this.maxCbf);
        end
        function pth  = cbfPath(this, id, v)
            pth = fullfile(this.subjectsDir, sprintf('BOLD-%s_v%i', id, v), 'PCASL', 'CBF', '');
        end
        function fp   = fileprefixGroup(~, label, v, gly, kind)
            assert(ischar(label));
            assert(isnumeric(v));
            assert(isnumeric(gly));
            assert(ischar(kind));
            if (isscalar(gly))
                fp = sprintf('BOLD-%s_v%i_Gr%i_%s', label, v, gly, kind);
                return
            end            
            fp = sprintf('BOLD-%s_v%i_Gr%ito%i_%s', label, v, gly(1), gly(end), kind);
        end
        function fp   = fileprefixAaron(~, id, v, gly, kind)
            assert(ischar(id));
            assert(isnumeric(v));
            assert(isscalar(gly));
            assert(ischar(kind));
            fp = fullfile( ...
                sprintf('BOLD-%s_v%i_PC_asl_Gr%i_xr3d_1_atl_%s', id, v, gly, kind));
        end
        function [ic,groupNN] = finalizeGroupImage(this, groupNN, label, v, gly, varargin)
            ip = inputParser;
            addParameter(ip, 'kind', 'wCBF', @ischar);
            parse(ip, varargin{:});
            
            pwd1 = this.groupPath(v, gly, label);            
            groupNN.filepath = pwd1;
            groupNN.fileprefix = this.fileprefixGroup(label, v, gly, this.cbfKind(ip.Results.kind));
            groupNN.filesuffix = '.4dfp.ifh';
            if (this.verboseView)
                groupNN.view;
            end
            this.hist(groupNN, ip.Results.kind, 100);
            groupNN.save;
            ic = mlfourd.ImagingContext(groupNN);
            fldr = fullfile(pwd1, sprintf('saveFigures_%s', this.cbfKind(ip.Results.kind)), '');
            ensuredir(fldr);
            saveFigures(fldr);
        end
        function fqfp = fqfileprefixGroup(this, label, v, gly, kind)
            fqfp = fullfile( ...
                this.groupPath(v, gly, label), ...
                this.fileprefixGroup(label, v, gly, kind));
        end
        function fqfp = fqfileprefixAaron(this, id, v, gly, kind)
            fqfp = fullfile( ...
                this.cbfPath(id, v), ...
                this.fileprefixAaron(id, v, gly, kind));
        end
        function p1   = groupPath(this, v, gly, label)            
            if (isscalar(gly))
                p1 = fullfile(this.subjectsDir, sprintf('%s_v%i_Gr%i', label, v, gly), '');
                ensuredir(p1);
                return
            end
            p1 = fullfile(this.subjectsDir, sprintf('%s_v%i_Gr%ito%i', label, v, gly(1), gly(end)), '');
            ensuredir(p1);
        end
        function hist(~, obj, kind, varargin)
            if (isa(obj, 'mlfourd.ImagingContext'))
                obj = obj.niftid;
            end
            assert(isa(obj, 'mlfourd.INIfTId'));
            assert(ischar(kind));
            figure;
            if (strncmpi(kind, 'w', 1))
                select = obj.img > 0;
            else
                select = obj.img > min(min(min(obj.img))) & obj.img ~= 0;
            end
            
            hist(obj.img(select), varargin{:});
            title(obj.fileprefix, 'Interpreter', 'none');
            ylabel('voxels');
            xlabel([kind ' / (mL/hg/min)']);
        end
        function [this,ic,nn] = prepareGroup(this, ids, v, gly, label, varargin)
            ip = inputParser;
            addParameter(ip, 'doDiff', false, @islogical);
            parse(ip, varargin{:});
            
            if (ip.Results.doDiff)
                [this,ic,nn] = this.prepareDiffGroup(ids, v, gly, label);
                return
            end
            [this,ic,nn] = this.prepareAbsGroup(ids, v, gly, label);            
        end
        function [this,ic,nn] = prepareAbsGroup(this, ids, v, gly, label)
            kind = 'wCBF';
            pwd1 = this.groupPath(v, gly, label);            
            pwd0 = pushd(pwd1);   

            img = 0;
            mskImg = 1;
            idx = 0;
            success = 0;
            while idx < length(ids)
                idx = idx + 1;
                try
                    [~,wcbf,bmsk,this] = this.prepareCBF(ids{idx}, v, gly, 'kind', kind);
                    if (this.verboseView)
                        wcbf.view;
                    end
                    this.hist(wcbf, kind, 100);
                    wcbf.save;
                    bmsk.save
                    img = img + wcbf.img;
                    mskImg = mskImg .* bmsk.img;
                    success = success + 1;
                catch ME
                    handwarning(ME);
                end
            end
            wcbf.img = (img/success) .* mskImg;            
            [ic,nn] = this.finalizeGroupImage(wcbf, label, v, gly, 'kind', kind);

            popd(pwd0);
        end
        function [this,ic,nn] = prepareDiffGroup(this, ids, v, gly, label)
            kind = 'dCBF';
            pwd1 = this.groupPath(v, gly, label);
            pwd0 = pushd(pwd1);   

            this = this.setupMuCbfs(v, gly, length(ids));
            img = 0;
            mskImg = 1;
            idx = 0;
            success = 0;
            while idx < length(ids)
                idx = idx + 1;
                try
                    [~,dcbf,bmsk,this] = this.prepareCBF(ids{idx}, v, gly, 'kind', kind);
                    this = this.updateMuCbfs(idx, v, gly, dcbf, bmsk);
                    dcbf.img = dcbf.img - bmsk.img*this.muCbfs(idx);
                    if (this.verboseView)
                        dcbf.view;
                    end
                    this.hist(dcbf, kind, 100);
                    dcbf.save;
                    bmsk.save;
                    img = img + dcbf.img;
                    mskImg = mskImg .* bmsk.img;
                    success = success + 1;
                catch ME
                    handwarning(ME);
                end
            end
            dcbf.img = (img/success) .* mskImg;               
            [ic,nn] = this.finalizeGroupImage(dcbf, label, v, gly, 'kind', kind);

            popd(pwd0);
        end
        function this = setupMuCbfs(this, v, gly, len)
            if (1 == v && 1 == gly)
                this.muCbfs = nan(1, len);
            end
        end
        function this = updateMuCbfs(this, idx, v, gly, dcbf, bmsk)
            if (1 == v && 1 == gly)
                this.muCbfs(idx) = mean(dcbf.img(logical(bmsk.img)));
            end
        end
        
        %% For use with FSL randomise
             
        function fqfn = inputData4D(this, ids, v, gly, label)
            assert(isscalar(gly));
            
            import mlfourd.*;
            ic = this.dCBF(ids{1}, v, gly);
            nn = ic.numericalNiftid;
            for idx = 2:length(ids)
                ic__ = this.dCBF(ids{idx}, v, gly);
                nn__ = ic__.numericalNiftid;
                nn.img(:,:,:,idx) = nn__.img;
            end
            nn.filepath = this.groupPath(v, gly, label);
            nn.fileprefix = sprintf('inputData4D-%s_v%i_Gr%i_dCBFlt%g', label, v, gly, this.maxCbf);
            nn.filesuffix = '.nii.gz';
            nn.save;
            fqfn = nn.fqfilename;
        end
        function fqfp = outputRootname(this, v, gly, label)
            fqfp = fullfile( ...
                this.groupPath(v, gly, label), ...
                sprintf('output-%s_v%i_Gr%i_dCBFlt%g', label, v, gly, this.maxCbf));
        end
        function designFqfn = designMat(this, ids, v, gly, label)
            Nsubj = length(ids);
            designFqfp = fullfile( ...
                this.groupPath(v, gly, label), ...
                sprintf('design-%s_v%i_Gr%i_dCBFlt%g', label, v, gly, this.maxCbf));
            designFqfn = [designFqfp '.mat'];
            
            fid = fopen([designFqfp '.txt'], 'w');
            for s = 1:Nsubj
                fprintf(fid, '1\n');
            end
            fclose(fid);
            
            pwd0 = pushd(fileparts(designFqfp));
            mlbash(sprintf('Text2Vest %s.txt %s', designFqfp, designFqfn));
            popd(pwd0);
        end
        function contrastFqfn = contrastCon(this, v, gly, label)
            contrastFqfp = fullfile( ...
                this.groupPath(v, gly, label), ...
                sprintf('contrast-%s_v%i_Gr%i_dCBFlt%g', label, v, gly, this.maxCbf));
            contrastFqfn = [contrastFqfp '.con'];
            
            fid = fopen([contrastFqfp '.txt'], 'w');
            fprintf(fid, '1\n');
            fclose(fid);
            
            pwd0 = pushd(fileparts(contrastFqfp));
            mlbash(sprintf('Text2Vest %s.txt %s', contrastFqfp, contrastFqfn));
            popd(pwd0);
        end
        function fqfn = maskImage(this, v, gly, label)
            nn = mlfourd.NumericalNIfTId.load( ...
                [this.fqfileprefixGroup(label, v, gly, this.cbfKind('dCBF')) '.4dfp.ifh']);
            nn.filesuffix = '.nii.gz';
            nn = nn.binarized;
            nn.save;
            fqfn = nn.fqfilename;
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

