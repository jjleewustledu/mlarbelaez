classdef Model4Compartments  
	%% MODEL4COMPARTMENTS   

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
		  
 		function this = Model4Compartments(varargin) 
 			%% MODEL4COMPARTMENTS 
 			%  Usage:  this = Model4Compartments() 

 			 
 		end 
        function ed = estimateQFast(this, k04, k12, k21, k32, k43, t0)            
            k22 = k12 + k32;
            t = this.timeInterpolants;
            
            q2_ = this.VB * k21 * exp(-k22*t);
            q3_ = this.VB * k21 * k32 * (k22 - k43)^-1 * (exp(-k43*t) - exp(-k22*t));
            q4_ = this.VB * k21 * k32 * k43 * ( ...
                     exp(-k22*t)/((k04 - k22)*(k43 - k22)) + ...
                     exp(-k43*t)/((k22 - k43)*(k04 - k43)) + ...
                     exp(-k04*t)/((k22 - k04)*(k43 - k04)));
            q234 = conv(q2_ + q3_ + q4_, this.Ca);
            q234 = q234(1:length(t));
            Q0   = this.VB * this.Ca + q234;            
            
            t0_idx         = floor(t0/this.dt) + 1;
            ed             = zeros(size(Q0));
            ed(t0_idx:end) = Q0(1:end-t0_idx+1);
        end 
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

