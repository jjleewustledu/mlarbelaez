classdef RegionalKinetics4 < mlbayesian.AbstractMcmcProblem
	%% REGIONALKINETICS4 is a stand-alone implementation of the 4-compartment model from
    %  William J. Powers, et al.  Cerebral Transport and Metabolism of 1-[11C]-D-Glucose During Stepped Hypoglycemia.
    %  Annals of Neurology 1995 38(4) 599-609.

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
        
        xLabel = 'times/s'
        yLabel = 'concentration/(wellcounts/mL)'
    end
    
    properties (Dependent)
        baseTitle
        detailedTitle
        dta
        measurements        
        map
        VB
        FB
        K04
        parameters
    end
    
    methods %% GET
        function bt = get.baseTitle(this)
            bt = sprintf('%s %s', class(this), this.measurements.pnumber);
        end
        function dt = get.detailedTitle(this)
            dt = sprintf('%s\n%s\nk04 %g, k21 %g, k12frac %g, k32 %g, k43 %g, t0 %g, VB %g, FB %g', ...
                         this.baseTitle, ...
                         this.measurements.scanIndex, ...
                         this.measurements.region, ...
                         this.k04, this.k21, this.k12frac, this.k32, this.k43, this.t0, this.VB, this.FB);
        end
        function d  = get.dta(this)
            d = this.measurements.dta;
            assert(~isempty(d));
        end
        function m  = get.measurements(this)
            m = this.measurements_;
            assert(~isempty(m));
        end        
        function m  = get.map(this)
            m = containers.Map;
            fL = 1; fH = 1;
            m('k04')     = struct('fixed', 1, 'min', 0*fL,       'mean', this.K04,     'max', 1*fH); 
            m('k12frac') = struct('fixed', 0, 'min', 0.0387*fL,  'mean', this.k12frac, 'max', 0.218*3);    % Powers' monkey paper
            m('k21')     = struct('fixed', 0, 'min', 0.0435*fL,  'mean', this.k21,     'max', 0.0942*fH);  % "
            m('k32')     = struct('fixed', 0, 'min', 0.0015*fL,  'mean', this.k32,     'max', 0.5589*fH);  % " excluding last 2 entries
            m('k43')     = struct('fixed', 0, 'min', 2.03e-4*fL, 'mean', this.k43,     'max', 3.85e-4*fH); % "
            m('t0' )     = struct('fixed', 1, 'min',-2e2*fL,     'mean', this.t0,      'max', 2e2*fH);  
        end
        function v  = get.VB(this)
            % fraction
            v = this.measurements.vFrac;
            if (v > 1)
                v = v/100; end % mL/100g to fraction
        end
        function f  = get.FB(this)
            % fraction/s
            f = this.measurements.fFrac;
            assert(~isnumeric(f) || ~isnan(f), 'mlarbelaez:nan', '%s.get.FB', mfilename);
            if (f > 1)
                f = 1.05 * f / 6000; end % mL/min/100g to 1/s
        end
        function k  = get.K04(this)
            % 1/s
            k = this.FB/this.VB;
        end
        function p  = get.parameters(this)            
            p   = [this.finalParams('k04'), this.finalParams('k12frac'), this.finalParams('k21'), ...
                   this.finalParams('k32'), this.finalParams('k43'),     this.finalParams('t0')]; 
        end
    end
    
    methods (Static)
        function [k,rk4] = run(meas)
            rk4 = mlarbelaez.RegionalKinetics4(meas);
            disp(rk4)            
            rk4 = rk4.estimateParameters(rk4.map);
            k   = rk4.parameters; 
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
        function this = RegionalKinetics4(meas)
            this = this@mlbayesian.AbstractMcmcProblem(meas.tsc.times, meas.tsc.becquerels);
            
            ip = inputParser;
            addRequired(ip, 'measurements', @(x) isa(x, 'mlarbelaez.RegionalMeasurements'));
            parse(ip, meas);
            this.measurements_          = ip.Results.measurements;    
            this.k04                    = this.K04;
            this.expectedBestFitParams_ = [this.k04 this.k12frac this.k21 this.k32 this.k43 this.t0];
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
            assert(lstrfind(par, properties('mlarbelaez.RegionalKinetics4')));
            assert(isnumeric(vars));
            switch (par)
                case 'k04'
                    for v = 1:length(vars)
                        args{v} = { vars(v)  this.k12frac this.k21 this.k32 this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
                case 'k12frac'
                    for v = 1:length(vars)
                        args{v} = { this.k04 vars(v)      this.k21 this.k32 this.k43 this.t0 this.dta.wellCounts this.VB this.dt this.times }; end
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
        measurements_
    end
    
    methods (Access = 'private')
        function plotParArgs(this, par, args, vars)
            assert(lstrfind(par, properties('mlarbelaez.RegionalKinetics4')));
            assert(iscell(args));
            assert(isnumeric(vars));
            import mlarbelaez.*;
            figure
            hold on
            for v = 1:size(args,2)
                argsv = args{v};
                plot(this.times, RegionalKinetics4.concentrationQ(argsv{:}));
            end
            title(sprintf('k04 %g, k12frac %g, k21 %g, k32 %g, k43 %g, t0 %g', argsv{1}, argsv{2}, argsv{3}, argsv{4}, argsv{5}, argsv{6}));
            legend(cellfun(@(x) sprintf('%s = %g', par, x), num2cell(vars), 'UniformOutput', false));
            xlabel(this.xLabel);
            ylabel(this.yLabel);
        end
    end    
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

