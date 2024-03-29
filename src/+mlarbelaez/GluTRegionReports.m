classdef GluTRegionReports  
	%% GLUTREPORTS is a rapid prototype. 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 
	properties         
        dtdns
        ks
        kmps
        gluTxlsx
        
        ik04 = 1
        ik12frac = 2
        ik21 = 3
        ik32 = 4
        ik43 = 5
        it0  = 6
        
        F1
        V1
        Bloodglu
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
        size
    end
    
    methods %% GET
        function s = get.size(this)
            s = size(this.ks);
        end
    end
    
	methods 		  
 		function this = GluTRegionReports(varargin) 
 			%% GLUTREPORTS 
 			%  Usage:  this = GluTRegionReports(sessionFolderNames, ks_cell[, kmps_cell]) 
            %
            %          grr = GluTRegionReports(RegionalMeasurements.dns, job92_output{1})
            %          grr.report('loopRegionalMeasurements_2015oct29_2125.csv')

            ip = inputParser;
            addRequired(ip, 'dtdns', @iscell);
            addRequired(ip, 'ks',    @iscell);
            addOptional(ip, 'kmps',  @(x) ~isempty(x));
            parse(ip, varargin{:});
            this.dtdns = ip.Results.dtdns;
            this.ks    = ip.Results.ks;
            this.kmps  = ip.Results.kmps;
            this.gluTxlsx  = mlarbelaez.GluTxlsx;
            
            this.F1       = cell(this.size);
            this.V1       = cell(this.size);
            this.Bloodglu = cell(this.size);
            this.K04      = cell(this.size);
            this.K21      = cell(this.size);
            this.K12  = cell(this.size);
            this.K32      = cell(this.size);
            this.K43      = cell(this.size);
            this.T0       = cell(this.size);            
            this.UF       = cell(this.size);
            this.CMRglu   = cell(this.size);
            this.Chi      = cell(this.size);
            this.KD       = cell(this.size);
            this.CTX      = cell(this.size);
            this.Freeglu  = cell(this.size);
            this.MTT      = cell(this.size);
            this.FluxMet  = cell(this.size);
            
            for p = 1:this.size(1)
                for s = 1:this.size(2)
                    for r = 1:this.size(3)
                        if (~isempty(this.ks{p,s,r}))
                            try
                                this.V1{p,s,r}       = this.ks{p,s,r}.v * 100;
                                this.F1{p,s,r}       = this.ks{p,s,r}.f * 6000/1.05;
                                this.Bloodglu{p,s,r} = this.getBloodglu(p,s);
                                this.K04{p,s,r}      = this.ks{p,s,r}.k4parameters(this.ik04)*60;
                                this.K21{p,s,r}      = this.ks{p,s,r}.k4parameters(this.ik21)*60;
                                this.K12{p,s,r}      = this.ks{p,s,r}.k4parameters(this.ik12frac)*this.K21{p,s,r};
                                this.K32{p,s,r}      = this.ks{p,s,r}.k4parameters(this.ik32)*60;
                                this.K43{p,s,r}      = this.ks{p,s,r}.k4parameters(this.ik43)*60;
                                this.T0{p,s,r}       = this.ks{p,s,r}.k4parameters(this.it0);

                                this.MTT{p,s,r}      = 60 * this.V1{p,s,r} / this.F1{p,s,r};
                                this.Chi{p,s,r}      = this.K21{p,s,r} * this.K32{p,s,r} / (this.K12{p,s,r} + this.K32{p,s,r});
                                this.UF{p,s,r}       = this.Chi{p,s,r} * (this.MTT{p,s,r}/60) / (1 + 0.835 * this.Chi{p,s,r} * this.MTT{p,s,r}/60);
                                this.CMRglu{p,s,r}   = this.Chi{p,s,r} * this.Bloodglu{p,s,r} * this.V1{p,s,r};
                                this.KD{p,s,r}       = this.K21{p,s,r} * this.V1{p,s,r};
                                this.CTX{p,s,r}      = this.KD{p,s,r}  * this.Bloodglu{p,s,r};
                                this.Freeglu{p,s,r}  = this.CMRglu{p,s,r} / this.K32{p,s,r} / 100;
                                this.FluxMet{p,s,r}  = this.CTX{p,s,r} / this.CMRglu{p,s,r};
                            catch ME
                                handwarning(ME);
                            end
                        end
                    end
                end
            end
        end  
        function report(this, fqfn)
            %% REPORT
            %  mL/min/100g, umul/mL, 1/min, sec            

            fid = fopen(fqfn, 'w');
            this.printCsvHeader(fid);
            for r = 1:this.size(3)
                for p = 1:this.size(1)
                    for s = 1:this.size(2)
                        try
                            this.printCsvLine(fid, p, s, r);
                        catch ME
                            handexcept(ME);
                        end
                    end
                end
            end
            fprintf(fid, '\n');
            fclose(fid);
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')    
        function v = getV1(this, p, s, r)
            % mL/100g
            
            v = this.getGluTxlsxInfo(p, s).cbv(r);
        end
        function f = getF1(this, p, s, r)
            % mL/min/100g            
            
            f = this.getGluTxlsxInfo(p, s).cbf(r);
            if (strcmp('nan',f)); f = nan; end
        end
        function g = getBloodglu(this, p, s)
            g = this.PlasmaGluToBloodGlu(this.getGluTxlsxInfo(p,s).glu, ...
                                         this.getGluTxlsxInfo(p,s).hct);
        end
        function g = getGluTxlsxInfo(this, p, s)
            if (isnumeric(p))
                p = str2pnum(this.dtdns{p});
            end         
            g = this.gluTxlsx.pid_map(p).(sprintf('scan%i', s));
        end
        function f = V1toF1(~, v)
            % mL/100g to mL/min/100g
            
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
        function printCsvLine(this, fid, p, s, r)    
            pnum = str2pnum(this.dtdns{p});
            results = ...
                sprintf('%s,%i,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f,%f\n', ...
                    pnum, s, ...
                    this.F1{p,s,r}, this.V1{p,s,r}, this.Bloodglu{p,s,r}, ...
                    this.K04{p,s,r}, this.K21{p,s,r}, this.K12{p,s,r}, this.K32{p,s,r}, this.K43{p,s,r}, this.T0{p,s,r}, ...
                    this.UF{p,s,r}, this.CMRglu{p,s,r}, this.Chi{p,s,r}, this.KD{p,s,r}, this.CTX{p,s,r}, this.Freeglu{p,s,r}, ...
                    this.MTT{p,s,r}, this.FluxMet{p,s,r});
            fprintf(fid, results);
        end
        
        %% LEGACY for reading output from Joanne Markhams' glucnoflow
        
        function printCsvLinePrevious(this, fqfn)
            fid = fopen(fqfn, 'a');            
            gx = this.getGluTxlsxInfo(this.pnumber, this.petIndex);         
            [~,rDLog] = this.readDLog;
            [~,rOut]  = this.readOut;
            [~,rALog] = this.readALog;
            results = this.cell2csv([{this.pnumber this.petIndex gx.glu gx.hct} num2cell(rDLog) num2cell(rOut) num2cell(rALog)]);
            fprintf(fid, results);
            fprintf(fid, '\n');
            fclose(fid);
        end
        function [results,rrow] = readDLog(this)
            fid = fopen( ...
                  fullfile(this.procPath, sprintf('%swb%id.log', this.pnumber, this.petIndex)));
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            ts = cell2mat(textscan(fid, '%f %f %f %f %f %f %f',    'Delimiter', ' ', 'MultipleDelimsAsOne', true));
            
            results.cbf     = ts(1,1);
            results.cbv     = ts(1,2);
            results.glu_art = ts(1,3);
            results.k01     = ts(1,4);
            results.k21     = ts(1,5);
            results.k22     = ts(1,6);
            results.k32     = ts(1,7);
            results.k43     = ts(2,1);
            results.t0      = ts(2,2);
            results.t12     = ts(2,3);
            results.util    = ts(2,4);
            results.glu_met = ts(2,5);
            results.chi     = ts(2,6);
            results.kd      = ts(2,7);
            if (4 == size(ts,1))
                results.forward_flux = ts(3,1);
                results.brain_glu    = ts(4,1);
                rrow = [ts(1,:) ts(2,:) ts(3,1) ts(4,1)];
            elseif (3 == size(ts,1))
                results.forward_flux = ts(3,1);
                results.brain_glu    = ts(3,2);
                rrow = [ts(1,:) ts(2,:) ts(3,1) ts(3,2)];
            else
                error('mlarbelaez:unexpectedArraySize', 'size(Glucnoflow.readDlog.ts) -> %s', num2str(size(ts)));
            end
        end
        function [results,rrow] = readOut(this)
            tp = mlio.TextParser.load( ...
                 fullfile(this.procPath, sprintf('%swb%i.out', this.pnumber, this.petIndex)));
            results.condition = tp.parseAssignedNumeric('condition no');
            results.det = tp.parseRightAssociatedNumeric('DETERMINANT OF FI MATRIX');
            rrow = [results.condition results.det];
        end
        function [results,rrow] = readALog(this)
            tp = mlio.TextParser.load( ...
                 fullfile(this.procPath, sprintf('%swb%ia.log', this.pnumber, this.petIndex)));
            tmp = tp.parseRightAssociatedNumeric2('WEIGHTED SUM-OF-SQUARES & RMSE');
            results.weighted_sum_of_squares = tmp(1);
            results.rmse = tmp(2);
            rrow = [tmp(1) tmp(2)];
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

