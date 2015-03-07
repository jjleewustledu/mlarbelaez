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
        showPlots = true
        pnumber
        snumber
        baseTitle = 'Kinetics4McmcProblem'
        xLabel    = 'times'
        yLabel    = 'wellcounts'
        
        Ca
        dt = 1
    end
    
    properties (Dependent)
        gluTxlsxInfo
        VB
        FB
        K04
    end
    
    methods %% GET
        function inf = get.gluTxlsxInfo(this)
            inf = this.gluTxlsx_.pid_map(this.pnumber).(sprintf('scan%i', this.snumber));
        end
        function v = get.VB(this)        
            % fraction
            v = this.gluTxlsxInfo.cbv;
            if (v > 1)
                v = v/100; end
        end
        function f = get.FB(this)            
            % fraction/s
            f = this.gluTxlsxInfo.cbf;
            if (isnumeric(f) && ~isnan(f))
                f = f/6000; % mL/min/100g to 1/s
            else
                f = this.VBtoFB(this.VB); 
            end
        end
        function k = get.K04(this)
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
            Ca_ = dta.countInterpolants(1:len);
            Q_  = tsc.becquerelInterpolants(1:len);            
            %figure; plot(timeInterp, Ca_, timeInterp, Q_)
            
            kmp = mlarbelaez.Kinetics4McmcProblem(timeInterp, Q_, Ca_, pnum, snum);
            kmp.baseTitle = tscFqfp;
            kmp = kmp.estimateParameters;
            k   = [kmp.finalParams('k04'), kmp.finalParams('k12'), kmp.finalParams('k21'), ...
                   kmp.finalParams('k32'), kmp.finalParams('k43'), kmp.finalParams('t0')]; 
            figure; 
            plot(timeInterp, Ca_, timeInterp, kmp.estimateData, tsc.times, tsc.counts./tsc.taus, 'o');
            xlabel('time/s');
            ylabel('counts/well-counts');
            title(tscFqfp, 'Interpreter', 'none');
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
        end
        function this = estimateParameters(this)
            %% ESTIMATEPARAMETERS
            %  expected_parameters = [0.2606 4.7967e-04 0.0348 0.0025 4.2528e-04 4.3924]; % k04 k12 k21 k32 k43 t0
            
            import mlbayesian.*;
            map = containers.Map;
            map('k04') = struct('fixed', 1, 'min',    0, 'mean', this.K04,   'max', 1); 
            map('k12') = struct('fixed', 0, 'min', 2e-3, 'mean', 0.00047967, 'max', 0.02);
            map('k21') = struct('fixed', 0, 'min', 0.04, 'mean', 0.034772,   'max', 0.09);
            map('k32') = struct('fixed', 0, 'min', 1e-3, 'mean', 0.0025173,  'max', 8);
            map('k43') = struct('fixed', 1, 'min', 2e-4, 'mean', 0.00042528, 'max', 0.004);  
            map('t0' ) = struct('fixed', 0, 'min',    0, 'mean', 30,         'max', 30);  

            this.paramsManager = BayesianParameters(map);
            this.mcmc          = MCMC(this, this.dependentData, this.paramsManager);
            [~,~,this.mcmc]    = this.mcmc.runMcmc;
        end
        function ed   = estimateData(this)
            ed = this.estimateDataFast( ...
                this.finalParams('k04'), this.finalParams('k12'), this.finalParams('k21'), ...
                this.finalParams('k32'), this.finalParams('k43'), this.finalParams('t0'));
        end
        function Q    = estimateDataFast(this, k04, k12, k21, k32, k43, t0)            
            k22 = k12 + k32;
            t = this.timeInterpolants;
            
            t0_idx               = floor(t0/this.dt) + 1;
            cart                 = this.Ca(end) * ones(1, this.length);
            cart(1:end-t0_idx+1) = this.Ca(t0_idx:end); 
            
            q2_ = this.VB * k21 * exp(-k22*t);
            q3_ = this.VB * k21 * k32 * (k22 - k43)^-1 * (exp(-k43*t) - exp(-k22*t));
            q4_ = this.VB * k21 * k32 * k43 * ( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)));
            q234 = conv(q2_ + q3_ + q4_, cart);
            q234 = q234(1:length(t));
            Q    = this.VB * cart + q234;    
        end   
    end
    
    %% PRIVATE

    properties (Access = 'private')
        gluTxlsx_
    end
    
    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

