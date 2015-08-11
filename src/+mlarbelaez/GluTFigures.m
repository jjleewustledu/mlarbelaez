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

        boxFormat = '%4.1f'
        boxFontSize = 14
        axesFontSize = 14
        markerEdgeColor = [0.501960813999176 0.501960813999176 0.501960813999176]
        stairsColor = [0 0 0]
        
        p
        scan
        nominal_glu
        plasma_glu
        CBV
        CMRglu
        CTX
        MTT
        Videen_CBF
        Glucagon
        Epi
        Norepi
        NGPSx
        NGSx
    end
    
	methods		  
 		function this = GluTFigures(varargin) 
 			%% GLUTFIGURES 
 			%  Usage:  this = GluTFigures() 

            this = this.xlsRead;
        end 
        function figure0 = createGluFigure(this, y)

            y = 1e3*y/55.507; % converts frac{\mumol}{100 g min} \frac{dL}{mg} to mL/100g/min
            
            xLabel  = 'arterial plasma glucose';
            yLabel  = 'CMR_{glu}/glucose';
            xLabel1 = [xLabel ' (mg/dL)'];
            yLabel1 = [yLabel ' (\muL/100 g/min)'];
            xLabel2 = [xLabel ' (mmol/L)'];
            yLabel2 = [yLabel ' '];
            conversionFactor1 = 0.0551;
            conversionFactor2 = 1;

            glu = this.plasma_glu;
            
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

            sz1 = 150;
            sz2 = 200;
            mark1 = 'o';
            mark2 = 's';
            mark3 = 'o';
            mark4 = 's';

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
            scatter(glu45,y45,sz1,mark1,'MarkerEdgeColor',this.markerEdgeColor);
            scatter(glu65,y65,sz2,mark2,'MarkerEdgeColor',this.markerEdgeColor,'Marker','square');
            scatter(glu75,y75,sz1,mark3,'MarkerEdgeColor',this.markerEdgeColor);
            scatter(glu95,y95,sz2,mark4,'MarkerEdgeColor',this.markerEdgeColor,'Marker','square');

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
                        'Norepi',      metab_{idx,13});
            end
            this.Glucagon = this.vectorize(metab_,11);
            this.Epi      = this.vectorize(metab_,12);
            this.Norepi   = this.vectorize(metab_,13);
            
            [~,~,sx_] = xlsread(this.glut_xlsx, 'Sx');
            this.mapSx = containers.Map('KeyType', 'uint32', 'ValueType', 'any');       
            for idx = this.dataRows(1):this.dataRows(2)
                this.mapSx(uint32(idx-this.dataRows(1)+1)) = ...
                    struct('p',        sx_{idx,2}, ...
                        'scan',        sx_{idx,3}, ...
                        'nominal_glu', sx_{idx,4}, ...
                        'plasma_glu',  sx_{idx,5}, ...
                        'NGPSx',       sx_{idx,6}, ...
                        'NGSx',        sx_{idx,7});
            end
            this.NGPSx = this.vectorize(sx_,6);
            this.NGSx  = this.vectorize(sx_,7);
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
            high  = max(dat) + Delta;
            range = [low high];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

