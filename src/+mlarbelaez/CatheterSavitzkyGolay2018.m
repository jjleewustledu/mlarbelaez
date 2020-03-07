classdef CatheterSavitzkyGolay2018
	%% CATHETERSAVITZKYGOLAY2018  

	%  $Revision$
 	%  was created 26-Aug-2018 00:39:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties
        clip = 1.5
        filename = 'kernelBest.mat'
 		tauHalf = 122.2416 % sec for [15O]
        theCrv
        tTakeoff = 9 % empirical
        tLast = 75
    end
    
    properties (Dependent)
        counts
        degree
        span
        tauDecay
        times
    end

	methods 
        
        %% GET/SET
        
        function c = get.counts(this)
            c = this.theCrv.counts(this.times);
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
        function g = get.times(this)
            if (~isempty(this.times_))
                g = this.times_;
                return
            end
            g = this.theCrv.times;
        end
        function this = set.times(this, s)
            assert(isnumeric(s));
            this.times_ = s;
        end
        
        function g = get.tauDecay(this)
            g = this.tauHalf/log(2);
        end
        
        %%
        
        function xs = exploreSmoothed(this, spans, degrees)
            assert(all(1 == mod(spans, 2))); 
            assert(all(degrees > 1));
            
            S  = length(spans);
            D  = length(degrees);
            xs = zeros(this.lengthPower2_,S,D);
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
            xs = zeros(this.lengthPower2_,S,D);
            for d = 1:D
                for s = 1:S
                    this.span   = spans(s);
                    this.degree = degrees(d);
                    try
                        xs(:,s,d) = this.kernel;
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
            [pc,idx0,idxF] = this.paddedCounts;    
            s  = this.savitzkyGolay(pc, nl, nr, 0);
            s  = s';
            s  = s(idx0:idxF);
        end
        function K    = kernel(this)
            %% KERNEL returns the convolution kernel consistent with Heaviside input and this.counts as output.
            %  Input and output are not decay-corrected.  Kernel K models the decay-correction. 
            %  See also Numerical Recipes, 3rd ed., sec. 14.9 Savitzky-Golay Smoothing Filters.
            
            Nsg = (this.span - 1)/2;
            [pc,idx0,idxF] = this.paddedCounts;
            dcrv_dt = this.savitzkyGolay(pc, Nsg, Nsg, 1)/this.dtime; 
            dcrv_dt = dcrv_dt(idx0:idxF);
            c  = pchip(this.times, this.counts, 0:this.dtime:length(dcrv_dt)-1);
            K  = dcrv_dt + c/this.tauDecay;
            K  = this.kernelRegularized(K);
            K  = K / sum(abs(K));
            K  = K';
        end
        function d    = decay(this, len)
            t = 0:this.dtime:(len-1)*this.dtime;
            d = 2.^(-t/this.tauHalf);
        end
        function dc   = decayCorrection(this, len)
            t = 0:this.dtime:(len-1)*this.dtime;
            dc = 2.^(t/this.tauHalf);
        end
        function h    = decayingHeavi(this, len)
            h = this.Heavi(len) .* this.decay(len);
        end
        function dt   = dtime(this)            
            dt = this.times(2) - this.times(1);
        end
        function h =    Heavi(~, len)
            h = ones(1, len); 
        end
        function        plot(this)
            plot(this.kernelRegularized);
        end
        function crv  = recoveredCrv(this)
            K   = this.kernel;
            crv = conv(K, this.decayingHeavi(length(K)));            
            crv = crv(1:length(K));
        end
        function        save(this)
            kernelBest = this.kernel; %#ok<NASGU>
            save(this.filename, 'kernelBest');
        end
        function this = saveas(this, filename_)
            this.filename = filename_;
            this.save;
        end
		  
 		function this = CatheterSavitzkyGolay2018(aCrv, varargin)
 			%% CATHETERSAVITZKYGOLAY2018
 			%  @param .
 			
            import mlpet.*;
            if (ischar(aCrv))       
                this.theCrv = CRV.load(aCrv);
            end
            if (isa(aCrv, 'mlpet.CRV'))
                this.theCrv = aCrv;
            end
            
            ip = inputParser;
            addParameter(ip, 'span',   this.span_,       @(x) isnumeric(x) && 1 == mod(x,2));
            addParameter(ip, 'degree', this.degree_,     @isnumeric);
            addParameter(ip, 'times',  this.theCrv.times, @isnumeric);
            parse(ip, varargin{:});
            this.span_   = ip.Results.span;
            this.degree_ = ip.Results.degree;
            this.times_  = ip.Results.times;
            this.lengthPower2_ = length(this.ensurePower2(this.theCrv.counts));
 		end
    end
    
    %% PRIVATE
    
    properties (Access = 'private')        
        degree_ = 19
        lengthPower2_
        span_ = 127
        times_
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
        function K    = kernelClippedInput(this, K)
            lenK0 = length(K);
            t     = 0:this.dtime:(lenK0-1)*this.dtime;
            K     = conv(K, exp(-(t - this.clip).^2/(2*this.clip^2)));
            K     = K(1:lenK0);
            K     = K / sum(abs(K));
        end
        function K    = kernelRegularized(this, K)
            
            
            % dK/dt < 0 after tPeak
%             [~,tPeak] = max(K);
%             for t = tPeak+1:length(K)
%                 if (K(t) > K(t-1))
%                     K(t) = K(t-1);
%                 end
%             end
            
            % nonnegative K
            K(1:this.tTakeoff) = 0;
            K(this.tLast:end) = 0;
            K(K < 0) = 0;
            K = K / sum(abs(K));
        end
        function [pc,idx0,idxF] = paddedCounts(this)
            len = length(this.counts);
            pc = [linspace(0, this.counts(1), len) this.counts this.tailOfCounts];
            idx0 = len + 1;
            idxF = idx0 + this.lengthPower2_ - 1;
            
            %figure; plot(pc);
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
        function plot__(this, x, sp, deg)
            figure;    
            plot(this.times, this.counts, 'Marker', 'o');
            hold on;
            plot(this.times, x); %, 'k-');
            hold off;
            axis tight;
            title(sprintf('CatheterSavitzkyGolay.plot: span=%g, degree=%g', sp, deg));
            xlabel('time/arbitrary');
        end
        function c    = tailOfCounts(this)
            t = 0:1:round(4*this.tauHalf);
            c = this.counts(end) * 2.^(-t/this.tauHalf);      
            c = [c linspace(c(end), 0, ceil(this.tauHalf))];
        end
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

