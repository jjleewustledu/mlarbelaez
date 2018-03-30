classdef ThreeCompartmentsSimulator  
	%% THREECOMPARTMENTSSIMULATOR is insensitive to FB, k32; default simulation is for p5661

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
        
        VB = 0.0369 % fraction
        FB = 0.5769 / 60 % 1/sec
        Q 
        Ca
        k04fixed = 0.26057 % 0.5769 / (0.0369 * 60);
        k12      = 0.0010001
        k21      = 0.0650655
        k32      = 1.12944e-06
        t0       = 99.1327
        volume   = 488 % mL, slices 6-16
        
        dta
        tsc
    end

    methods (Static)
        function this = simulateDefault
            import mlpet.* mlarbelaez.*;
            
            pwd0 = pwd;
            cd('/Volumes/PassportStudio2/Arbelaez/GluT/jjlee/np15/p5661');
            dta_ = DTA.load('p5661g.dta');
            tsc_ = TSC.import('p5661wb.tsc');
            this = ThreeCompartmentsSimulator(dta_, tsc_);
            this.plot;
            cd(pwd0);
        end
        function this = varyParameters(paramName)
            import mlarbelaez.* mlpet.*;
            dta_ = DTA.load('p5661g.dta');
            tsc_ = TSC.import('p5661wb.tsc');
            this = ThreeCompartmentsSimulator(dta_, tsc_);
            rng  = this.createRange(this.(paramName));
            Qs   = cell(1,this.Nvariations);
            for p = 1:this.Nvariations
                this.(paramName) = rng(p);
                Qs{p} = this.estimateQFast(this.k04fixed, this.k12, this.k21, this.k32, this.t0);
            end
            this.plotVariation(Qs, paramName, rng);
        end
        function this = createSimulatedTsc
            import mlarbelaez.*;
            this = ThreeCompartmentsSimulator.simulateDefault;            
            cd('/Volumes/PassportStudio2/Arbelaez/GluT/jjlee/np15/p5661_JJL');
            fid = fopen('p5661wb.tsc', 'w');
            fprintf(fid, '30   decay_corrected_tissue_activity\n');
            fprintf(fid, '   54  3\n');
            for t = 1:this.tsc.length-1
                Qsum = sum(this.Q( this.tsc.times(t)+1:this.tsc.times(t+1) ));
                fprintf(fid, '%11.2f%11.2f%11.2f\n', this.tsc.times(t), this.tsc.taus(t), Qsum);
            end
            fprintf(fid, '%11.2f%11.2f%11.2f\n', this.tsc.times(end), this.tsc.taus(end), Qsum);
            fprintf(fid, 'whole brain slices 6 to 16');
            fclose(fid);
        end
    end
    
	methods 		  
 		function this = ThreeCompartmentsSimulator(dta, tsc)
 			%% ThreeCompartmentsSimulator 
 			%  Usage:  this = ThreeCompartmentsSimulator(dta_location) 

            p = inputParser;
            addRequired(p, 'dta', @(x) isa(x, 'mlpet.DTA'));
            addRequired(p, 'tsc', @(x) isa(x, 'mlpet.TSC'));
            parse(p, dta, tsc);
            
            import mlarbelaez.*;
            this.dta = p.Results.dta;
            this.tsc = p.Results.tsc;
            [this.timeInterpolants,this.dt] = this.interpolateTimes;
            this.Ca = this.interpolateCaCounts;
            this.Q  = this.estimateQFast(this.k04fixed, this.k12, this.k21, this.k32, this.t0);
        end 
        function [t,dt] = interpolateTimes(this)
            %% INTERPOLATETIMES from this.dta, this.tsc to uniform raster, as required for convolution
            %  Usage:  [timeInterpolants,dt] = this.interpolateTimes;
            
            t_last = max(this.dta.times(end), this.tsc.times(end));
            dt     = 1; % min([this.dta.taus this.tsc.taus]);
            t      = 0:dt:t_last;
        end
        function c = interpolateCaCounts(this)
            %% INTERPOLATECACOUNTS 
            %  Usage:  interpolated_counts = FourCompartmentSimulator.interpolateCaCounts
            
            c = pchip(this.dta.times, this.dta.counts, this.timeInterpolants);
            c = c(1:length(this.timeInterpolants));
        end
        function Q = estimateQFast(this, k04, k12, k21, k32, t0)         
            k22 = k12 + k32;
            t = this.timeInterpolants;
            
            t0_idx               = floor(t0/this.dt) + 1;
            cart                 = this.Ca(end) * ones(1, this.length);
            cart(1:end-t0_idx+1) = this.Ca(t0_idx:end); 
            
            q2_ = this.VB * k21 * exp(-k22*t);
            q3_ = this.VB * k21 * k32 * (k22 - k04)^-1 * (exp(-k04*t) - exp(-k22*t));
            q23 = conv(q2_ + q3_, cart);
            q23 = q23(1:length(t));
            Q   = this.VB * cart + q23;
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
            text(618, 11000, sprintf('max(Ca) = %f; max(Q) = %f; max(TSC) = %f', ...
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

