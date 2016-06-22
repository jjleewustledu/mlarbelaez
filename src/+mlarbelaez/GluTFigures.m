classdef GluTFigures  
	%% GLUTFIGURES   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.6.0.232648 (R2015b) 
 	%  $Id$ 
 	 

	properties
        glut_xlsx = '/Users/jjlee/Documents/WUSTL/Arbelaez/Glucose Threshold manuscript/loopKinetics4_Kinetics4McmcProblem_20150919T1936.xlsx'
        %'/Users/jjlee/Tmp/loopKinetics4_Kinetics4McmcProblem_20150919T1936.xlsx';
        glut_sheet = 'LoopKinetics4';
        dataRows = [2 37]
        mapKin4
        mapMetab
        mapSx

        boxFormat = '%4.2f'
        boxFontSize = 14
        axesFontSize = 14
        axesLabelFontSize = 16
        markerEdgeColor   = [0 0 0]
        markerEdgeColor95 = [0.8 0.309 0.1]
        markerEdgeColor75 = [0.1 0.309 0.8]
        markerFaceColor   = [1 1 1]
        markerFaceColor95 = [1 1 1]
        markerFaceColor75 = [0 0 0]
        markerLineWidth = 1
        stairsColor = [0.618 0.618 0.618]
        barWidth = 0.45
        
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
    
	methods		  
 		function this = GluTFigures(varargin) 
 			%% GLUTFIGURES 
 			%  Usage:  this = GluTFigures() 

            ip = inputParser;
            addOptional(ip, 'xlsxFile', this.glut_xlsx, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            if (~isempty(ip.Results.xlsxFile))
                this.glut_xlsx = ip.Results.xlsxFile; end
            this = this.xlsRead;
            this.registry_ = mlarbelaez.ArbelaezRegistry.instance;
        end 
        function figure0 = createScatterStairs(this, yLabel)
            %% CREATESCATTERSTAIRS
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createScatterStairs('CMR_{glu}/CBV')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
                        
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(yLabel);            
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');            
            
            glu   = this.plasma_glu;            
            glu95 = glu(1:10);   y95 = y(1:10);
            glu75 = glu(11:18);  y75 = y(11:18);
            glu65 = glu(19:28);  y65 = y(19:28);
            glu45 = glu(29:end); y45 = y(29:end);

            range95 = [min(glu95) max(glu95)];
            range75 = [min(glu75) max(glu75)];
            range65 = [min(glu65) max(glu65)];
            range45 = [min(glu45) max(glu45)];

            x0 = [range45(1) mean([range45(2) range65(1)]) mean([range65(2) range75(1)]) mean([range75(2) range95(1)]) range95(2)];
            y0 = [mean(y45) mean(y65) mean(y75) mean(y95) mean(y95)];

            sz1 = 220;
            sz2 = 150;
            sz3 = 220;
            sz4 = 150;
            mark1 = 's';
            mark2 = 'o';
            mark3 = 's';
            mark4 = 'o';

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
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLimX(glu));           
            ylim(axes1,this.axesLimY(y));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','bottom','YAxisLocation','left');

            % Create stairs
            stairs(x0,y0,'LineWidth',2,'Color',this.stairsColor);

            % Create scatter
            scatter(glu45,y45,sz1,mark1,'MarkerEdgeColor',this.markerEdgeColor75,'LineWidth',this.markerLineWidth);
            scatter(glu65,y65,sz2,mark2,'MarkerEdgeColor',this.markerEdgeColor95,'LineWidth',this.markerLineWidth);
            scatter(glu75,y75,sz3,mark3,'MarkerEdgeColor',this.markerEdgeColor75,'LineWidth',this.markerLineWidth);
            scatter(glu95,y95,sz4,mark4,'MarkerEdgeColor',this.markerEdgeColor95,'LineWidth',this.markerLineWidth);
            
            % Create textboxes
            annotation(figure0,'textbox',[0.735223615662053 0.415099651058484 0.101920723226704 0.0702210663198959],...
                'String',{sprintf(this.boxFormat, mean(y45))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.565239409726313 0.580644144778168 0.0866216968011125 0.0650195058517556],...
                'String',{sprintf(this.boxFormat, mean(y65))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.419856226868767 0.576703059383082 0.0838400556328233 0.0689206762028608],...
                'String',{sprintf(this.boxFormat, mean(y75))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.27481721317272 0.668005571299824 0.0754951321279559 0.081924577373212],...
                'String',{sprintf(this.boxFormat, mean(y95))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');    
        end
        function figure0 = createScatterStairs2(this, yLabel)
            %% CREATESCATTERSTAIRS2
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createScatterStairs2('CMR_{glu}/arterial plasma glucose')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(yLabel);            
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            
            glu   = this.plasma_glu;            
            glu95 = glu(1:10);   y95 = y(1:10);
            glu75 = glu(11:18);  y75 = y(11:18);
            glu65 = glu(19:28);  y65 = y(19:28);
            glu45 = glu(29:end); y45 = y(29:end);

            range95 = [min(glu95) max(glu95)];
            range75 = [min(glu75) max(glu75)];
            range65 = [min(glu65) max(glu65)];
            range45 = [min(glu45) max(glu45)];

            x0 = [range45(1) mean([range45(2) range65(1)]) mean([range65(2) range75(1)]) mean([range75(2) range95(1)]) range95(2)];
            y0 = [mean(y45) mean(y65) mean(y75) mean(y95) mean(y95)];

            sz1 = 220;
            sz2 = 150;
            sz3 = 220;
            sz4 = 150;
            mark1 = 's';
            mark2 = 'o';
            mark3 = 's';
            mark4 = 'o';

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
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLimX(glu));           
            ylim(axes1,this.axesLimY(y));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','bottom','YAxisLocation','left');

            % Create stairs
            stairs(x0,y0,'LineWidth',2,'Color',this.stairsColor);

            % Create scatter
            scatter(glu45,y45,sz1,mark1,'MarkerEdgeColor',this.markerEdgeColor75,'LineWidth',this.markerLineWidth);
            scatter(glu65,y65,sz2,mark2,'MarkerEdgeColor',this.markerEdgeColor95,'LineWidth',this.markerLineWidth);
            scatter(glu75,y75,sz3,mark3,'MarkerEdgeColor',this.markerEdgeColor75,'LineWidth',this.markerLineWidth);
            scatter(glu95,y95,sz4,mark4,'MarkerEdgeColor',this.markerEdgeColor95,'LineWidth',this.markerLineWidth);
        end
        function cf      = cftool(this, yLabel)
            [y, yLabel1, yLabel2, conversionFactor2] = this.yLabelLookup(yLabel);            
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            
            glu   = this.plasma_glu;          
            cftool(glu,y);
        end
        function figure0 = createScatterCTXandCMR(this)
            %% CREATESCATTERCTXANDCMR
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createScatterCTXandCMR

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            y1      = this.CTX;
            y2      = this.CMRglu;
            yLabel1 = 'CTX_{glu} (\mumol/100 g/min)';
            yLabel2 = 'CMR_{glu} (\mumol/100 g/min)';
            conversionFactor2 = 1;         
            [~, xLabel1, xLabel2, conversionFactor1] = this.xLabelLookup('arterial plasma glucose');
            glu   = this.plasma_glu; 

            sz1 = 220;
            sz2 = 220;
            mark1 = 's';
            mark2 = 's';

            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0);
            hold(axes2,'on');

            xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);
            ylabel(axes2, yLabel2, 'FontSize', this.axesLabelFontSize);

            xlim(axes2,this.axesLimX(glu*conversionFactor1)); 
            ylim(axes2,this.axesLimY(y1 *conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

            xlim(axes1,this.axesLimX(glu));           
            ylim(axes1,this.axesLimY(y1));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','bottom','YAxisLocation','left');          
            
            % Create scatter
            scatter(glu,y1,sz1,mark1,'MarkerEdgeColor',this.markerEdgeColor,'MarkerFaceColor',[1 1 1],'LineWidth',this.markerLineWidth);
            scatter(glu,y2,sz2,mark2,'MarkerEdgeColor',this.markerEdgeColor,'MarkerFaceColor',[.818 .818 .818],'LineWidth',this.markerLineWidth);
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
            
            y95 = y(1:10);
            y75 = y(11:18);
            y65 = y(19:28);
            y45 = y(29:end);
            %x95 = x(1:10);
            %x75 = x(11:18);
            %x65 = x(19:28);
            %x45 = x(29:end);
            
            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0);
            hold(axes2,'on');

            xlabel(axes2, xLabel2, 'FontSize', this.axesLabelFontSize);
            if (conversionFactor2 ~= 1)
                ylabel(axes2, yLabel2, 'FontSize', this.axesLabelFontSize); end

            xlim(axes2,this.axesLimXBar(x*conversionFactor1)); 
            ylim(axes2,this.axesLimYBar(y*conversionFactor2, ip.Results.limYHard*conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRisingSI,'XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1, 'FontSize', this.axesLabelFontSize);
            ylabel(axes1, yLabel1, 'FontSize', this.axesLabelFontSize);

            xlim(axes1,this.axesLimXBar(x));        
            ylim(axes1,this.axesLimYBar(y, ip.Results.limYHard));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XTick',this.nominalRising,'XAxisLocation','bottom','YAxisLocation','left');

            % Create bar
            xb95 = [this.nominalGlu(1) this.nominalGlu(3)];
            xb75 = [this.nominalGlu(2) this.nominalGlu(4)];
            yb95 = [mean(y95) mean(y65)];
            yb75 = [mean(y75) mean(y45)];
            bar(xb95, yb95, this.barWidth, 'FaceColor', [1 1 1]);
            bar(xb75, yb75, this.barWidth, 'FaceColor', [0.92 0.92 0.92]);
            
            % Create errorbar
            xe = this.nominalGlu;
            ye = [mean(y95) mean(y75) mean(y65) mean(y45)];
            ee = [ std(y95)  std(y75)  std(y65)  std(y45)] ./ ...
                 sqrt([length(y95) length(y75) length(y65) length(y45)]);
            errorbar(xe,ye,ee,'Parent',axes1,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0],'LineStyle','none','LineWidth',1.5,...
                'Color',[0 0 0]);

            % Create textboxes
            %R   = this.axesLimY(y);
            %L   = R(1);
            %D   = R(2) - R(1);
            %z45 = 0.12 + 0.8*(mean(y45) - L)/D;
            %z65 = 0.12 + 0.8*(mean(y65) - L)/D;
            %z75 = 0.12 + 0.8*(mean(y75) - L)/D;
            %z95 = 0.12 + 0.8*(mean(y95) - L)/D;  
            zN  = 0.10;
            zV  = 0.15;
            annotation(figure0,'textbox',[0.705 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y45))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.555 zV 0.11 0.07],...
                'String',{sprintf(this.boxFormat, mean(y65))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.413 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y75))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.266 zV 0.11 0.07],...
                'String',{sprintf(this.boxFormat, mean(y95))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');   
            annotation(figure0,'textbox',[0.698 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y45))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.548 zN 0.11 0.07],...
                'String',{sprintf('N = %i', length(y65))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.406 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y75))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.256 zN 0.11 0.07],...
                'String',{sprintf('N = %i', length(y95))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.433 0.790 0.158 0.0739],...
                'String',{'p = 0.0'},...
                'LineStyle','none',...
                'FontSize',14,...
                'FitBoxToText','off');
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
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapMetab(uint32(idx-this.dataRows(1)+1)) = ...
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
            this.Glucagon = this.vectorize(metab_,11);
            this.Epi      = this.vectorize(metab_,12);
            this.Norepi   = this.vectorize(metab_,13);
            this.Insulin  = this.vectorize(metab_,10);
            this.Cortisol = this.vectorize(metab_,7);
            
            [~,~,sx_] = xlsread(this.glut_xlsx, 'Sx');
            this.mapSx = containers.Map('KeyType', 'uint32', 'ValueType', 'any');       
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapSx(uint32(idx-this.dataRows(1)+1)) = ...
                    struct('p',        sx_{idx,2}, ...
                        'scan',        sx_{idx,3}, ...
                        'nominal_glu', sx_{idx,4}, ...
                        'plasma_glu',  sx_{idx,5}, ...
                        'NGPSx',       sx_{idx,6}, ...
                        'NGSx',        sx_{idx,7}, ...
                        'TotalSx',     sx_{idx,8});
            end
            this.NGPSx   = this.vectorize(sx_,6);
            this.NGSx    = this.vectorize(sx_,7);            
            this.TotalSx = this.vectorize(sx_,8);
        end
        function c = cellulize(this, arr, col)
            clen = this.dataRows(2) - this.dataRows(1) + 1;
            D = this.dataRows(1) - 1;
            c = cell(1, clen);
            for ic = 1:clen
                c{ic} = arr{ic+D, col};
            end
        end
        function v = vectorize(this, arr, col)
            vlen = this.dataRows(2) - this.dataRows(1) + 1;
            D = this.dataRows(1) - 1;
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
            conversionFactor1 = 0.0551;
        end
        function [y,yLabel1,yLabel2,conversionFactor2] = yLabelLookup(this, yLabel)
            conversionFactor2 = 1;
            yLabel2 = '';
            switch (yLabel)
                case 'CTX_{glu} - \langle CMR_{glu}(>45 mg/dL) \rangle'
                    y = this.CTX - mean(this.CMRglu(1:28));
                    yLabel1 = [yLabel ''];
                case 'CTX_{glu} - CMR_{glu}(92 mg/dL)'
                    y = this.CTX - 23.6;
                    yLabel1 = [yLabel ''];
                case 'CTX_{glu}/CMR_{glu}'
                    y = this.CTX ./ this.CMRglu;
                    yLabel1 = [yLabel ''];
                case 'CMR_{glu}/CTX_{glu}'
                    y = this.CMRglu ./ this.CTX;
                    yLabel1 = [yLabel ''];
                case '(CTX_{glu} - CMR_{glu})/CBV'
                    y = (this.CTX - this.CMRglu) ./ this.CBV;
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'CTX_{glu} - CMR_{glu}'
                    y = this.CTX - this.CMRglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CMR_{glu}'
                    y = this.CMRglu;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'CTX_{glu}'
                    y = this.CTX;
                    yLabel1 = [yLabel ' (\mumol/100 g/min)'];
                case 'Free brain glucose'
                    y = this.free_glu;                   
                    yLabel1 = [yLabel ' (\mumol/g)'];
                case 'CTX_{glu}/CBV'
                    y = this.CTX ./ this.CBV;
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'CMR_{glu}/CBV'
                    y = this.CMRglu ./ this.CBV;               
                    yLabel1 = [yLabel ' (\mumol/mL/min)'];
                case 'Free brain glucose/CBV'   
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
                case 'k_{04}'
                    y = this.k04;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{21}'
                    y = this.k21;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{21}k_{32} / (k_{12} + k_{32})'
                    y = this.k21 .* this.k32 ./ (this.k12 + this.k32);
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{32} / (k_{12} + k_{32})'
                    y = this.k32 ./ (this.k12 + this.k32);
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{12}'
                    y = this.k12;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{32}'
                    y = this.k32;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'k_{43}'
                    y = this.k43;
                    yLabel1 = [yLabel ' (1/min)'];
                case 'E_{net}'
                    y = this.E_net;
                    yLabel1 = yLabel;                       
                case 'Insulin'
                    y = this.Insulin;
                    yLabel1 = [yLabel ' (\muU/mL)'];
                    yLabel2 =          '(nmol/L)';
                    conversionFactor2 = 6.945e-3;
                case 'Epinephrine'
                    y = this.Epi;
                    yLabel1 = [yLabel ' (pg/mL)'];
                    yLabel2 =          '(nmol/L)';
                    conversionFactor2 = 5.485e-3;
                case 'Glucagon'
                    y = this.Glucagon;
                    yLabel1 = [yLabel ' (pg/mL)'];
                    yLabel2 =          '(pmol/L)';
                    conversionFactor2 = 0.2871;
                case 'Cortisol'
                    y = this.Cortisol;
                    yLabel1 = [yLabel ' (\mug/dL)'];
                    yLabel2 =          '(pmol/L)';
                    conversionFactor2 = 27.59e-3; 
                case 'Arterial plasma glucose'    
                    y = this.plasma_glu;
                    yLabel1 = [yLabel ' (mg/dL)'];
                    yLabel2 =          '(mmol/L)';
                    conversionFactor2 = 0.0551;
                case 'Total Sx'
                    y = this.NGSx + this.NGPSx;
                    yLabel1 = yLabel;
                case 'Neurogenic symptom score'
                    y = this.NGSx;
                    yLabel1 = yLabel;
                case 'Neuroglycopenic symptom score'
                    y = this.NGPSx;
                    yLabel1 = yLabel;                    
                otherwise
                    error('mlarbelaez:unsupportedSwitchCase', 'yLabel was %s', yLabel);
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

