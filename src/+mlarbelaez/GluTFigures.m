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
        glut_xlsx = '/Users/jjlee/Documents/WUSTL/Arbelaez/Glucose Threshold manuscript/report_2015aug10.xlsx'
        dataRows = [2 37]
        mapKin4
        mapMetab
        mapSx

        boxFormat = '%4.0f'
        boxFontSize = 12
        axesFontSize = 14
        markerEdgeColor95 = [0.8 0.309 0.1]
        markerEdgeColor75 = [0.1 0.309 0.8]
        markerLineWidth = 1.5
        stairsColor = [0.618 0.618 0.618]
        
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
    end
    
	methods		  
 		function this = GluTFigures(varargin) 
 			%% GLUTFIGURES 
 			%  Usage:  this = GluTFigures() 

            this = this.xlsRead;
        end 
        function figure0 = createGluFigure(this, yLabel)
            %% CREATEGLUFIGURE
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createGluFigure(glutf.CMRglu./glutf.plasma_glu, 'CMR_{glu}/arterial plasma glucose')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            
            yLabel1 = yLabel;
            conversionFactor2 = 1;
            switch (yLabel)
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
                case 'CBV'
                    y = this.CBV;
                    yLabel1 = [yLabel ' (mL/100 g)'];                    
                case 'insulin'
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
                    conversionFactor2 = 0.0551;
                case 'total Sx'
                    y = this.NGSx + this.NGPSx;
                    yLabel1 = yLabel;
            end

            xLabel  = 'arterial plasma glucose';
            xLabel1 = [xLabel ' (mg/dL)'];
            xLabel2 =          '(mmol/L)';
            conversionFactor1 = 0.0551;
            
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

            xlim(axes2,this.axesLim(glu*conversionFactor1)); 
            ylim(axes2,this.axesLim(y  *conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLim(glu));           
            ylim(axes1,this.axesLim(y));
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
        function figure0 = createGluFigure2(this, yLabel)
            %% CREATEGLUFIGURE
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createGluFigure(glutf.CMRglu./glutf.plasma_glu, 'CMR_{glu}/arterial plasma glucose')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            yLabel1 = yLabel;
            conversionFactor2 = 1;
            switch (yLabel)
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
                case 'CBV'
                    y = this.CBV;
                    yLabel1 = [yLabel ' (mL/100 g)'];                    
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
                    conversionFactor2 = 0.0551;
                case 'total Sx'
                    y = this.NGSx + this.NGPSx;
                    yLabel1 = yLabel;
            end

            xLabel  = 'arterial plasma glucose';
            xLabel1 = [xLabel ' (mg/dL)'];
            xLabel2 =          '(mmol/L)';
            conversionFactor1 = 0.0551;
            
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

            xlim(axes2,this.axesLim(glu*conversionFactor1)); 
            ylim(axes2,this.axesLim(y  *conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLim(glu));           
            ylim(axes1,this.axesLim(y));
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
        function figure0 = createGluFigure3(this, yLabel)
            %% CREATEGLUFIGURE
            %  e.g., glutf = GluTFigures;
            %        f = glutf.createGluFigure(glutf.CMRglu./glutf.plasma_glu, 'CMR_{glu}/arterial plasma glucose')

            %y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            %y = 100*y; % converts \frac{\mumol}{g} \frac{100 g}{mL} to \frac{\mumol}{mL}
            
            yLabel1 = yLabel;
            conversionFactor2 = 1;
            switch (yLabel)
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
                case 'CBV'
                    y = this.CBV;
                    yLabel1 = [yLabel ' (mL/100 g)'];                    
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
                    conversionFactor2 = 0.0551;
                case 'total Sx'
                    y = this.NGSx + this.NGPSx;
                    yLabel1 = yLabel;
            end

            xLabel  = 'arterial plasma glucose';
            xLabel1 = [xLabel ' (mg/dL)'];
            xLabel2 =          '(mmol/L)';
            conversionFactor1 = 0.0551;
            
            glu   = this.plasma_glu;            
            glu95 = glu(1:10);   y95 = y(1:10);
            glu75 = glu(11:18);  y75 = y(11:18);
            glu65 = glu(19:28);  y65 = y(19:28);
            glu45 = glu(29:end); y45 = y(29:end);

            %range95 = [min(glu95) max(glu95)];
            %range75 = [min(glu75) max(glu75)];
            %range65 = [min(glu65) max(glu65)];
            %range45 = [min(glu45) max(glu45)];

            %x0 = [range45(1) mean([range45(2) range65(1)]) mean([range65(2) range75(1)]) mean([range75(2) range95(1)]) range95(2)];
            %y0 = [mean(y45) mean(y65) mean(y75) mean(y95) mean(y95)];

            % Create figure
            figure0 = figure;

            % Create axes2
            axes2 = axes('Parent',figure0);
            hold(axes2,'on');

            xlabel(axes2, xLabel2);
            if (conversionFactor2 ~= 1)
                ylabel(axes2, yLabel2); end

            xlim(axes2,this.axesLim(glu*conversionFactor1)); 
            ylim(axes2,this.axesLim(y  *conversionFactor2));
            set(axes2,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','top','YAxisLocation','right');

            % Create axes1
            axes1 = axes('Parent',figure0);
            hold(axes1,'on');

            xlabel(axes1, xLabel1);
            ylabel(axes1, yLabel1);

            xlim(axes1,this.axesLim(glu));           
            ylim(axes1,this.axesLim(y));
            box(axes1,'on');
            set(axes1,'FontSize',this.axesFontSize,'XDir','reverse','XAxisLocation','bottom','YAxisLocation','left');

            % Create stairs
            %stairs(x0,y0,'LineWidth',2,'Color',this.stairsColor);

            % Create bar
            xb95 = [95 65];
            xb75 = [75 45];
            yb95 = [mean(y95) mean(y65)];
            yb75 = [mean(y75) mean(y45)];
            bar(xb95, yb95, 1/3, 'FaceColor', [0.92 0.92 0.92]);
            bar(xb75, yb75, 1/3, 'FaceColor', [1 1 1]);
            
            % Create errorbar
            xe = [95 75 65 45];
            ye = [mean(y95) mean(y75) mean(y65) mean(y45)];
            ee = [ std(y95)  std(y75)  std(y65)  std(y45)] ./ ...
                 sqrt([length(y95) length(y75) length(y65) length(y45)]);
            errorbar(xe,ye,ee,'Parent',axes1,'MarkerFaceColor',[0 0 0],'MarkerEdgeColor',[0 0 0],'LineStyle','none','LineWidth',1,...
                'Color',[0 0 0]);

            % Create textboxes
            R   = this.axesLim(y);
            L   = R(1);
            D   = R(2) - R(1);
            z45 = 0.12 + 0.8*(mean(y45) - L)/D;
            z65 = 0.12 + 0.8*(mean(y65) - L)/D;
            z75 = 0.12 + 0.8*(mean(y75) - L)/D;
            z95 = 0.12 + 0.8*(mean(y95) - L)/D;  
            zN  = 0.12;
            zV  = 0.17;
            annotation(figure0,'textbox',[0.718 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y45))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.535 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y65))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.441 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y75))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.259 zV 0.09 0.07],...
                'String',{sprintf(this.boxFormat, mean(y95))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');   
            annotation(figure0,'textbox',[0.720 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y45))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.528 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y65))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.439 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y75))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');
            annotation(figure0,'textbox',[0.254 zN 0.09 0.07],...
                'String',{sprintf('N = %i', length(y95))},...
                'LineStyle','none',...
                'FontSize',this.boxFontSize,...
                'FitBoxToText','off');            
        end
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')        
        function this = xlsRead(this)
            [~,~,kin4_] = xlsread(this.glut_xlsx, 'Kinetics4');
            this.mapKin4 = containers.Map('KeyType', 'uint32', 'ValueType', 'any');
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapKin4(uint32(idx-this.dataRows(1)+1)) = ...
                    struct('p',        kin4_{idx, 2}, ...
                        'scan',        kin4_{idx, 3}, ...
                        'nominal_glu', kin4_{idx, 4}, ...
                        'plasma_glu',  kin4_{idx, 5}, ...
                        'CBV',         kin4_{idx, 7}, ...
                        'CMRglu',      kin4_{idx,16}, ...
                        'CTX',         kin4_{idx,19}, ...
                        'free_glu',    kin4_{idx,20}, ...
                        'MTT',         kin4_{idx,21}, ...
                        'Videen_CBF',  kin4_{idx,24});
            end
            this.p           = this.cellulize(kin4_, 2);
            this.scan        = this.vectorize(kin4_, 3);
            this.nominal_glu = this.vectorize(kin4_, 4);
            this.plasma_glu  = this.vectorize(kin4_, 5);
            this.CBV         = this.vectorize(kin4_, 7);
            this.CMRglu      = this.vectorize(kin4_,16);
            this.CTX         = this.vectorize(kin4_,19);
            this.free_glu    = this.vectorize(kin4_,20);
            this.MTT         = this.vectorize(kin4_,21);
            this.Videen_CBF  = this.vectorize(kin4_,24);
            
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
        function range = axesLim(~, dat)
            Delta = (max(dat) - min(dat))*2*0.1618;        
            low   = min(dat) - Delta;
            low   = max(low, 0);
            high  = max(dat) + Delta;
            range = [low high];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

