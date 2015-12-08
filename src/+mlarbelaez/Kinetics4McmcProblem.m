classdef Kinetics4McmcProblem < mlbayesian.AbstractMcmcProblem
	%% mlarbelaez.KINETICS4MCMCPROBLEM is a stand-alone implementation of Powers' 4-compartment model for
    %  1-[11C]-glucose kinetics

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
    
    properties
        k04 = nan
        k12frac = 0.0842
        k21 = 0.0579
        k32 = 0.0469
        k43 = 0.000309
        t0  = 44.1
        
        pnumber
        scanIndex
        xLabel = 'times/s'
        yLabel = 'concentration/(wellcounts/mL)'
        
        dta
        mode = 'Macaque'
        region
    end
    
    properties (Dependent)
        baseTitle
        detailedTitle
        gluTxlsxFilename
        gluTxlsxInfo
        map
        VB
        FB
        K04
    end
    
    methods %% GET
        function bt  = get.baseTitle(this)
            bt = sprintf('%s %s', class(this),str2pnum(pwd));
        end
        function dt  = get.detailedTitle(this)
            dt = sprintf('%s:\nk04 %g, k21 %g, k12frac %g, k32 %g, k43 %g, t0 %g, VB %g, FB %g', ...
                         this.baseTitle, ...
                         this.k04, this.k21, this.k12frac, this.k32, this.k43, this.t0, this.VB, this.FB);
        end
        function fn  = get.gluTxlsxFilename(~)
            fn = fullfile(getenv('ARBELAEZ'), 'GluT', 'GluT de novo 2015aug11.xlsx');
        end
        function inf = get.gluTxlsxInfo(this)
            switch (this.mode)
                case 'Macaque'                    
                    inf = this.gluTxlsx_.pid_map(this.pnumber).(this.region);
                case 'WholeBrain'
                    inf = this.gluTxlsx_.pid_map(this.pnumber).(sprintf('scan%i', this.scanIndex));
                case 'AlexsRois'
                    inf = this.gluTxlsx_.rois_map(strtok(this.region, '_')).(sprintf('scan%i', this.scanIndex));                    
                otherwise
                    error('mlarbelaez:failedSwitch', 'Kinetics4McmcProblem.get.gluTxlsxInfo');
            end
        end        
        function m   = get.map(this)
            m = containers.Map;
            fL = 1; fH = 1;
            m('k04')     = struct('fixed', 1, 'min', 0*fL,       'mean', this.K04,     'max', 1*fH); 
            m('k12frac') = struct('fixed', 0, 'min', 0.0387*fL,  'mean', this.k12frac, 'max', 0.218*3);   % Powers' monkey paper
            m('k21')     = struct('fixed', 0, 'min', 0.0435*fL,  'mean', this.k21,     'max', 0.0942*fH);  % "
            m('k32')     = struct('fixed', 0, 'min', 0.0015*fL,  'mean', this.k32,     'max', 0.5589*fH);  % " excluding last 2 entries
            m('k43')     = struct('fixed', 0, 'min', 2.03e-4*fL, 'mean', this.k43,     'max', 3.85e-4*fH); % "
            m('t0' )     = struct('fixed', 0, 'min',-2e2*fL,     'mean', this.t0,      'max', 2e2*fH);  
        end
        function v   = get.VB(this)
            % fraction
            v = this.gluTxlsxInfo.cbv;
            if (v > 1)
                v = v/100; end
        end
        function f   = get.FB(this)
            % fraction/s
            f = this.gluTxlsxInfo.cbf;
            assert(~isnumeric(f) || ~isnan(f), 'mlarbelaez:nan', 'Kinetics4McmcProblem.get.FB');
            f = 1.05 * f / 6000; % mL/min/100g to 1/s
        end
        function k   = get.K04(this)
            % 1/s
            k = this.FB/this.VB;
        end
    end
    
    methods (Static)
        function [k,kmp] = run(pth, snum)

            pnum = str2pnum(pth);
            dtaFqfn = fullfile(pth, 'jjl_proc', sprintf('%sgluc%i.dta',  pnum, snum));
            tscFqfp = fullfile(pth, 'jjl_proc', sprintf('%swb%i', pnum, snum));
            tscFqfn = [tscFqfp '.tsc'];
            
            import mlpet.*;
                        
            dta_ = DTA.load(dtaFqfn);
            tsc_ = TSC.import(tscFqfn);          
            %figure; plot(timeInterp, Ca_, timeInterp, Q_)            
            kmp = mlarbelaez.Kinetics4McmcProblem(tsc_.times, tsc_.becquerels, dta_, pnum, snum);
            
            fprintf('Kinetics4McmcProblem.run.pth -> %s\n', pth);
            fprintf('Kinetics4McmcProblem.run.snum -> %i\n', snum);
            disp(dta_)
            disp(tsc_)
            disp(kmp)
            
            kmp = kmp.estimateParameters(kmp.map);
            %kmp.plotProduct;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12frac'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
        end 
        function [k,kmp] = runMacaque(pth, region)

            mnum = str2mnum(pth);
            dtaFqfn = fullfile(pth, 'text', sprintf('%sG.DTA',  mnum));
            tscFqfp = fullfile(pth, 'text', sprintf('%s', mnum));
            tscFqfn = [tscFqfp '.TSC'];
            
            import mlpet.* mlarbelaez.*;
                        
            dta_ = DTA.load(dtaFqfn, true); % DTA has short header
            if (lstrfind(lower(region), 'left'))
                tsc_ = TSC.import(tscFqfn, 1);
            else
                tsc_ = TSC.import(tscFqfn, 2);
            end                
            %figure; plot(dta_.timeInterpolants, dta_.wellCountInterpolants, tsc_.times, tsc_.becquerels);
            kmp  = Kinetics4McmcProblem(tsc_.times, tsc_.becquerels, dta_, mnum, 1, 'Region', region, 'GluTxlsx', GluTxlsxMacaque);
            
            fprintf('Kinetics4McmcProblem.runMacaque.pth -> %s\n', pth);
            disp(dta_)
            disp(tsc_)
            disp(kmp)
            
            kmp = kmp.estimateParameters(kmp.map);
            %kmp.plotProduct;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12frac'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
        end 
        function [k,kmp] = runRegion(pth, snum, region)

            import mlpet.* mlarbelaez.*;            
            tscf = GluTFiles('pnumPath', pth, 'scanIndex', snum, 'region', region);                        
            dta_ = DTA.load(tscf.dtaFqfilename);
            tsc_ = TSC.loadGluTFiles(tscf);
            len  = min(length(dta_.timeInterpolants), length(tsc_.timeInterpolants));           
            %figure; plot(timeInterp, Ca_, timeInterp, Q_)
            kmp  = mlarbelaez.Kinetics4McmcProblem( ...
                tsc_.timeInterpolants(1:len), ...
                tsc_.becquerelInterpolants(1:len), ...
                dta_, ...
                str2pnum(pth), snum, 'Region', region);
            
            fprintf('Kinetics4McmcProblem.runRegions.pth  -> %s\n', pth);
            fprintf('Kinetics4McmcProblem.runRegions.snum -> %i\n', snum);
            fprintf('Kinetics4McmcProblem.runRegions.region -> %s\n', region);
            disp(dta_)
            disp(tsc_)
            disp(kmp)
            
            kmp = kmp.estimateParameters(kmp.map);
            %kmp.plotProduct;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12frac'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
        end 
        function Q_sampl = concentrationQ(k04, k12frac, k21, k32, k43, t0, dta, VB, t_sampl)
            t      = dta.timeInterpolants; % use interpolants internally            
            t0_idx = floor(abs(t0)/dta.dt) + 1;
            if (t0 < -1) % shift cart earlier in time
                cart                 = dta.wellCountInterpolants(end) * ones(1, length(t));
                cart(1:end-t0_idx+1) = dta.wellCountInterpolants(t0_idx:end); 
            elseif (t0 > 1) % shift cart later in time
                cart             = dta.wellCountInterpolants(1) * ones(1, length(t));
                cart(t0_idx:end) = dta.wellCountInterpolants(1:end-t0_idx+1);
            else
                cart = dta.wellCountInterpolants;
            end
            
            k12 = k21 * k12frac;
            k22 = k12 + k32;
            q1_ = VB * cart;
            q2_ = VB * k21 * exp(-k22*t);
            q3_ = VB * k21 * k32 * (k22 - k43)^-1 * (exp(-k43*t) - exp(-k22*t));
            q4_ = VB * k21 * k32 * k43 * ( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)));
                 
            q234    = conv(q2_ + q3_ + q4_, cart);
            Q       = q1_ + q234(1:length(t)); % truncate convolution         
            Q_sampl = pchip(t, Q, t_sampl); % resample interpolants
        end
    end
    
    methods
        function this = Kinetics4McmcProblem(t, y, dta, pnum, snum, varargin)
            this = this@mlbayesian.AbstractMcmcProblem(t, y);
            
            ip = inputParser;
            addRequired(ip, 't', @isnumeric);
            addRequired(ip, 'y', @isnumeric);
            addRequired(ip, 'dta', @(x) isa(x, 'mlpet.IWellData'));
            addRequired(ip, 'pnum', @(x) lstrfind(x, 'p') | lstrfind(x, 'M'));
            addRequired(ip, 'snum', @isnumeric);
            addParameter(ip, 'Region', '', @ischar);
            addParameter(ip, 'GluTxlsx', mlarbelaez.GluTxlsx, @(x) isa(x, 'mlarbelaez.IGluTxlsx'));
            parse(ip, t, y, dta, pnum, snum, varargin{:});
            
            this.dta       = ip.Results.dta;
            this.pnumber   = ip.Results.pnum;
            this.scanIndex = ip.Results.snum;
            this.region    = ip.Results.Region;
            this.gluTxlsx_ = ip.Results.GluTxlsx;              
            this.k04       = this.K04;
            this.expectedBestFitParams_ = ...
                [this.k04 this.k12frac this.k21 this.k32 this.k43 this.t0];
        end
        function Q    = itsConcentrationQ(this)
            Q = this.concentrationQ(this.k04, this.k12frac, this.k21, this.k32, this.k43, this.t0, this.dta, this.VB, this.times);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.ensureKeyOrdering({'k04' 'k12frac' 'k21' 'k32' 'k43' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.k04 = this.finalParams('k04');
            this.k12frac = this.finalParams('k12frac');
            this.k21 = this.finalParams('k21');
            this.k32 = this.finalParams('k32');
            this.k43 = this.finalParams('k43');
            this.t0  = this.finalParams('t0');
        end
        function ed   = estimateData(this)
            keys = this.paramsManager.paramsMap.keys;
            ed = this.estimateDataFast( ...
                this.finalParams(keys{1}), ...
                this.finalParams(keys{2}), ...
                this.finalParams(keys{3}), ...
                this.finalParams(keys{4}), ...
                this.finalParams(keys{5}), ...
                this.finalParams(keys{6}));
        end
        function Q    = estimateDataFast(this, k04, k12frac, k21, k32, k43, t0)
            Q = this.concentrationQ(k04, k12frac, k21, k32, k43, t0, this.dta, this.VB, this.times);
        end   
        
        function        plotProduct(this)
            try
                figure;
                max_ecat = max(max(this.itsConcentrationQ), max(this.dependentData));
                max_aif  = max(this.dta.wellCounts);

                hold on;
                plot(this.times,     this.itsConcentrationQ / max_ecat);
                plot(this.times,     this.dependentData     / max_ecat, 'Marker','s','LineStyle','none');
                plot(this.dta.times, this.dta.wellCounts    / max_aif,  'Marker','o','LineStyle',':');
                legend('concentration_{ecat}', 'data_{ecat}', ...
                       'concentration_{art}'); 
                title(this.detailedTitle, 'Interpreter', 'none');
                xlabel(this.xLabel);
                ylabel(sprintf('arbitrary:  ECAT norm %g, AIF norm %g', max_ecat, max_aif));
                hold off;
            catch ME
                handwarning(ME);
            end
        end  
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlarbelaez.Kinetics4McmcProblem')));
            assert(isnumeric(vars));
            switch (par)
                case 'k04'
                    for v = 1:length(vars)
                        args{v} = { vars(v)  this.k12frac this.k21 this.k32 this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 'k12frac'
                    for v = 1:length(vars)
                        args{v} = { this.k04 vars(v)  this.k21 this.k32 this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 'k21'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac vars(v)  this.k32 this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 'k32'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 vars(v)  this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 'k43'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 this.k32 vars(v)  this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12frac this.k21 this.k32 this.k43 vars(v) this.dta.wellCounts this.VB this.dt this.times }; end
            end
            this.plotParArgs(par, args, vars);
        end  
    end
    
    %% PRIVATE

    properties (Access = 'private')
        gluTxlsx_
    end
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlarbelaez.Kinetics4McmcProblem')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlarbelaez.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, Kinetics4McmcProblem.concentrationQ(argsv{:}));
            end
            title(sprintf('k04 %g, k12frac %g, k21 %g, k32 %g, k43 %g, t0 %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

