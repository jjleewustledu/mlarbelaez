classdef LegacyCatheterResponse < mlaif.AbstractVectorAifProblem & mlarbelaez.AbstractCatheterAnalysis 
	%% LEGACYCATHETERRESPONSE   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 

    properties (Constant)
        DCV_START   = 15;
        DCV_END     = 115;
        DCCRV_START = 20;
        DCCRV_END   = 120;
    end
    
    properties 
        baseTitle = 'DCV from mm01-021, p7413'
        xLabel    = 'time/s'
        yLabel    = 'counts'
        
        dcv 
        dccrv
        binWidth  = 3
    end
    
    properties (Dependent)        
        dccrvCounts
    end
    
    methods % GET
        function c = get.dccrvCounts(this)
            c = this.dccrv.counts(this.DCCRV_START:this.DCCRV_END);
        end
    end
    
	methods 
        function this = estimateParameters(this)
            %% ESTIMATEPARAMETERS manages Bayes PETMR processing
            %  Usage:  this = this.estimateParameters

            import mlbayesian.*;
            Rmax = max(this.dcv.counts)/max(this.dccrv.counts);
            map  = containers.Map('KeyType', 'double', 'ValueType', 'any');
            B    = this.length/this.binWidth;
            for b = 1:B
                map(b)  = struct('fixed', 0, 'min', 0, 'mean', this.ramp(b, B, Rmax), 'max', Rmax);
            end
            this = this.runMcmc(map);
        end
        function r    = ramp(~, b, B, Rmax)
            r = Rmax*(1 - b/B);
        end
        function ed   = estimateData(this)
            ed = this.estimateDcv;
        end
        function ed   = estimateDataFast(this, varargin)
            ed = this.estimateDcvFast(varargin{:});
        end
        
  		function this = LegacyCatheterResponse(dcv, dccrv)
 			%% LEGACYCATHETERRESPONSE 
 			%  Usage:  this = LegacyCatheterResponse(DCV_object, DecoyCorrectedCRV_object) 
 			
            assert(isa(dcv,   'mlarbelaez.DCV'));
            assert(isa(dccrv, 'mlarbelaez.DecayCorrectedCRV'));
            assert(this.DCV_END - this.DCV_START == this.DCCRV_END - this.DCCRV_START);
            
            this.dcv = dcv;
            this.dccrv = dccrv;
            this.dependentData = this.smoothPeristalsis(this.dcv.counts(this.DCV_START:this.DCV_END));  
            this.independentData = 0:length(this.dependentData)-1;
 		end 
    end 
    
    methods (Access = 'protected')    
        function c  = smoothPeristalsis(this, c)
            %% SMOOTHPERISTALSIS attempts to remove fluctuations associated with peristaltic pumps 
            
            c = this.ensureRowVector(smooth(c));
        end
        function R  = normalizeResponse(~, R)
            R = R / sum(R);
        end            
        function er = estimateDcv(this)
            er = this.estimateDcvFast(this.finalParams);
        end
        function er = estimateDcvFast(this, bins)
            er = conv(this.estimateResponseFast(bins), this.dccrvCounts);
            er = er(1:this.length);
        end      
        function er = estimateResponse(this)
            er = this.estimateResponseFast(this.finalParams);
        end
        function er = estimateResponseFast(this, bins)
            er = zeros(1, length(this.dependentData));
            for b = 1:length(bins)
                er((b-1)*this.binWidth+1:b*this.binWidth) = bins(b);
            end
        end        
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

