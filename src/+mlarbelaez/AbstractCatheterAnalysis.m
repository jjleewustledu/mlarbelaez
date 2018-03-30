classdef (Abstract) AbstractCatheterAnalysis  
	%% ABSTRACTCATHETERANALYSIS provides sampling-time information, isotope information, decay-correction method
    %  Prefers working with row-vectors.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 
 	 

	properties
    end 
    
    methods (Static)
        function x = ensureColVector(x)
            %% ENSURECOLVECTOR reshapes row vectors to col vectors, leaving matrices untouched
            
            x = mlsystem.VectorTools.ensureColVector(x);
        end
        function x = ensureRowVector(x)
            %% ENSUREROWVECTOR reshapes row vectors to col vectors, leaving matrices untouched
            
            x = mlsystem.VectorTools.ensureRowVector(x);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

