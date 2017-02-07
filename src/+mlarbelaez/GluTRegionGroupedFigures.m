classdef GluTRegionGroupedFigures  
	%% GLUTREGIONGROUPEDFIGURES is a rapid prototype

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.6.0.232648 (R2015b) 
 	%  $Id$ 
 	 

	properties 
        glut_xlsx = '/Volumes/SeagateBP4/Arbelaez/GluT/loopRegionalMeasurements_2015dec2_2105.xlsx'
        glut_sheet = 'loopRegionalMeasurements';
        dataRows = [2 111 2 21]
        mapKin4
        mapMetab
        mapSx

        boxFormat = '%4.1f'
        boxFontSize = 12
        axesFontSize = 14
        markerFaceColor95 = [1   1   1  ] %[0.8 0.309 0.1]
        markerFaceColor75 = [0.3 0.3 0.3] %[0.1 0.309 0.8]
        markerLineWidth = 1
        stairsColor = [0.618 0.618 0.618]
        barWidth = 0.8
        
        nominalGlu      = [90 75 60 45]
        nominalRising   = [45 60 75 90]
        nominalRisingSI = [2.5 3.3 4.1 5.0]
        p
        scan
        nominal_glu
        plasma_glu
        CBV
        CMRglu
        CTX
        free_glu
        MTT
        Videen_CBF
        Glucagon
        Epi
        Norepi
        NGPSx
        NGSx
        TotalSx
        Insulin
        Cortisol    
        
        blood_glu
        k04
        k21
        k12
        k32
        k43
        t0
        UtilFrac
        chi
        Kd
        flux_met
        E_net
        region
        
        regions = {'amygdala' 'hippocampus' 'hypothalamus' 'mpfc' 'thalamus'};
    end
    
    
	methods		  
 		function this = GluTRegionGroupedFigures(varargin) 
 			%% GLUTREGIONGROUPEDFIGURES 
 			%  Usage:  this = GluTFigures() 

            ip = inputParser;
            addOptional(ip, 'xlsxFile', this.glut_xlsx, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.xlsxFile))
                this.glut_xlsx = ip.Results.xlsxFile; end
            this = this.xlsRead;
            this.registry_ = mlarbelaez.ArbelaezRegistry.instance;
        end 
        function y = selectRegion(~, y, region)            
            switch (region)
                case 'amygdala'
                    rng =  1:22;
                case 'hippocampus'
                    rng = 23:44;
                case 'hypothalamus'
                    rng = 45:66;
                case 'mpfc'
                    rng = 67:88;
                case 'thalamus'
                    rng = 89:110;
                otherwise
                    error('mlarbelaez:unsupportedSwitchCase', 'GluTRegionGroupedFigures.selectRegion.region->%s', region);
            end
            y = y(rng);
        end
        function figure0 = createBarErr(this, yLabel, varargin)
            %% CREATEBARERR
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createBarErr('CMR_{glu}/CBV')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            ip = inputParser;
            addRequired(ip, 'yLabel', @ischar);
            addOptional(ip, 'limYHard', [], @isnumeric);
            parse(ip, yLabel, varargin{:});
            
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(ip.Results.yLabel);   
            [x, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('nominal arterial plasma glucose'); 
            
            NR  = length(this.regions);
            y90 = zeros(5,NR);
            y75 = zeros(6,NR);
            y60 = zeros(5,NR);
            y45 = zeros(6,NR);
            for r = 1:NR
                yr = this.selectRegion(y, this.regions{r});
                y90(:,r) = yr(1:5);
                y75(:,r) = yr(6:11);
                y60(:,r) = yr(12:16);
                y45(:,r) = yr(17:22);
            end
            
            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0);
            hold(axes2,'on');

            xlabel(axes2, xLabel2);
            if (conversionFactor2 ~= 1)
                ylabel(axes2, yLabel2); end

            xlim(axes2,this.axesLimXBar(x*conversionFactor1)); 
            ylim(axes2,this.axesLimYBar(y*conversionFactor2, ip.Results.limYHard*conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRisingSI,'XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLimXBar(x));        
            ylim(axes1,this.axesLimYBar(y, ip.Results.limYHard));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRising,'XAxisLocation','bottom','YAxisLocation','left');

            % Create bar
            xb = this.nominalGlu;
            yb = [mean(y90); mean(y75); mean(y60); mean(y45)];
            theBar = bar(xb, yb, this.barWidth); %,'FaceColor',[1 1 1]);            
            for r = 1:NR
                set(theBar(r),'DisplayName',this.regions{r});
            end

            % Create legend 
            theLegend = legend(axes1,'show');
            set(theLegend,'EdgeColor',[1 1 1]);
            
            % Create errorbar
            xe = [this.barOrigins(90); this.barOrigins(75); this.barOrigins(60); this.barOrigins(45)];
            ye = [mean(y90); mean(y75); mean(y60); mean(y45)];
            ee = [std(y90)./sqrt(length(y90)); std(y75)./sqrt(length(y75)); std(y60)./sqrt(length(y60)); std(y45)./sqrt(length(y45))];
            errorbar(xe, ye, ee, 'Parent',axes1,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0],'LineStyle','none','LineWidth',1,...
                'Color',[0 0 0]);

            % Create textboxes
            %R   = this.axesLimY(y);
            %L   = R(1);
            %D   = R(2) - R(1);
            %z45 = 0.12 + 0.8*(mean(y45) - L)/D;
            %z65 = 0.12 + 0.8*(mean(y65) - L)/D;
            %z75 = 0.12 + 0.8*(mean(y75) - L)/D;
            %z95 = 0.12 + 0.8*(mean(y95) - L)/D;  
