classdef GluTRegionFigures  
	%% GLUTREGIONFIGURES is a rapid prototype

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
        barWidth = 0.475
        
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
    end
    
    methods (Static)
        function this = createBarErrs
            this = mlarbelaez.GluTRegionFigures;
            labels  = {'CMR_{glu}' 'CTX_{glu}' 'E_{net}' 'free glucose' 'CBF' 'CBV' 'MTT' };
            regions = {'amygdala' 'hippocampus' 'hypothalamus' 'mpfc' 'thalamus'};
            for l = 1:length(labels)
                for r = 1:length(regions)
                    this.createBarErr(labels{l}, regions{r});
                    aFig = get(0, 'children');
                    saveas(aFig, sprintf('%s_%s.fig', regions{r}, labels{l}));
                    saveas(aFig, sprintf('%s_%s.png', regions{r}, labels{l}));
                    close(aFig);
                end
            end
        end
    end
    
	methods		  
 		function this = GluTRegionFigures(varargin) 
 			%% GLUTREGIONFIGURES 
 			%  Usage:  this = GluTFigures() 

            ip = inputParser;
            addOptional(ip, 'xlsxFile', this.glut_xlsx, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.xlsxFile))
                this.glut_xlsx = ip.Results.xlsxFile; end
            this = this.xlsRead;
            this.registry_ = mlarbelaez.ArbelaezRegistry.instance;
        end 
        function [x,y] = selectRegion(this, y, region)
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
                    error('mlarbelaez:unsupportedSwitchCase', 'GluTRegionFigures.selectRegion.region->%s', region);
            end
            x = this.plasma_glu;
            x = x(rng);
            y = y(rng);
        end
        function figure0 = createScatter(this, yLabel, region)
            %% CREATESCATTERSTAIRS2
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createScatterStairs2('CMR_{glu}/arterial plasma glucose')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(yLabel, region);            
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');            
            [glu,y] = this.selectRegion(y, region); 
            
            glu95 = glu(1:5);    y95 = y(1:5);
            glu75 = glu(6:10);   y75 = y(6:10);
            glu65 = glu(11:15);  y65 = y(11:15);
            glu45 = glu(16:end); y45 = y(16:end);

            range95 = [min(glu95) max(glu95)];
            range75 = [min(glu75) max(glu75)];
            range65 = [min(glu65) max(glu65)];
            range45 = [min(glu45) max(glu45)];

            x0 = [range45(1) mean([range45(2) range65(1)]) mean([range65(2) range75(1)]) mean([range75(2) range95(1)]) range95(2)];
            y0 = [mean(y45) mean(y65) mean(y75) mean(y95) mean(y95)];

            sz1 = 220;
            sz2 = 220;
            sz3 = 220;
            sz4 = 220;
            mark1 = 's';
            mark2 = 's';
            mark3 = 's';
            mark4 = 's';

            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0);
            hold(axes2,'on');

            xlabel(axes2, xLabel2);
            if (conversionFactor2 ~= 1)
                ylabel(axes2, yLabel2); end

            xlim(axes2,this.axesLimX(glu*conversionFactor1)); 
            ylim(axes2,this.axesLimY(y  *conversionFactor2));
            box(axes2,'on');
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLimX(glu));           
            ylim(axes1,this.axesLimY(y));
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','bottom','YAxisLocation','left');

            % Create stairs
            % stairs(x0,y0,'LineWidth',2,'Color',this.stairsColor);

            % Create scatter
            scatter(glu45,y45,sz1,mark1,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',this.markerFaceColor75,'LineWidth',this.markerLineWidth);
            scatter(glu65,y65,sz2,mark2,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',this.markerFaceColor95,'LineWidth',this.markerLineWidth);
            scatter(glu75,y75,sz3,mark3,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',this.markerFaceColor75,'LineWidth',this.markerLineWidth);
            scatter(glu95,y95,sz4,mark4,'MarkerEdgeColor',[0 0 0],'MarkerFaceColor',this.markerFaceColor95,'LineWidth',this.markerLineWidth);
        end
        function figure0 = createBarErr(this, yLabel, varargin)
            %% CREATEBARERR
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createBarErr('CMR_{glu}/CBV')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            ip = inputParser;
            addRequired(ip, 'yLabel', @ischar);
            addOptional(ip, 'region', 'thalamus', @ischar);
            addOptional(ip, 'limYHard', [], @isnumeric);
            parse(ip, yLabel, varargin{:});
            
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(ip.Results.yLabel, ip.Results.region);   
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('nominal arterial plasma glucose');            
            [x,y] = this.selectRegion(y, ip.Results.region); 
            
            y95 = y( 1:5);
            y75 = y( 6:11);
            y65 = y(12:16);
            y45 = y(17:22);
            
            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRisingSI,'TickLength',[0 0],'XAxisLocation','top','YAxisLocation','right');
            
            xlabel(axes2, xLabel2);
            if (conversionFactor2 ~= 1)
                ylabel(axes2, yLabel2); end

            xlim(axes2,this.axesLimXBar(x*conversionFactor1));
            ylim(axes2,this.axesLimYBar(y*conversionFactor2, ip.Results.limYHard*conversionFactor2));

            % Create axes1
            axes1 = axes('Position',axes2.Position,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRising,'XAxisLocation','bottom','YAxisLocation','left');
            box(axes1,'on');
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLimXBar(x));
            ylim(axes1,this.axesLimYBar(y, ip.Results.limYHard));

            % Create bar
            xb95 = [this.nominalGlu(1) this.nominalGlu(3)];
            xb75 = [this.nominalGlu(2) this.nominalGlu(4)];
            yb95 = [mean(y95) mean(y65)];
            yb75 = [mean(y75) mean(y45)];
            bar(xb95, yb95, this.barWidth,'Parent',axes1,'FaceColor',[1 1 1]);
            bar(xb75, yb75, this.barWidth,'Parent',axes1,'FaceColor',[0.92 0.92 0.92]);
            
            % Create errorbar
            xe = this.nominalGlu;
            ye = [mean(y95) mean(y75) mean(y65) mean(y45)];
            ee = [ std(y95)  std(y75)  std(y65)  std(y45)] ./ ...
                 sqrt([length(y95) length(y75) length(y65) length(y45)]);
            errorbar(xe,ye,ee,'Parent',axes1,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0],'LineStyle','none','LineWidth',1.5,...
                'Color',[0 0 0]);

            %% Create textboxes
            
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
        function saveFigures(varargin)
            ip = inputParser;
            addOptional(ip, 'location', pwd, @isdir);
            parse(ip, varargin{:});

            cd(ip.Results.location);
            theFigs = get(0, 'children');
            N = numel(theFigs);
            assert(N < 1000, 'saveFigures only supports up to 999 open figures');
            for f = 1:N
                aFig = theFigs(f);
                figure(aFig);
                saveas(aFig, sprintf('%03d.fig', N-f+1));
                saveas(aFig, sprintf('%03d.png', N-f+1));
                close(aFig);
            end
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        registry_
    end
    
    methods (Access = 'private')        
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
            x       = this.plasma_glu;  
            xLabel1 = [xLabel ' (mg/dL)'];
            xLabel2 =          '(mmol/L)';
            conversionFactor1 = 0.05551;
        end
        function [y,yLabel1,yLabel2,conversionFactor2] = yLabelLookup(this, yLabel, region)
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
            yLabel1 = [region ' ' yLabel1];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

