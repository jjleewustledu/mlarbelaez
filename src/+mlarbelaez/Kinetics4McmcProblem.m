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
        k12 = 0.00525
        k21 = 0.0860
        k32 = 0.00344
        k43 = 0.000302
        t0  = 44.1
        
        pnumber
        snumber
        xLabel = 'times/s'
        yLabel = 'concentration/(wellcounts/mL)'
        
        Ca
        mode = 'AlexsRois'
    end
    
    properties (Dependent)
        baseTitle
        detailedTitle
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
            dt = sprintf('%s:\nk04 %g, k21 %g, k12 %g, k32 %g, k43 %g, t0 %g, VB %g, FB %g', ...
                         this.baseTitle, ...
                         this.k04, this.k21, this.k12, this.k32, this.k43, this.t0, this.VB, this.FB);
        end
        function inf = get.gluTxlsxInfo(this)
            switch (this.mode)
                case 'WholeBrain'
                    inf = this.gluTxlsx_.pid_map(this.pnumber).(sprintf('scan%i', this.snumber));
                case 'AlexsRois'
                    inf = this.gluTxlsx_.rois_map(this.pnumber).(sprintf('scan%i', this.snumber));                    
                otherwise
                    error('mlarbelaez:failedSwitch', 'Kinetics4McmcProblem.get.gluTxlsxInfo');
            end
        end        
        function m   = get.map(this)
            m = containers.Map;
            m('k04') = struct('fixed', 1, 'min', 0,       'mean', this.K04, 'max', 1); 
            m('k12') = struct('fixed', 0, 'min', 0.00192, 'mean', this.k12, 'max', 0.0204);  % Powers' monkey paper
            m('k21') = struct('fixed', 0, 'min', 0.0435,  'mean', this.k21, 'max', 0.0942);  % "
            m('k32') = struct('fixed', 0, 'min', 0.0015,  'mean', this.k32, 'max', 0.559);   % "
            m('k43') = struct('fixed', 0, 'min', 2.03e-5, 'mean', this.k43, 'max', 3.85e-4); % "
            m('t0' ) = struct('fixed', 0, 'min', 0,       'mean', this.t0,  'max', 5e2);  
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
            dtaFqfn = fullfile(pth, 'jjl_proc', sprintf('%sg%i.dta',  pnum, snum));
            tscFqfp = fullfile(pth, 'jjl_proc', sprintf('%swb%i', pnum, snum));
            tscFqfn = [tscFqfp '.tsc'];
            
            import mlpet.*;
                        
            dta = DTA.load(dtaFqfn);
            tsc = TSC.import(tscFqfn);
            len = min(length(dta.timeInterpolants), length(tsc.timeInterpolants));
            timeInterp = tsc.timeInterpolants(1:len);
            Ca_ = dta.wellCountInterpolants(1:len);
            Q_  = tsc.becquerelInterpolants(1:len);            
            %figure; plot(timeInterp, Ca_, timeInterp, Q_)            
            kmp = mlarbelaez.Kinetics4McmcProblem(timeInterp, Q_, Ca_, pnum, snum);
            
            fprintf('Kinetics4McmcProblem.run.pth -> %s\n', pth);
            fprintf('Kinetics4McmcProblem.run.snum -> %s\n', snum);
            disp(dta)
            disp(tsc)
            disp(kmp)
            
            kmp = kmp.estimateParameters(kmp.map);
            kmp.plotProduct;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
        end 
        function [k,kmp] = runRegions(pth, snum, region)

            pnum = str2pnum(pth);
            dtaFqfn = fullfile(pth, 'jjl_proc', sprintf('%sg%i.dta',  pnum, snum));
            tscFqfp = fullfile(pth, 'jjl_proc', sprintf('%swb%i_%s', pnum, snum, region));
            tscFqfn = [tscFqfp '.tsc'];
            
            import mlpet.*;
                        
            dta = DTA.load(dtaFqfn);
            tsc = TSC.import(tscFqfn);
            len = min(length(dta.timeInterpolants), length(tsc.timeInterpolants));
            timeInterp = tsc.timeInterpolants(1:len);
            Ca_ = dta.wellCountInterpolants(1:len);
            Q_  = tsc.becquerelInterpolants(1:len);            
            %figure; plot(timeInterp, Ca_, timeInterp, Q_)            
            kmp = mlarbelaez.Kinetics4McmcProblem(timeInterp, Q_, Ca_, pnum, snum);
            
            fprintf('Kinetics4McmcProblem.runRegions.pth -> %s\n', pth);
            fprintf('Kinetics4McmcProblem.runRegions.snum -> %s\n', snum);
            fprintf('Kinetics4McmcProblem.runRegions.snum -> %s\n', region);
            disp(dta)
            disp(tsc)
            disp(kmp)
            
            kmp = kmp.estimateParameters(kmp.map);
            kmp.plotProduct;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
        end 
        function Q = concentrationQ(k04, k12, k21, k32, k43, t0, Ca, VB, dt, t)
            k22 = k12 + k32;
            len = length(t);
            
            t0_idx               = floor(t0/dt) + 1;
            cart                 = Ca(end) * ones(1, len);
            cart(1:end-t0_idx+1) = Ca(t0_idx:end); 
            
            q2_ = VB * k21 * exp(-k22*t);
            q3_ = VB * k21 * k32 * (k22 - k43)^-1 * (exp(-k43*t) - exp(-k22*t));
            q4_ = VB * k21 * k32 * k43 * ( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)));
            q234 = conv(q2_ + q3_ + q4_, cart);
            q234 = q234(1:len);
            Q    = VB * cart + q234;  
        end
        function f = VBtoFB(v)
            % 1/s
            f = 0.076339*v^0.671;
        end
    end
    
    methods
        function this = Kinetics4McmcProblem(t, y, ca, pnum, snum)
            this = this@mlbayesian.AbstractMcmcProblem(t, y);
            this.Ca = ca;
            this.pnumber = pnum;
            this.snumber = snum;
            this.gluTxlsx_ = mlarbelaez.GluTxlsx;               
            this.k04 = this.K04;
            this.expectedBestFitParams_ = ...
                [this.k04 this.k12 this.k21 this.k32 this.k43 this.t0];
        end
        function Q = itsConcentrationQ(this)
            Q = this.concentrationQ(this.k04, this.k12, this.k21, this.k32, this.k43, this.t0, this.Ca, this.VB, this.dt, this.times);
        end
        function this = estimateParameters(this, varargin)
            ip = inputParser;
            addOptional(ip, 'map', this.map, @(x) isa(x, 'containers.Map'));
            parse(ip, varargin{:});
            
            import mlbayesian.*;
            this.paramsManager = BayesianParameters(varargin{:});
            this.paramsManager.nBeta = 100;
            this.ensureKeyOrdering({'k04' 'k12' 'k21' 'k32' 'k43' 't0'});
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
            this.k04 = this.finalParams('k04');
            this.k12 = this.finalParams('k12');
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
        function Q    = estimateDataFast(this, k04, k12, k21, k32, k43, t0)
            Q = this.concentrationQ(k04, k12, k21, k32, k43, t0, this.Ca, this.VB, this.dt, this.times);
        end        
        
        function        plotProduct(this)
            figure;
            max_ecat = max(max(this.itsConcentrationQ), max(this.dependentData));
            max_aif  = max(this.Ca);
            
            plot(this.times, this.itsConcentrationQ / max_ecat, ...
                 this.times, this.dependentData     / max_ecat, ...
                 this.times, this.Ca                / max_aif);
            legend('concentration_{ecat}', 'data_{ecat}', ...
                   'concentration_{art}'); 
            title(this.detailedTitle, 'Interpreter', 'none');
            xlabel(this.xLabel);
            ylabel(sprintf('arbitrary:  ECAT norm %g, AIF norm %g', max_ecat, max_aif));
        end  
        function        plotParVars(this, par, vars)
            assert(lstrfind(par, properties('mlarbelaez.Kinetics4McmcProblem')));
            assert(isnumeric(vars));
            switch (par)
                case 'k04'
                    for v = 1:length(vars)
                        args{v} = { vars(v)  this.k12 this.k21 this.k32 this.k43 this.t0 this.Ca this.VB this.dt this.times }; end
                case 'k12'
                    for v = 1:length(vars)
                        args{v} = { this.k04 vars(v)  this.k21 this.k32 this.k43 this.t0 this.Ca this.VB this.dt this.times }; end
                case 'k21'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12 vars(v)  this.k32 this.k43 this.t0 this.Ca this.VB this.dt this.times }; end
                case 'k32'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12 this.k21 vars(v)  this.k43 this.t0 this.Ca this.VB this.dt this.times }; end
                case 'k43'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12 this.k21 this.k32 vars(v)  this.t0 this.Ca this.VB this.dt this.times }; end
                case 't0'
                    for v = 1:length(vars)
                        args{v} = { this.k04 this.k12 this.k21 this.k32 this.k43 vars(v) this.Ca this.VB this.dt this.times }; end
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
            title(sprintf('k04 %g, k12 %g, k21 %g, k32 %g, k43 %g, t0 %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