%             zN  = 0.12;
%             zV  = 0.17;
%             annotation(figure0,'textbox',[0.712 zV 0.09 0.07],...
%                 'String',{sprintf(this.boxFormat, mean(y45))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.562 zV 0.09 0.07],...
%                 'String',{sprintf(this.boxFormat, mean(y65))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.42 zV 0.09 0.07],...
%                 'String',{sprintf(this.boxFormat, mean(y75))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.275 zV 0.09 0.07],...
%                 'String',{sprintf(this.boxFormat, mean(y95))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');   
%             annotation(figure0,'textbox',[0.707 zN 0.09 0.07],...
%                 'String',{sprintf('N = %i', length(y45))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.555 zN 0.09 0.07],...
%                 'String',{sprintf('N = %i', length(y65))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.415 zN 0.09 0.07],...
%                 'String',{sprintf('N = %i', length(y75))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');
%             annotation(figure0,'textbox',[0.265 zN 0.09 0.07],...
%                 'String',{sprintf('N = %i', length(y95))},...
%                 'LineStyle','none',...
%                 'FontSize',this.boxFontSize,...
%                 'FitBoxToText','off');            
        end        
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        registry_
    end
    
    methods (Access = 'private')     
        function x    = barOrigins(~, x0)
            x = [(x0 - 4.6) (x0 - 2.3) x0 (x0 + 2.3) (x0 + 4.6)];
        end
        function this = xlsRead(this)
            [~,~,kin4_] = xlsread(this.glut_xlsx, this.glut_sheet);
            this.mapKin4 = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapKin4(uint32(idx-this.dataRows(1)+1)) = ...
                    struct('p',        kin4_{idx, 2}, ...
                        'scan',        kin4_{idx, 3}, ...
                        'nominal_glu', kin4_{idx, 4}, ...
                        'plasma_glu',  kin4_{idx, 5}, ...
                        'Videen_CBF',  kin4_{idx, 6}, ...
                        'CBV',         kin4_{idx, 7}, ...
                        'blood_glu',   kin4_{idx, 8}, ...
                        'k04',         kin4_{idx, 9}, ...
                        'k21',         kin4_{idx,10}, ...
                        'k12',         kin4_{idx,11}, ...
                        'k32',         kin4_{idx,12}, ...
                        'k43',         kin4_{idx,13}, ...
                        't0',          kin4_{idx,14}, ...
                        'UtilFrac',    kin4_{idx,15}, ...
                        'CMRglu',      kin4_{idx,16}, ...
                        'chi',         kin4_{idx,17}, ...
                        'Kd',          kin4_{idx,18}, ...
                        'CTX',         kin4_{idx,19}, ...
                        'free_glu',    kin4_{idx,20}, ...
                        'MTT',         kin4_{idx,21}, ...                        
                        'flux_met',    kin4_{idx,22}, ...
                        'E_net',       kin4_{idx,23});
            end
            this.p           = this.cellulize(kin4_, 2);
            this.scan        = this.vectorize(kin4_, 3);
            this.nominal_glu = this.vectorize(kin4_, 4);
            this.plasma_glu  = this.vectorize(kin4_, 5);
            this.Videen_CBF  = this.vectorize(kin4_, 6);
            this.CBV         = this.vectorize(kin4_, 7);
            this.blood_glu   = this.vectorize(kin4_, 8);
            this.k04         = this.vectorize(kin4_, 9);
            this.k21         = this.vectorize(kin4_,10);
            this.k12         = this.vectorize(kin4_,11);
            this.k32         = this.vectorize(kin4_,12);
            this.k43         = this.vectorize(kin4_,13);
            this.t0          = this.vectorize(kin4_,14);
            this.UtilFrac    = this.vectorize(kin4_,15);
            this.CMRglu      = this.vectorize(kin4_,16);
            this.chi         = this.vectorize(kin4_,17);
            this.Kd          = this.vectorize(kin4_,18);
            this.CTX         = this.vectorize(kin4_,19);
            this.free_glu    = this.vectorize(kin4_,20);
            this.MTT         = this.vectorize(kin4_,21);
            this.flux_met    = this.vectorize(kin4_,22);
            this.E_net       = this.vectorize(kin4_,23);
            
            [~,~,metab_] = xlsread(this.glut_xlsx, 'Metabolites');
            this.mapMetab = containers.Map('KeyType', 'uint32', 'ValueType', 'any');      
            for idx = this.dataRows(3):this.dataRows(4)
                this.mapMetab(uint32(idx-this.dataRows(3)+1)) = ...
                    struct('p',        metab_{idx, 2}, ...
                        'scan',        metab_{idx, 3}, ...
                        'nominal_glu', metab_{idx, 4}, ...
                        'plasma_glu',  metab_{idx, 5}, ...
                        'Glucagon',    metab_{idx,11}, ...
                        'Epi',         metab_{idx,12}, ...
                        'Norepi',      metab_{idx,13}, ...
                        'Insulin',     metab_{idx,10}, ...
                        'Cortisol',    metab_{idx,7});
            end
            this.Glucagon = this.vectorize(metab_,11, true);
            this.Epi      = this.vectorize(metab_,12, true);
            this.Norepi   = this.vectorize(metab_,13, true);
            this.Insulin  = this.vectorize(metab_,10, true);
            this.Cortisol = this.vectorize(metab_,7,  true);
            
            [~,~,sx_] = xlsread(this.glut_xlsx, 'Sx');
            this.mapSx = containers.Map('KeyType', 'uint32', 'ValueType', 'any');       
            for idx = this.dataRows(3):this.dataRows(4)
                this.mapSx(uint32(idx-this.dataRows(3)+1)) = ...
                    struct('p',        sx_{idx,2}, ...
                        'scan',        sx_{idx,3}, ...
                        'nominal_glu', sx_{idx,4}, ...
                        'plasma_glu',  sx_{idx,5}, ...
                        'NGPSx',       sx_{idx,6}, ...
                        'NGSx',        sx_{idx,7}, ...
                        'TotalSx',     sx_{idx,8});
            end
            this.NGPSx   = this.vectorize(sx_,6, true);
            this.NGSx    = this.vectorize(sx_,7, true);            
            this.TotalSx = this.vectorize(sx_,8, true);
        end
        function c = cellulize(this, arr, col, secondSheets)
            if (exist('secondSheets', 'var'))
                clen = this.dataRows(4) - this.dataRows(3) + 1;
                D = this.dataRows(3) - 1;
            else
                clen = this.dataRows(2) - this.dataRows(1) + 1;
                D = this.dataRows(1) - 1;
            end
            c = cell(1, clen);
            for ic = 1:clen
                c{ic} = arr{ic+D, col};
            end
        end
        function v = vectorize(this, arr, col, secondSheets)
            if (exist('secondSheets', 'var'))
                vlen = this.dataRows(4) - this.dataRows(3) + 1;
                D = this.dataRows(3) - 1;
            else
                vlen = this.dataRows(2) - this.dataRows(1) + 1;
                D = this.dataRows(1) - 1;
            end
            v = zeros(vlen, 1);
            for iv = 1:vlen
                v(iv) = arr{iv+D, col};
            end
        end
        function range = axesLimY(~, dat)
            Delta = (max(dat) - min(dat))*0.25;        
            low   = min(dat) - Delta;
            low   = max(low, 0);
            high  = max(dat) + Delta;
            range = [low high];
        end
        function range = axesLimX(~, dat)
            Delta = (max(dat) - min(dat))*0.25;        
            low   = min(dat) - Delta;
            high  = max(dat) + Delta;
            range = [low high];
        end
        function range = axesLimYBar(~, dat, limHard)
            if (isempty(limHard))
                range = [0 max(dat)+std(dat)];
            else
                range = [0 limHard];
            end
        end
        function range = axesLimXBar(~, dat)
            Delta = (max(dat) - min(dat))*0.333;        
            low   = min(dat) - Delta;
            high  = max(dat) + Delta*0.666;
            range = [low high];
        end
        function [x,xLabel1,xLabel2,conversionFactor1] = xLabelLookup(this, xLabel)
            x       = this.nominal_glu;  
            xLabel1 = [xLabel ' (mg/dL)'];
            xLabel2 =          '(mmol/L)';
            conversionFactor1 = 0.05551;
        end
        function [y,yLabel1,yLabel2,conversionFactor2] = yLabelLookup(this, yLabel)
            conversionFactor2 = 1;
            yLabel2 = '';
            switch (yLabel)
                case 'CTX_{glu}/CMR_{glu}'
                    y = this.CTX ./ this.CMRglu;
                    yLabel1 = [yLabel ''];
                case '(CTX_{glu} - CMR_{glu})/CBV'
                    y = (this.CTX - this.CMRglu) ./ this.CBV;
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'CTX_{glu} - CMR_{glu}'
                    y = (this.CTX - this.CMRglu);
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CMR_{glu}'
                    y = this.CMRglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CTX_{glu}'
                    y = this.CTX;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'free glucose'
                    y = this.free_glu;                   
                    yLabel1 = [yLabel ' (\mumol/g)'];
                case 'CTX_{glu}/CBV'
                    y = this.CTX ./ this.CBV;
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'CMR_{glu}/CBV'
                    y = this.CMRglu ./ this.CBV;               
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'free glucose/CBV'   
                    y = this.free_glu ./ this.CBV;
                    y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL} 
                    yLabel1 = [yLabel ' (\mumol/mL)'];
                case 'CBF'
                    y = this.Videen_CBF;
                    yLabel1 = [yLabel ' (mL/100 g/min)']; 
                case 'CBF (Kety-Schmidt)'
                    y = this.Videen_CBF;
                    y = this.registry_.regressFVideenToHersc(y);
                    yLabel1 = [yLabel ' (mL/100 g/min)']; 
                case 'CBV'
                    y = this.CBV;
                    yLabel1 = [yLabel ' (mL/100 g)'];                    
                case 'MTT'
                    y = this.MTT;
                    yLabel1 = [yLabel ' (s)']; 
                case 'k04'
                    y = this.k04;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k21'
                    y = this.k21;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k12'
                    y = this.k12;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k32'
                    y = this.k32;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k43'
                    y = this.k43;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'E_{net}'
                    y = this.E_net;
                    yLabel1 = yLabel;                       
                case 'insulin'
                    y = this.Insulin;
                    yLabel1 = [yLabel ' (\muU/mL)'];
                    yLabel2 =          '(nmol/L)';
                    conversionFactor2 = 6.945e-3;
                case 'epinephrine'
                    y = this.Epi;
                    yLabel1 = [yLabel ' (pg/mL)'];
                    yLabel2 =          '(nmol/L)';
                    conversionFactor2 = 5.485e-3;
                case 'glucagon'
                    y = this.Glucagon;
                    yLabel1 = [yLabel ' (pg/mL)'];
                    yLabel2 =          '(pmol/L)';
                    conversionFactor2 = 0.2871;
                case 'cortisol'
                    y = this.Cortisol;
                    yLabel1 = [yLabel ' (\mug/dL)'];
                    yLabel2 =          '(pmol/L)';
                    conversionFactor2 = 27.59e-3; 
                case 'arterial plasma glucose'    
                    y = this.plasma_glu;
                    yLabel1 = [yLabel ' (mg/dL)'];
                    yLabel2 =          '(mmol/L)';
                    conversionFactor2 = 0.05551;
                case 'total Sx'
                    y = this.NGSx + this.NGPSx;
                    yLabel1 = yLabel;
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

