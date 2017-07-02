classdef CRV < mlpet.CRV
	%% CRV  

	%  $Revision$
 	%  was created 29-Jun-2017 21:14:36 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.

    
    properties (Constant)
        EMBEDDING_INDICES = 13:46
    end
    
    properties (Dependent)
        Nt
    end
    
	properties
        bump = 0.1
        kernelBestFqfn
 		kernelBest
        tHalf = 122.24 % sec, for [15O]
 	end

    methods (Static)
        function k = fittedKernel(t)
            a1 = 7.163;
            b1 = 0.6001;
            t01 = 0; %8.834;
            a2 = 8.424;
            b2 = 0.9980;
            t02 = 14.41; %22.83;
            weight1 = 0.8717;
            k = mlbayesian.GeneralizedGammaTerms.gammaSeries(a1, b1, t01, a2, b2, t02, weight1, t);
            k = k/sum(k);
        end
        function this = load(fileLoc)
            this = mlarbelaez.CRV(fileLoc);
        end
    end
    
	methods 
        
        %% GET
        
        function g = get.Nt(this)
            g = (this.times(2) - this.times(1))/this.dt;
        end
        %%
        
        function c = decayCorrectedCounts(this)
            c = this.counts .* 2.^((this.times - this.times(1))/this.tHalf);
        end        
        function c = decayCorrectedCountInterpolants(this)
            c = this.countInterpolants .* exp((this.timeInterpolants - this.timeInterpolants(1))/this.tHalf);
        end
        function dcv = deconvMeasuredKernel(this)
                        
            len = length(this);
            timeInterp2 = [this.timeInterpolants (this.timeInterpolants(end) + this.dt + this.timeInterpolants - this.times(1))];
            Ninterp = length(timeInterp2);
            domega0 = 2*pi/this.times(1);
            domega = 2*pi/(timeInterp2(end) - this.times(1));
            freqInterp2 = domega0:domega:(domega0+(Ninterp-1)*domega);
            
            kernelEmbedded = zeros(1,len);
            kernelEmbedded(this.EMBEDDING_INDICES) = this.kernelBest(this.EMBEDDING_INDICES);  
            kernelEmbedded = mlbayesian.AbstractMcmcStrategy.slide( ...
                kernelEmbedded, this.times, -this.times(this.EMBEDDING_INDICES(1)));
            
            kernelPchip = pchip(this.times, kernelEmbedded, this.timeInterpolants);
            kernelPchip = [kernelPchip kernelPchip(end)*ones(size(kernelPchip))]; % 2x length
            kernelPchip = kernelPchip/sum(kernelPchip);
            fftKernelPchip = fft(kernelPchip);
            fftKernelPchip = fftKernelPchip + this.bump*max(fftKernelPchip)*ones(size(fftKernelPchip));            
            responsePchip = concatReflection( ...
                pchip(this.times, this.decayCorrectedCounts, this.timeInterpolants));
            fftResponsePchip = fft(smooth(responsePchip, 2*this.Nt)'); 
            dcv = abs(ifft(fftResponsePchip./fftKernelPchip));
            dcv = mlbayesian.AbstractMcmcStrategy.slide(dcv, timeInterp2, -timeInterp2(this.EMBEDDING_INDICES(13)));
            
            figure; plot(timeInterp2, responsePchip, timeInterp2, kernelPchip);
            xlabel('t');
            title('response, kernel');
            figure; plot(freqInterp2, abs(fftResponsePchip), freqInterp2, abs(fftKernelPchip));
            xlabel('\omega');
            title('fft(response), fft(kernel)');
            legend('Abs resp(\omega)', 'Abs ker(\omega)');
            figure; plot(timeInterp2, responsePchip, timeInterp2, dcv);
            xlabel('t');
            title('response, responseDcv');
        end
        function dcv = smoothDeconv(this, varargin)                        
            
            timeInterp2 = [this.timeInterpolants (this.timeInterpolants(end) + this.dt + this.timeInterpolants - this.times(1))];
            
            kernelPchip = this.fittedKernel(timeInterp2);
            fftKernelPchip = fft(kernelPchip);
            fftKernelPchip = fftKernelPchip + this.bump*max(fftKernelPchip)*ones(size(fftKernelPchip));            
            responsePchip = concatReflection( ...
                pchip(this.times, this.decayCorrectedCounts, this.timeInterpolants));
            fftResponsePchip = fft(smooth(responsePchip, 2*this.Nt)'); 
            dcv = abs(ifft(fftResponsePchip./fftKernelPchip));
            dcv = smooth(dcv, varargin{:});
            dcv = mlbayesian.AbstractMcmcStrategy.slide(dcv, timeInterp2, -8.834);
            
            figure;
            plot(timeInterp2, responsePchip, timeInterp2, dcv);
            xlabel('t');
            title('response; responseDcv');
        end
        function [dcv,gof,out,dcvRaw] = fitDeconv(this, varargin)                        
            
            timeInterp2 = [this.timeInterpolants (this.timeInterpolants(end) + this.dt + this.timeInterpolants - this.times(1))];
            
            kernelPchip = this.fittedKernel(timeInterp2);
            fftKernelPchip = fft(kernelPchip);
            fftKernelPchip = fftKernelPchip + this.bump*max(fftKernelPchip)*ones(size(fftKernelPchip));            
            responsePchip = concatReflection( ...
                pchip(this.times, this.decayCorrectedCounts, this.timeInterpolants));
            fftResponsePchip = fft(smooth(responsePchip, 2*this.Nt)'); 
            dcvRaw = abs(ifft(fftResponsePchip./fftKernelPchip));
            [dcv,gof,out] = fit(timeInterp2', dcvRaw', varargin{:});
            
            figure;
            plot(timeInterp2, responsePchip);
            xlabel('t');
            title('response');
            figure;
            plot(dcv, timeInterp2, dcvRaw);
            xlabel('t');
            title('responseDcv');
        end
		  
 		function this = CRV(varargin)
 			%% CRV
 			%  Usage:  this = CRV(file_location) 
            %          this = CRV('/path/to/p1234data/p1234ho1.crv')
            %          this = CRV('/path/to/p1234data/p1234ho1')
            %          this = CRV('p1234ho1')

 			this = this@mlpet.CRV(varargin{:});
            this.kernelBestFqfn = '~/Tmp/kernel6_span33_deg4.mat'; %fullfile(getenv('ARBELAEZ'), 'jjlee', 'GluT', 'kernel6_span33_deg4.mat');
            load(this.kernelBestFqfn);
            this.kernelBest = kernel;
            this.dt = 0.1;
 		end
    end 
    
    %% PROTECTED
    
    methods (Access = protected)
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

