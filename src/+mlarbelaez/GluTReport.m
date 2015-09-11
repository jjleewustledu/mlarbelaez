classdef GluTReport  
	%% GLUTREPORT   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
	properties         
        mode = 'WholeBrain'

        pnum
        snum
        ks
        kmps
        gluTxlsx
        
        ik04 = 1
        ik12 = 2
        ik21 = 3
        ik32 = 4
        ik43 = 5
        it0  = 6
        
        K04
        K21
        K12
        K32
        K43
        T0
        UF
        CMRglu
        Chi
        KD
        CTX
        Freeglu
        MTT
        FluxMet
    end 
    
    properties (Dependent)
        Bloodglu
        F1
        GluTxlsxInfo
        V1
    end
    
    methods %% GET 
        function v = get.V1(this)
            % mL/100g
            
            v = this.GluTxlsxInfo.cbv;
        end
        function f = get.F1(this)
            % mL/min/100g            
            
            f = this.GluTxlsxInfo.cbf;
            if (any(isnan(f)) || strcmp('nan',f))
                f = this.V1toF1(this.GluTxlsxInfo.cbv); 
            end
        end
        function g = get.Bloodglu(this)
            g = this.PlasmaGluToBloodGlu(this.GluTxlsxInfo.glu, ...
                                         this.GluTxlsxInfo.hct);
        end
        function g = get.GluTxlsxInfo(this)
            switch (this.mode)
                case 'WholeBrain'
                    g = this.gluTxlsx.pid_map(this.pnum).(sprintf('scan%i', this.snum));
                case 'AlexsRois'
                    g = this.gluTxlsx.rois_map(this.pnum).(sprintf('scan%i', this.snum));
                otherwise
                    error('mlarbelaez:switchFailure', 'GluTReport.get.GluTxlsxInfo');
            end
        end
    end
    
	methods 		  
 		function this = GluTReport(pnum, ks, kmps) 
 			%% GLUTREPORT 
 			%  Usage:  this = GluTReport(ks_cell, kmps_cell) 

            this.pnum = pnum;
            this.snum = kmps.snumber;
            this.ks = ks;
            this.kmps = kmps;            
            this.gluTxlsx  = mlarbelaez.GluTxlsx;

            if (~isempty(this.ks))
                try
                    this.K04      = this.ks(this.ik04)*60;
                    this.K21      = this.ks(this.ik21)*60;
                    this.K12      = this.ks(this.ik12)*60;
                    this.K32      = this.ks(this.ik32)*60;
                    this.K43      = this.ks(this.ik43)*60;
                    this.T0       = this.ks(this.it0);

                    this.MTT      = 60 * this.V1 / this.F1;
                    this.Chi      = this.K21 * this.K32 / (this.K12 + this.K32);
                    this.UF       = this.Chi * (this.MTT/60) / (1 + 0.835 * this.Chi * this.MTT/60);
                    this.CMRglu   = this.Chi * this.Bloodglu * this.V1;
                    this.KD       = this.K21 * this.V1;
                    this.CTX      = this.KD  * this.Bloodglu;
                    this.Freeglu  = this.CMRglu / this.K32 / 100;
                    this.FluxMet  = this.CTX / this.CMRglu;
                catch ME
                    handwarning(ME);
                end
            end
        end  
        function report(this, fqfn)
            %% REPORT
            %  mL/min/100g, umul/mL, 1/min, sec            

            fid = fopen(fqfn, 'w');
            this.printCsvHeader(fid);
            try
                this.printCsvLine(fid, this.pnum, this.snum);
            catch ME
                handexcept(ME);
            end
            fprintf(fid, '\n');
            fclose(fid);
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')    
        function f = V1toF1(~, v)
            % mL/100g to mL/min/100g
            
            warning('mlarbelaez:imputinData', 'GluTReport.V1toF1');
            f = 20.84*v^0.671;
        end
        function g = PlasmaGluToBloodGlu(~, g, hct)
            %% PLASMAGLUTOBLOODGLU
            %  e.g., 63.4 mg/dL * (1 g/1000 mg) * (1000 mmoles/180.1559 g) * (10 dL/L) * (1 - 0.3*Hct) = 3.18 mmol/L 
            %                                                                                          = 3.18 umol/mL
            
            if (hct > 1)
                hct = hct / 100; end
            g = g * (1/1000) * (1000/180.1559) * 10 * (1 - 0.3*hct);
        end
        function printCsvHeader(~, fid)  
            fprintf(fid, sprintf('Glucose Threshold, JJL, %s\n\n', datestr(now)));
            results = ...
                'p#,scan#,CBF,CBV,blood glu,k04,k21,k12,k32,k43,t0,Util Frac,CMR glu,chi,Kd,CTX,free glu,MTT,flux/met\n';
            fprintf(fid, results);
        end
        function printCsvLine(this, fid, pnum, s)
            results = ...
                sprintf('%s,%i,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
                    pnum, s, ...
                    this.F1, this.V1, this.Bloodglu, ...
                    this.K04, this.K21, this.K12, this.K32, this.K43, this.T0, ...
                    this.UF, this.CMRglu, this.Chi, this.KD, this.CTX, this.Freeglu, ...
                    this.MTT, this.FluxMet);
            fprintf(fid, results);
        end
        function c = cell2csv(~, c)
            for ci = 1:length(c)
                if (isnumeric(c{ci}))
                    c{ci} = num2str(c{ci}); end
            end
            c = cellfun(@(x) [x ','], c, 'UniformOutput', false);
            c = strjoin(c);
            c = c(1:end-1);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

