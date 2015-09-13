classdef YSI 
	%% YSI   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.6.0.232648 (R2015b) 
 	%  $Id$ 
 	 

	properties (Constant)
        GLUT_HOME = '/Volumes/InnominateHD3/Arbelaez/GluT'
        YSI_XLSX  = '/Users/jjlee/Documents/WUSTL/Arbelaez/Glucose Threshold manuscript/report_2015jul21.xlsx'
    end 

    properties (Dependent)
        np
        pid
        raw
        scanInfo
        ysi
    end
    
    methods % GET
        function y = get.np(this)
            y = this.np2pid_.keys;
        end
        function y = get.pid(this)
            y = this.pid2np_.keys;
        end
        function y = get.raw(this)
            y = this.raw_;
        end
        function s = get.scanInfo(this)
            s = this.scanInfo_;
        end
        function y = get.ysi(this)
            y = this.ysi_;
        end
    end
    
    methods (Static)
        function info = collectScanInfo
            
            cd(mlarbelaez.YSI.GLUT_HOME);
            icell = cell(1,2);
            info  = containers.Map;
            dt    = mlsystem.DirTools('p*_JJL');
            for d = 1:18
                for s = 1:2
                    try
                        cd(fullfile(mlarbelaez.YSI.GLUT_HOME, dt.dns{d}, 'PET', sprintf('scan%i', s), ''));
                        pnum = str2pnum(dt.dns{d});
                        tr   = mlpet.ImgRecParser.load(sprintf('%str%i.img.rec',   pnum, s));
                        oc   = mlpet.ImgRecParser.load(sprintf('%soc%i.img.rec',   pnum, s));
                        ho   = mlpet.ImgRecParser.load(sprintf('%sho%i.img.rec',   pnum, s));
                        gluc = mlpet.ImgRecParser.load(sprintf('%sgluc%i.img.rec', pnum, s));
                        
                        icell{s} = struct('tr', tr, 'oc', oc, 'ho', ho, 'gluc', gluc);
                    catch ME
                        handwarning(ME);
                    end
                end                
                info(pnum) = struct('scan1', icell{1}, 'scan2', icell{2});
            end            
        end
        function [t0,t1] = startEndTime(infoEle, scanId)
            t0 = datetime( ...
                sprintf('%s %s', ...
                        infoEle.(scanId).tr.scanDate, ...
                        infoEle.(scanId).tr.scanTime), ...
                'InputFormat', 'MM/dd/yyyy HH:mm');
            
            t1 = datetime( ...
                sprintf('%s %s', ...
                        infoEle.(scanId).gluc.scanDate, ...
                        infoEle.(scanId).gluc.scanTime), ...
                'InputFormat', 'MM/dd/yyyy HH:mm');
            t1 = t1 + duration(0,60,0);
        end
    end
    
	methods 		  
 		function this = YSI 
 			%% YSI 
 			%  Usage:  this = YSI
 			 
            import mlarbelaez.*;
            this.scanInfo_ = YSI.collectScanInfo;
            this = this.loadIdLists;
            this = this.loadYSI;
        end 
        function pid = np2pid(this, np)
            pid = this.np2pid_(np);
        end
        function np = pid2np(this, pid)
            np = this.pid2np_(pid);
        end
        function plotGlu(this, pid)
            ele = this.ysi_(this.pid2np(pid));
            figure1 = figure;
            plot(ele.time, ele.glu,'Marker','o','LineStyle','none');
            title(pid);
            xlabel('time');
            ylabel('art plasma glu (mg/dL)');
            [t1,t2] = this.startEndTime(this.scanInfo(pid), 'scan1');
            [t3,t4] = this.startEndTime(this.scanInfo(pid), 'scan2');
            annotation(figure1,'textbox',[0.629571428571427 0.534741959611071 0.244459579180511 0.35952380952381],...
                'String',{'scan1:',char(t1),char(t2),'scan2:',char(t3),char(t4)},...
                'FitBoxToText','off',...
                'EdgeColor','none');
        end
        function [g1,g2] = scannedGlu(this, pid, offset)
            if (~exist('offset', 'var'))
                offset = days(0);
            end
            ele = this.ysi_(this.pid2np(pid));         
            [t11,t12] = this.startEndTime(this.scanInfo(pid), 'scan1');
            [t21,t22] = this.startEndTime(this.scanInfo(pid), 'scan2');
            t11 = t11 + offset;
            t12 = t12 + offset;
            g1 = []; g2 = [];
            
            for it = 1:length(ele.time)
                if (t11 <= ele.time(it) && ele.time(it) <= t12)
                    if (~isnan(ele.glu(it)))
                        g1 = [g1 ele.glu(it)];
                    end
                end
                if (t21 <= ele.time(it) && ele.time(it) <= t22)
                    if (~isnan(ele.glu(it)))
                        g2 = [g2 ele.glu(it)];
                    end
                end
            end
        end        
        function report(this, fqfn)
            %% REPORT
            %  mL/min/100g, umul/mL, 1/min, sec            

            cd(this.GLUT_HOME);
            fid = fopen(fqfn, 'w');
            for s = 1:2
                for p = 1:length(this.pid)
                    try
                        if (1 == s); this.plotGlu(this.pid{p}); end
                        this.printCsvLine(fid, this.pid{p}, s);
                    catch ME
                        handexcept(ME);
                    end
                end
            end
            fprintf(fid, '\n');
            fclose(fid);
        end
        function printCsvLine(this, fid, pid, s)
            [g1,g2] = this.scannedGlu(pid);
            if (1 == s)
                glu = g1; 
            else
                glu = g2;
            end
            n = length(glu);
            se = std(glu)/sqrt(n);
            fprintf(fid, sprintf('%s,%s,%i,%f,%f,%i\n', this.pid2np(pid), pid, s, mean(glu), se, n));
        end
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        np2pid_
        pid2np_
        raw_
        scanInfo_
        ysi_
    end

    methods (Static, Access = 'protected')
        function x = loadNpLabels(raw)
            x  = cell(1,size(raw,2)-1);
            for c = 2:size(raw,2)
                x{c-1} = raw{1,c};
            end
        end
    end
    
    methods (Access = 'protected')        
        function this = loadIdLists(this)
            [~,~,rawNp] = xlsread(this.YSI_XLSX, 'Kinetics4', 'A2:A19');
            [~,~,rawP]  = xlsread(this.YSI_XLSX, 'Kinetics4', 'B2:B19');
            
            this.np2pid_ = containers.Map;
            this.pid2np_ = containers.Map;
            for r = 1:length(rawNp)
                this.np2pid_(rawNp{r}) = rawP{r};
                this.pid2np_(rawP{r})  = rawNp{r};
            end            
        end
        function this = loadYSI(this)
            [~,~,raw__] = xlsread(this.YSI_XLSX, 'YSI', 'A1:V89');
            npLabels  = this.loadNpLabels(raw__);            
            this.ysi_ = containers.Map;
            
            for idx = 1:length(npLabels)   
                if (lstrfind(this.np2pid_.keys, npLabels{idx}))
                    glu  = this.ysi2glu(idx, raw__);
                    time = this.ysi2datetime(length(glu), raw__, npLabels{idx});
                    this.ysi_(npLabels{idx}) = ...
                        struct('time', time, 'glu',  glu);
                end
            end
            this.raw_ = raw__;
        end
        function dts = ysi2datetime(this, len, raw, np)
            for r = 3:2+len
                times(r-2) = raw{r,1}; % do not pre-allocate
            end
            time1  = times(end);
            pid_   = this.np2pid_(np);            
            [~,dt1] = this.startEndTime(this.scanInfo_(pid_), 'scan2');
            dts = dt1 - duration(0, time1 - times,0);
        end
        function g = ysi2glu(~, col, raw)
            for r = 3:size(raw,1)
                if (raw{r,col+1} < 0); break; end
                g(r-2) = raw{r,col+1}; % do not pre-allocate
            end
        end
    end
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

