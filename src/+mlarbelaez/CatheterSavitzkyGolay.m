classdef CatheterSavitzkyGolay  
	%% CATHETERSAVITZKYGOLAY analyzes data from catheter-lines used in quantitative PET.  In particular,  
    %  H_2[^{15}O] and [^{15}O]O tracers are sampled from radial-artery cannulation, the samplings are deconvoluted and
    %  modeled with PET autoradiography frameworks so as to estimate blood flow and oxygen metabolism (Raichle,
    %  Herscovitch, Videen, 1980s). The catheter is typically inserted into the radial artery, in situ, passed in-line
    %  through a beta-particle detector and connected to a peristaltic pump set to a known, fixed pumping rate.  This
    %  class analyzes calibration data from a phantom (per Avi Snyder, ca. 1985) that provides an ex vivo, labeled blood
    %  source with activity that is a Heaviside function in time.  The time-derivative of the the Heaviside gives the
    %  intrinsic dynamic response of the catheter expressed as a convolution kernel.  The kernel estimates
    %  delay/dispersion from the catheter; it may be used by clients of this class for deconvolution tasks.
    %
    %  The catheter data will typically be modulated sinusoidally by the pumping rate of the peristaltic pump. There
    %  will also be noise from the detection electronics.  Estimating the catheter's intrinsic convolution kernel must
    %  account for these.  This class uses Savitzky-Golay methods to create piece-wise polynomial fits to the
    %  phantom-catheter data; the time-derivative of the polynomials estimates the kernel. The data should first be
    %  explored with Matlab-native Savitzky-Golay smoothing to determine suitable smoothing intervals and polynomial
    %  order.   The time-derivative, or kernel, is estimated using mex-routines based on Numerical Recipes, 3rd edition,
    %  section 14.9.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id

	properties
        dccrv
        times
        kernelBest
        kernelBestintervalKernel = 1:102 
    end 
    
    properties (Dependent)
        counts
        degree
        span
    end
    
    methods %% GET/SET
        function c = get.counts(this)
            c = this.dccrv.counts(this.times);
        end
        function d = get.degree(this)
            d = this.degree_;
        end
        function this = set.degree(this, d)
            this.degree_ = d;
            assert(this.degree > 1); 
        end
        function s = get.span(this)
            s = this.span_;
        end
        function this = set.span(this, s)
            this.span_ = s;
            assert(1 == mod(s,2)); % must be odd  
        end
    end

	methods 
        function [xss, xsk] = explore(this, spans, degrees)
            xss = this.exploreSmoothed(spans, degrees);
            xsk = this.exploreKernels( spans, degrees);
        end
        function xs = exploreSmoothed(this, spans, degrees)
            assert(all(1 == mod(spans, 2))); 
            assert(all(degrees > 1));
            
            S  = length(spans);
            D  = length(degrees);
            xs = zeros(length(this.ensurePower2(this.counts)),S,D);
            for d = 1:D
                for s = 1:S
                    this.span   = spans(s);
                    this.degree = degrees(d);
                    try
                        xs(:,s,d) = this.smoothedCounts;
                    catch ME
                        handexcept(ME);
                    end
                end
            end
            this.mplot(xs, spans, degrees);
        end
        function xs = exploreKernels(this, spans, degrees)
            assert(all(1 == mod(spans, 2))); 
            assert(all(degrees > 1));
            
            S  = length(spans);
            D  = length(degrees);
            xs = zeros(length(this.ensurePower2(this.counts)),S,D);
            for d = 1:D
                for s = 1:S
                    this.span   = spans(s);
                    this.degree = degrees(d);
                    try
                        xs(:,s,d)   = this.kernel;
                    catch ME
                        handexcept(ME);
                    end
                end
            end
            scale = max(this.counts) / max(max(max(xs)));
            this.mplot(scale*xs, spans, degrees);
        end
        function s = savitzkyGolay(this, data, nl, nr, orderDeriv)
            
            data2 = this.ensurePower2(data);            
            assert(this.uniformSampling);          
            assert(nl + nr + 1 < length(data2)); % required by savgol.h
            assert(nl + nr >= this.degree);
            s = mxSavitzkyGolay(data2, nl + nr + 1, nl, nr, orderDeriv, this.degree); 
        end
        function s = smoothedCounts(this)
            
            nl = (this.span - 1)/2;
            nr = nl;            
            s  = this.savitzkyGolay(this.counts, nl, nr, 0);
            s  = s';
        end
        function k = kernel(this)
            %% KERNEL returns the convolution kernel consistent with Heaviside input and output from this.counts;
            %  cf. Numerical Recipes, 3rd ed., sec. 14.9 Savitzky-Golay Smoothing Filters
            
            nl = (this.span - 1)/2;
            nr = nl;            
            k  = this.savitzkyGolay(this.counts, nl, nr, 1); 
            dt = this.times(2) - this.times(1);
            k  = k / dt;
            k  = k / sum(abs(k));
            k  = k';
        end
        function d = deconvSynth(this)
            n2_lub = log(length(this.counts)) / log(2);
            n2     = ceil(n2_lub);
            
            synthCounts = conv(this.kernelBest, [0 ones(1,length(this.counts)-1)]);
            %synthCounts = synthCounts(1:length(this.counts));
            
            c = zeros(1, 2^(n2 + 1));
            c(1:length(synthCounts)) = synthCounts;
            
            k    = zeros(1, length(c));
            krnl = this.kernelBest; 
            k(1:length(krnl)) = krnl;
            %[~,idxmax] = max(k);
            %k    = circshift(k, [0,-idxmax+1]);
            
            d = ifft(fft(c) ./ fft(k));
            d = d(1:length(this.times));
        end
        function d = deconvSynth2(this)
            
            synthCounts = conv(this.kernelBest, [0 ones(1,255)]);
            synthCounts = synthCounts(1:256);
            
            k    = zeros(1, length(synthCounts));
            krnl = this.kernelBest; 
            k(1:length(krnl)) = krnl;
            [~,idxmax] = max(k);
            k    = circshift(k, [0,-idxmax+1]);
            
            d = ifft(fft(synthCounts) ./ fft(k));
            d = d(1:256);
        end
        function d = deconv(this, interval)
            if (~exist('interval', 'var'))
                interval = this.intervalKernel; 
            end
            
            n      = length(this.smoothedCounts);
            n2_lub = log(n) / log(2);
            n2     = 2^(ceil(n2_lub) + 1);
            c      = zeros(1, n2);
            c(1:n) = this.smoothedCounts;
            
            k    = zeros(1, length(c));
            krnl = this.kernelBest; 
            k(interval) = krnl(interval);
            
            d = ifft(fft(c) ./ fft(k));
            d = d(1:length(this.times));
        end
        function p = powerSpectrum(this)
            p = (fft(this.counts));
            p = p .* conj(p);
        end
        function d = wienerDeconv(this)
        end
		  
 		function this = CatheterSavitzkyGolay(dcc, varargin) 
 			%% CATHETERSAVITZKYGOLAY 
 			%  Usage:  this = CatheterSavitzkyGolay(DecayCorrectedCRV, ['span', 37, 'degree', 4]) 
            %                                       ^ filename, CRV, or DecayCorrectedCRV for ex vivo sampling of
            %                                         Heaviside inputs

            import mlpet.*;
            switch (class(dcc))
                case 'char'
                    this.dccrv = DecayCorrectedCRV.load(dcc);
                case 'mlpet.CRV'
                    this.dccrv = DecayCorrectedCRV(dcc);
                case 'mlpet.DecayCorrectedCRV'
                    this.dccrv = dcc;
                otherwise
                    error('mlpet:unsupportTypeclass', ...
                          'CatheterSavitzkyGolay.ctor.dcc is from unsupported class %s', class(dcc));
            end
            
            ip = inputParser;
            addParameter(ip, 'span',   this.span_,       @(x) isinteger(x) && 1 == mod(x,2));
            addParameter(ip, 'degree', this.degree_,     @isinteger);
            addParameter(ip, 'times',  this.dccrv.times, @isnumeric);
            parse(ip, varargin{:});
            this.span   = ip.Results.span;
            this.degree = ip.Results.degree;
            this.times  = ip.Results.times;
            crk         =  mlpet.CatheterResponseKernels('kernelBest');
            this.kernelBest = crk.kernel;
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')        
        degree_ = 9
        span_ = 33
    end
    
    methods (Access = 'private')
        function tf = uniformSampling(this)
            taus = this.times(2:end) - this.times(1:end-1);
            taus = taus / (this.times(2) - this.times(1));
            tf = all(1 == taus);
        end
        function y = ensurePower2(this, y)
            %% ENSUREPOWER2 zero-pads y to ensure length(y) == 2^n >= length(y_0), n \in \mathbb{N}
            
            leny = length(y);
            n0   = log(leny)/log(2);
            if (0 == n0 - floor(n0))
                return
            end
            n    = 1;
            while (2^n < leny)
                n = n + 1;
            end
            y = this.appendZeros(2^n - leny, y);
        end
        function y = appendZeros(~, n, y)
            %% APPENDZEROS appends n zeros to y, preserving row or col shape
            
            if (size(y,2) > size(y,1)) 
                % row vector
                y = [y zeros(1,n)];
            else
                % col vector
                leny = length(y);
                y0   = zeros(leny+n,1);
                for iy = 1:leny
                    y0(iy) = y(iy);
                end
                y = y0;
            end
        end
        function plot(this, x, sp, deg)
            figure;    
            plot(this.times, this.counts, 'Marker', 'o');
            hold on;
            plot(this.times, x); %, 'k-');
            hold off;
            axis tight;
            title(sprintf('CatheterSavitzkyGolay.plot: span=%g, degree=%g', sp, deg));
            xlabel('time/arbitrary');
        end
        function mplot(this,xs, sps, degs)
            figure;
            S = length(sps);
            D = length(degs);
            for d = 1:D
                subplot(D,1,d);
                plot(this.times, this.counts, 'Color', [0 0 0], 'Marker', 'o');
                hold on;
                for s = 1:S
                    plot(xs(:,s,d)); %, '-', 'Color', (0.5-0.5*s/S)*[1 1 1]);
                end
                hold off;
                axis tight;
                title(sprintf('CatheterSavitzkyGolay.mplot: span=%s, degree=%g', mat2str(sps), degs(d)));
                legend(['native' cellfun(@(x) sprintf('span = %g', x), num2cell(sps), 'UniformOutput', false)]);
            end
            xlabel('time/arbitray');
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

