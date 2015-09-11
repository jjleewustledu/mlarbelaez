classdef Kinetics4Diagnostics  
	%% KINETICS4DIAGNOSTICS   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties (Constant)
        GLUTHOME = '/Volumes/InnominateHD3/Arbelaez/GluT'
 	end 

	methods (Static)
        
        function forallGluT(funch)            
            pwd0 = pwd;
            cd(mlarbelaez.Kinetics4Diagnostics.GLUTHOME);
            dt = mlsystem.DirTool('p*_JJL');
            for t = 1:dt.length
                for s = 1:2
                    funch(dt.fqdns{t}, s);
                end
            end
            cd(pwd0);
        end
        function plotDta(pth, snum)
            pnum = str2pnum(pth);     
            dta = mlpet.DTA.load( ...
                  fullfile(pth, 'jjl_proc', sprintf('%sg%i.dta',  pnum, snum)));
            mlarbelaez.Kinetics4Diagnostics.plotSemilogx(dta, dta.wellCounts, dta.wellCountInterpolants, 'well counts');
        end
 		function plotTsc(pth, snum)
            pnum = str2pnum(pth);   
            tsc = mlpet.TSC.import( ...
                  fullfile(pth, 'jjl_proc', sprintf('%swb%i.tsc',  pnum, snum)));
            mlarbelaez.Kinetics4Diagnostics.plot(tsc, tsc.becquerels, tsc.becquerelInterpolants, 'Bq');
        end 
        function plotSemilogx(petObj, c, ci, yl)
            f1 = figure;             
            a1 = axes('Parent',f1,'XScale','log');
            box(a1,'on');
            hold(a1,'on');
            semilogx(petObj.times,c,'DisplayName','from dta','MarkerSize',8,'Marker','o','LineStyle','none');
            semilogx(petObj.timeInterpolants,ci,'DisplayName','interpolants');
            xlabel('time / s');
            ylabel(yl);
            title(petObj.fqfilename, 'Interpreter', 'none');
            l1 = legend(a1,'show');
            set(l1,'EdgeColor',[1 1 1]);
        end
        function plot(petObj, c, ci, yl)
            f1 = figure;             
            a1 = axes('Parent',f1,'XScale','linear');
            box(a1,'on');
            hold(a1,'on');
            plot(petObj.times,c,'DisplayName','from dta','MarkerSize',8,'Marker','o','LineStyle','none');
            plot(petObj.timeInterpolants,ci,'DisplayName','interpolants');
            xlabel('time / s');
            ylabel(yl);
            title(petObj.fqfilename, 'Interpreter', 'none');
            l1 = legend(a1,'show');
            set(l1,'EdgeColor',[1 1 1]);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

