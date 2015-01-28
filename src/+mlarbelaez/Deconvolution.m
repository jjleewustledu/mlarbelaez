classdef Deconvolution  
	%% DECONVOLUTION   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
 		 
 	end 

	methods 
  		function this = Deconvolution(varargin) 
 			%% DECONVOLUTION 
 			%  Usage:  this = Deconvolution() 

 			 
        end 
        
        function f = byFFT(this, fg, g)
            %% BYFFT
            %  Usage:  f = \mathcal{F}^{-1}[ \mathcal{F}[f * g] \mathcal{F}[g] ]
            
            import mlsystem.*;
            fg  = VectorTools.ensureRowVector(fg);
            g   = VectorTools.ensureRowVector(g);
            len = max(length(fg), length(g));
            wid = length(fg) + length(g) - 1;
            f   = ifft(fft(fg, wid) ./ fft(g, wid));
            f   = f(1:len);
            if (any(isnan(f)))
                error('mlarbelaez:NaN', 'Deconvolution.byFFT.f had NaNs; check fft(g)'); end
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

