classdef RegionalMeasurements 
	%% REGIONALMEASUREMENTS is a meta-director that organizes specific directors 
    %  for reading, constructing, assembling, processing regional measurements
    %  that are salient for publication of glucose threshold imaging studies.
    %  See also:  mlarbelaez.KineticsDirector,
    %             mlpet.AutoradiographyDirector, 
    %             mlpet.O15Director.

	%  $Revision$
 	%  was created 15-Oct-2015 17:17:32
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 8.5.0.197613 (R2015a) for MACI64.
 	
    properties (Constant)
        GLUC_FILE_SUFFIX = '_454552fwhh_mcf.nii.gz'
        HO_FILE_SUFFIX = '_454552fwhh.nii.gz'
        OC_FILE_SUFFIX = '_141414fwhh.nii.gz'
        
        dns  = {'p7873_JJL' 'p7901_JJL' 'p7926_JJL' 'p7935_JJL' ...
                'p7954_JJL' 'p7979_JJL' 'p7991_JJL' 'p8015_JJL' ...
                'p8018_JJL' 'p8039_JJL' 'p8042_JJL' 'p8047_JJL'};
    end
    
    properties (Dependent)
        pnumber
        sessionPath
        scanIndex
 		region
        
        plasmaGlucose
        hct
        dta
        tsc        
        
        glucFqfilename
        hoFqfilename
        ocFqfilename
        ocHdrinfoFqfilename
    end
    
    methods % GET
        function g = get.pnumber(this)
            g = this.registry_.str2pnum(this.sessionPath_);
        end
        function p = get.sessionPath(this)
            p = this.sessionPath_;
        end
        function g = get.scanIndex(this)
            g = this.scanIndex_;
        end
        function g = get.region(this)
            g = this.region_;
        end
        function g = get.plasmaGlucose(this)
            map = this.gluTxlsxMap_;
            g = map(this.pnumber).(this.scanLabel).glu;
        end
        function g = get.hct(this)
            map = this.gluTxlsxMap_;
            g = map(this.pnumber).(this.scanLabel).hct;
        end
        function g = get.dta(this)
            g = this.dta_;
        end
        function g = get.tsc(this)
            g = this.tsc_;
        end        
        function f = get.glucFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%sgluc%i%s', this.pnumber, this.scanIndex, this.GLUC_FILE_SUFFIX));
            assert(lexist(f, 'file'));
        end              
        function f = get.hoFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%sho%i%s', this.pnumber, this.scanIndex, this.HO_FILE_SUFFIX));
            %assert(lexist(f, 'file'));
        end               
        function f = get.ocFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%soc%i%s', this.pnumber, this.scanIndex, this.OC_FILE_SUFFIX));
            %assert(lexist(f, 'file'));
        end  
        function f = get.ocHdrinfoFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%soc%i%s', this.pnumber, this.scanIndex, '_g3.hdrinfo'));
            %assert(lexist(f, 'file'));
        end
    end

    methods (Static)
        function [carr,tf] = looper
            import mlarbelaez.*;
            t0      = tic;
            reg     = ArbelaezRegistry.instance;
            sDir    = reg.subjectsDir;
            cd(sDir);
            dns     = {'p8047_JJL'};
            carr    = cell(length(dns), 2, length(reg.regionLabels));  
            for d = 1:length(dns)
                for s = 1:1 % 2
                    regions = reg.regionLabels;
                    for r = 1:1 % length(regions)
                        rm = RegionalMeasurements(fullfile(sDir, dns{d}, ''), s, regions{r});
                        %[~,rm] = rm.vFrac;
                        %[~,rm] = rm.fFrac;
                        %[~,rm] = rm.kinetics4;
                        carr{d,s,r} = rm;
                    end
                end
            end
            cd(sDir);
            tf = toc(t0);
        end
    end
    
	methods		  
 		function this = RegionalMeasurements(sessionPath, scanIndex, region)
 			%% REGIONALMEASUREMENTS
 			%  Usage:  this = RegionalMeasurements(session_path, scan_index, region)

            import mlarbelaez.* mlpet.*;
            this.registry_ = ArbelaezRegistry.instance;
            
            ip = inputParser;
            addRequired(ip, 'sessionPath', @isdir);
            addRequired(ip, 'scanIndex',   @isnumeric);
            addRequired(ip, 'region',      @(x) lstrfind(x, this.registry_.regionLabels));
            parse(ip, sessionPath, scanIndex, region);
            
            this.sessionPath_ = ip.Results.sessionPath;
            this.scanIndex_   = ip.Results.scanIndex;
            this.region_      = ip.Results.region;
            
            gTx = GluTxlsx;
            this.gluTxlsxMap_ = gTx.pid_map;            
            this.gluTAlignmentDirector_ = GluTAlignmentDirector.loadTouched(this.sessionPath);            
            this.dta_ = DTA.load(this.dtaFqfn_);
            this.tsc_ = TSC.load( ...
                        this.tscFqfn_, this.glucFqfilename, this.dtaFqfn_, this.maskFqfilenameFor('gluc'));   
        end
        function [k,this] = kinetics4(this)
            import mlarbelaez.*;
            try                
                if (isempty(this.vFracCached_))
                    [~,this] = this.vFrac;
                end
                if (isempty(this.fFracCached_))
                    [~,this] = this.fFrac;
                end
                if (isempty(this.kinetics4Cached_))
                    director = KineticsDirector.loadRegionalKinetics4(this);
                    director = director.estimateAllFixedT0(this.registry_.getKinetics4T0(this.scanIndex, this.pnumber));
                    this.kinetics4Cached_ = director.product;
                end
                k = this.kinetics4Cached_;
            catch ME
                disp(ME)
                struct2str(ME.stack)
                handwarning(ME);
                k = nan;
            end
        end
        function [f,this] = fFrac(this)
            import mlpet.*;
            try
                if (isempty(this.fFracCached_))
                    director = AutoradiographyDirector.loadCRVAutoradiography( ...
                               this.maskFqfilenameFor('ho'), ...
                               this.crvFn_, ...
                               this.hoFqfilename, ...                               
                               'crvShift', this.registry_.getGluTShifts(this.scanIndex, this.pnumber), ...
                               'dcvShift', this.registry_.getGluTShifts(this.scanIndex, this.pnumber));
                    director = director.estimateAll;
                    this.fFracCached_ = director.product.f;
                    this.fFracCached_ = this.registry_.regressFHerscToVideen(this.fFracCached_);
                end
                f = this.fFracCached_;
            catch ME
                disp(ME)
                struct2str(ME.stack)
                handwarning(ME);
                f = nan;
            end
        end
        function [v,this] = vFrac(this)
            import mlpet.*;
            try                
                if (isempty(this.vFracCached_))
                    director = O15Director.load( ...
                               this.ocFqfilename, ...
                               'Hdrinfo', this.ocHdrinfoFqfilename, ...
                               'Mask',    this.maskFqfilenameFor('oc'));
                    this.vFracCached_ = director.vFrac;
                end
                v = double(this.vFracCached_);
            catch ME
                disp(ME)
                struct2str(ME.stack)
                handwarning(ME);
                v = nan;
            end
        end
        function ic = ocImagingContext(this)
            import mlfourd.*;
            fqfn0 = fullfile(this.sessionPath, 'PET', sprintf('scan%i', this.scanIndex), ...
                             sprintf('%soc%i.nii.gz', this.pnumber, this.scanIndex));
            if (~lexist(this.ocFqfilename, 'file'))  
                bniid = BlurringNIfTId(NIfTId(fqfn0), 'blur', [14.70904 14.70904 14.70904]);
                bniid.save;
                ic = ImagingContext(bniid.fqfilename);
            else 
                ic = ImagingContext(this.ocFqfilename);
            end
        end        
        function ic = hoImagingContext(this)
            ic = mlfourd.ImagingContext(this.hoFqfilename);
        end
        function ic = glucImagingContext(this)
            ic = mlfourd.ImagingContext(this.glucFqfilename);
        end
    end 
    
    %% PRIVATE
    
    properties (Hidden)
        vFracCached_
        fFracCached_
    end
    
    properties (Access = 'private')
        sessionPath_
        scanIndex_
        region_
        registry_
        gluTxlsxMap_
        dta_
        tsc_
        kinetics4Cached_
        
        gluTAlignmentDirector_
        maskImagingContext_
    end

    methods (Access = 'private')
        function f = maskFqfilenameFor(this, tracer)
            switch (lower(tracer))
                case 'oc'
                    ic = this.gluTAlignmentDirector_.alignRegion(this.region, this.ocImagingContext);
                    f  = ic.fqfilename;
                case 'ho'
                    ic = this.gluTAlignmentDirector_.alignRegion(this.region, this.hoImagingContext);
                    f  = ic.fqfilename;
                case 'gluc'
                    ic = this.gluTAlignmentDirector_.alignRegion(this.region, this.glucImagingContext);
                    f  = ic.fqfilename;
                otherwise
                    error('mlarbelaez:unsupportedSwitchCase', ...
                          'RegionalMeasurements.maskFqfilename.tracer->%s', tracer);
            end
        end
        function f = tscFqfn_(this)          
            f = fullfile( ...
                this.sessionPath_, 'jjl_proc', ...
                sprintf('%sgluc%i_%s.tsc', this.pnumber, this.scanIndex, this.region));
        end
        function f = dtaFqfn_(this)
            f = fullfile( ...
                this.sessionPath_, 'jjl_proc', ...
                sprintf('%sgluc%i.dta', this.pnumber, this.scanIndex));
        end
        function f = crvFn_(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%sho%i.crv', this.pnumber, this.scanIndex));
        end
        function s = scanLabel(this)
            s = sprintf('scan%i', this.scanIndex);
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

