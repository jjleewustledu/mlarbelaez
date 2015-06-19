classdef CatheterTvd  
	%% CATHETERTVD   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties 
         stopTol = 1e-3
         maxIter = 1e2
         verbose = 1                  
         lratios = [1e-4 1e-3 1e-2 1e-1]
         
         crvFn = '/Volumes/InnominateHD2/Arbelaez/deconvolution/data 2014jul17/AMAtest4.crv'
         counts
         times
    end 
    
    properties (Dependent)
         dccrv
    end
    
    methods %% GET        
        function d = get.dccrv(this)        
            d = mlpet.DecayCorrectedCRV.load(this.crvFn);
        end
    end
    
	methods 
        function [xs,E,status,this] = query(this, varargin)
            ip = inputParser;
            addParameter(ip, 'counts',  this.dccrv.counts,     @isnumeric);
            addParameter(ip, 'lratios', [1e-4 1e-3 1e-2 1e-1], @isnumeric);
            parse(ip, varargin{:});            
            this.counts  = ip.Results.counts;
            this.lratios = ip.Results.lratios;
            
            [xs, E, status] = this.tvdip(this.counts, this.lratios);             
            this.mplot(this.counts, xs, this.lratios);           
        end       
		function lambdamax = tvdiplmax(this, counts)
            lambdamax = this.itsTvdip_.tvdiplmax(counts);
        end        
        function [x, E, s, lambdamax] = tvdip(this, counts, lratio)
            lmax = this.tvdiplmax(counts);
            if (this.verbose)
                fprintf('CatheterTvd.tvdip.lmax -> %g\n', lmax);
            end
            [x, E, s, lambdamax] = this.itsTvdip_.tvdip(counts, lmax*lratio, this.verbose, this.stopTol, this.maxIter);
        end
        function x = withPeristalsis(this, x, A, tau, phi)
            x = x(this.times);
            x = x + A * sin(phi + 2 * pi * this.times / tau);
        end        
        function plot(this, y, x, lratio)
            figure;
            lmax = this.tvdiplmax(y);            
            plot(y,'-','Color',0.8*[1 1 1]);
            plot(x(:,l),'k-');
            axis tight;
            title(sprintf('CatheterTvd.plot: \\lambda=%5.2e, \\lambda/\\lambda_{max}=%5.2e', ...
                          lmax*lratio,lratio));
            xlabel('n');
            legend({'Input y_n','TVD x_n'});            
        end
        function mplot(this, y, xs, lratios)
            figure;
            L = length(lratios);
            lmax = this.tvdiplmax(y);
            for l = 1:L
                subplot(L,1,l);
                hold on;
                plot(y,'-','Color',0.8*[1 1 1]);
                plot(xs(:,l),'k-');
                axis tight;
                title(sprintf('CatheterTvd.mplot: \\lambda=%5.2e, \\lambda/\\lambda_{max}=%5.2e', ...
                              lmax*lratios(l),lratios(l)));
            end
            xlabel('n');
            legend({'Input y_n','TVD x_n'});   
        end
        
 		function this = CatheterTvd(varargin) 
 			%% CATHETERTVD 
 			%  Usage:  this = CatheterTvd() 
            
            ip = inputParser;
            addParameter(ip, 'counts', this.dccrv.counts, @isnumeric);
            addParameter(ip, 'times',  1:107,             @isnumeric);
            parse(ip, varargin{:});
            
            this.counts    = ip.Results.counts;
            this.times     = ip.Results.times; 
            this.counts    = this.counts(this.times);
            this.itsTvdip_ = mltvd.TvdIp;
 		end 
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        itsTvdip_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

