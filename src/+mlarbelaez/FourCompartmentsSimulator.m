classdef FourCompartmentsSimulator  
	%% FOURCOMPARTMENTSSIMULATOR is insensitive to FB, k32; default simulation is for p5661

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
        dt
        timeInterpolants
        
        FB = 0.5769 / 60 % 1/sec
        VB = 0.0369 % fraction
        Q 
        Ca
        k12 = 0.28780E-01 / 60 % 1/sec
        k21 = 2.0863 / 60
        k32 = 0.15104 / 60
        k43 = 0.25517E-01 / 60
        k04fixed = 0.5769 / (0.0369 * 60);
        t0  = 4.3924 * 60 % sec
        volume = 488 % mL, slices 6-16
        
        dta
        tsc
    end

    methods (Static)
        function this   = simulateDefault
            import mlpet.* mlarbelaez.*;
            dta_ = DTA.load('p5661cg1.dta');
            tsc_ = TSC.import('p5661wb.tsc');
            this = FourCompartmentsSimulator(dta_, tsc_);
            this.plot;
        end
        function this   = varyParameters(paramName)
            import mlarbelaez.* mlpet.*;
            dta_ = DTA.load('p5661cg1.dta');
            tsc_ = TSC.import('p5661wb.tsc');
            this = FourCompartmentsSimulator(dta_, tsc_);
            rng  = this.createRange(this.(paramName));
            Qs   = cell(1,this.Nvariations);
            for p = 1:this.Nvariations
                this.(paramName) = rng(p);
                Qs{p} = this.estimateQFast(this.k04fixed, this.k12, this.k21, this.k32, this.k43, this.t0);
            end
            this.plotVariation(Qs, paramName, rng);
        end
        function [t,dt] = interpolateTimes(dtaTimes, tscTimes)
            %% INTERPOLATETIMES to linear raster, as required for convolution
            %  Usage:  [t,dt] = FourCompartmentSimulator.interpolateTimes( ...
            %                   raw_times, raw_times2) % raw times may have unique, nonuniform rasters
            
            t_last  = min(dtaTimes(end), tscTimes(end));
            dtaTaus = dtaTimes(2:end) - dtaTimes(1:end-1);
            tscTaus = tscTimes(2:end) - tscTimes(1:end-1);
            dt      = min([dtaTaus tscTaus]);
            t       = 0:dt:t_last;
        end
        function c      = interpolateCounts(times, counts, timeInterpolants)
            %% INTERPOLATECOUNTS 
            %  Usage:  interpolated_counts = FourCompartmentSimulator.interpolateCounts( ...
            %                                raw_times, raw_counts, interpolated_times)
            
            c = spline(times, counts, timeInterpolants);
            c = c(1:length(timeInterpolants));
        end
    end
    
	methods 		  
 		function this = FourCompartmentsSimulator(dta, tsc)
 			%% FOURCOMPARTMENTSSIMULATOR 
 			%  Usage:  this = FourCompartmentsSimulator(dta_location) 

            p = inputParser;
            addRequired(p, 'dta', @(x) isa(x, 'mlpet.DTA'));
            addRequired(p, 'tsc', @(x) isa(x, 'mlpet.TSC'));
            parse(p, dta, tsc);
            
            import mlarbelaez.*;
            this.dta = p.Results.dta;
            this.tsc = p.Results.tsc;
            [this.timeInterpolants,this.dt] = FourCompartmentsSimulator.interpolateTimes( ...
                                              this.dta.times, this.tsc.times);
            this.Ca = FourCompartmentsSimulator.interpolateCounts( ...
                      this.dta.times, this.dta.counts, this.timeInterpolants);
            this.Q  = this.estimateQFast(this.k04fixed, this.k12, this.k21, this.k32, this.k43, this.t0);
        end 
        function Q = estimateQFast(this, k04, k12, k21, k32, k43, t0)
            k22 = k12 + k32;
            t = this.timeInterpolants;
            
            q1 = this.VB * this.Ca;
            q2 = this.VB * k21 * this.dt * conv(exp(-k22*t), this.Ca);
            q3 = this.VB * k21 * k32 * (k22 - k43)^-1 * this.dt * conv(exp(-k43*t) - exp(-k22*t), this.Ca);
            q4 = this.VB * k21 * k32 * k43 * this.dt * conv( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)), ...
                     this.Ca); 
            Q0 = q1 + q2(1:length(t)) + q3(1:length(t)) + q4(1:length(t));
            
            t0_idx        = floor(t0/this.dt);
            Q             = zeros(size(Q0));
            Q(t0_idx:end) = Q0(1:end-t0_idx+1);
        end  
        function Q = estimateQFast2(this, k04, k12, k21, k32, k43, t0)
            %k11 = this.FB/this.VB + k21;
            k22 = k12 + k32;
            a = 0.5 * (k12 + k32 + k43 - sqrt((k12 + k32 + k43)^2 - 4*k12*k43));
            b = 0.5 * (k12 + k32 + k43 + sqrt((k12 + k32 + k43)^2 - 4*k12*k43));
            t = this.timeInterpolants;
            
            qb1 = (b - a)^-1 * ((k22 - a) * exp(-a*t) + (b - k22) * exp(-b*t));
            qb2 = k21 * (b - a)^-1 * (exp(-a*t) - exp(-b*t));
            qb3 = k21 * k32 * (exp(-a*t) / ((b - a) * (k43 - a)) + exp(-b*t) / ((b - a) * (b - k43)) + exp(-k43*t) / ((k43 - b) * (k43 - a)));
            qb4 = k21 * k32 * k43 * ( ...
                     exp(-a*t)   / ((b   - a) * (k43 - a) * (k04 - a)) + ...
                     exp(-b*t)   / ((a   - b) * (k43 - b) * (k04 - b)) + ...
                     exp(-k43*t) / ((k43 - a) * (k43 - b) * (k04 - k43)) + ...
                     exp(-k04*t) / ((a - k04) * (b - k04) * (k43 - k04)));
            Q0 = this.FB * conv(qb1 + qb2 + qb3 + qb4, this.Ca);
            Q0 = Q0(1:length(t));  
            
            t0_idx        = floor(t0/this.dt);
            Q             = zeros(size(Q0));
            Q(t0_idx:end) = Q0(1:end-t0_idx+1);          
        end
        function plot(this)
            figure; hold on;
            plot(this.dta.times, this.dta.counts, 'Marker', 'o', 'Linestyle', 'none');
            plot(this.timeInterpolants, this.Q);
            counts = this.tsc.counts ./ this.tsc.taus;                        
            plot(this.tsc.times, counts,          'Marker', 'o', 'LineStyle', 'none'); % well counts/mL/s
            title('p5661, glucnoflow simulation');
            ylabel('well counts/mL/s');
            xlabel('time/s');
            legend('TSC.counts', 'no-flow 4-compartment Q', 'TSC.counts');
            legend('boxoff');
            text(618, -618, sprintf('max(Ca) = %f; max(Q) = %f; max(TSC) = %f', ...
                max(this.Ca), max(this.Q), max(this.tsc.counts ./ this.tsc.taus)));
            hold off;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')        
        Nvariations = 7;
    end
    
    methods (Access = 'private')        
        function rng = createRange(this, value0)
            rng(1) =      value0 / 8;
            rng(2) =      value0 / 4;
            rng(3) =      value0 / 2;
            rng(4) =      value0;
            rng(5) =  2 * value0;
            rng(6) =  4 * value0;
            rng(7) =  8 * value0;
            assert(this.Nvariations == length(rng));
        end
        function plotVariation(this, Qs, paramName, paramValues)
            figure; hold on;
            for qi = 1:length(Qs)
                plot(this.timeInterpolants, Qs{qi}); end
            title(sprintf('p5661, glucnoflow:  varying %s [%f %f]', paramName, paramValues(1), paramValues(end)));
            ylabel('well counts/mL/s');
            xlabel('time/s');
            paramValuesCell = num2cell(paramValues);
            paramValuesCell = cellfun(@(x) num2str(x), paramValuesCell, 'UniformOutput', false);
            legend(paramValuesCell);
            legend('boxoff');
            hold off;
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

