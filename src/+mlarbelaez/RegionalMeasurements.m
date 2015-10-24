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
        GLUC_FILE_SUFFIX = '_mcf_revf1to5.nii.gz'
        HO_FILE_SUFFIX = '_sumt_333fwhh_on_gluc.nii.gz'
        OC_FILE_SUFFIX = '_333fwhh_on_gluc.nii.gz'
        DEFAULT_MASK = 'aparc_a2009s+aseg_mask'
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
        maskFqfilename
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
            assert(lexist(f, 'file'));
        end               
        function f = get.ocFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%soc%i%s', this.pnumber, this.scanIndex, this.OC_FILE_SUFFIX));
            assert(lexist(f, 'file'));
        end  
        function f = get.ocHdrinfoFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%soc%i%s', this.pnumber, this.scanIndex, '_g3.hdrinfo'));
            assert(lexist(f, 'file'));
        end   
        function f = get.maskFqfilename(this)
            f = fullfile( ...
                this.sessionPath_, 'PET', this.scanLabel, ...
                sprintf('%s_on_gluc%i.nii.gz', this.region_, this.scanIndex));
            assert(lexist(f, 'file'));
        end
    end

    methods (Static)
        function carr = loopRegionalMeasurements(studyPth)
            import mlarbelaez.*;
            reg     = ArbelaezRegistry.instance;
            regions = reg.regionLabels;
            dt      = mlsystem.DirTool(fullfile(studyPth, reg.sessionNamePattern));
            
            carr = cell(dt.length, 2, length(regions));            
            for d = 1:dt.length
                for s = 1:2
                    for r = 1:length(regions)
                        rm = RegionalMeasurements(dt.fqdns{d}, s, regions{r});
                        rm.kinetics4Cached_ = rm.kinetics4;
                        rm.fFracCached_     = rm.fFrac;
                        rm.vFracCached_     = rm.vFrac;
                        carr{d,s,r} = rm;
                    end
                end
            end
        end
    end
    
	methods		  
 		function this = RegionalMeasurements(sessionPath, scanIndex, region)
 			%% REGIONALMEASUREMENTS
 			%  Usage:  this = RegionalMeasurements(session_path, scan_index, region)

            import mlarbelaez.* mlpet.*;
            this.registry_ = ArbelaezRegistry.instance;
            
            ip = inputParser;
            addRequired(ip, 'sessionPath', @(x) lexist(x, 'dir'));
            addRequired(ip, 'scanIndex',   @isnumeric);
            addRequired(ip, 'region',      @(x) lstrfind(x, this.registry_.regionLabels));
            parse(ip, sessionPath, scanIndex, region);
            
            this.sessionPath_ = ip.Results.sessionPath;
            this.scanIndex_   = ip.Results.scanIndex;
            this.region_      = ip.Results.region;
            
            gTx = GluTxlsx;
            this.gluTxlsxMap_ = gTx.pid_map;
            
            this.dta_ = DTA.load(this.dtaFqfn_);
            this.tsc_ = TSC.load( ...
                        this.tscFqfn_, this.glucFqfilename, this.dtaFqfn_, this.maskFqfilename);
        end
        function k = kinetics4(this)
            import mlarbelaez.*;
            try
                if (isempty(this.kinetics4Cached_))
                    director = KineticsDirector.loadRegionalKinetics4( ...
                               RegionalMeasurements(this.sessionPath, this.scanIndex, this.region));
                    director = director.estimateAll;
                    this.kinetics4Cached_ = director.product;
                end
                k = this.kinetics4Cached_;
            catch ME
                handwarning(ME);
                k = nan;
            end
        end
        function f = fFrac(this)
            import mlpet.*;
            try
                if (isempty(this.fFracCached_))
                    director = AutoradiographyDirector.loadCRVAutoradiography( ...
                               this.maskFqfilename, ...
                               this.crvFn_, ...
                               this.hoFqfilename, ...
                               this.registry_.getGluTShifts(this.scanIndex, this.pnumber));
                    director = director.estimateAll;
                    this.fFracCached_ = director.product.f;
                end
                f = this.registry_.regressFHerscToVideen(this.fFracCached_);
            catch ME
                handwarning(ME);
                f = nan;
            end
        end
        function v = vFrac(this)
            import mlpet.*;
            try                
                if (isempty(this.vFracCached_))
                    director = O15Director.load( ...
                               this.ocFqfilename, ...
                               'Hdrinfo', this.ocHdrinfoFqfilename, ...
                               'Mask',    this.maskFqfilename);
                    this.vFracCached_ = director.vFrac;
                end
                v = this.vFracCached_;
            catch ME
                handwarning(ME);
                v = nan;
            end
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        sessionPath_
        scanIndex_
        region_
        registry_
        gluTxlsxMap_
        dta_
        tsc_
        vFracCached_
        fFracCached_
        kinetics4Cached_
    end

    methods (Access = 'private')
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

