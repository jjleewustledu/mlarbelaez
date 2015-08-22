classdef GlutWorker  
	%% GLUTWORKER   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
 		 
 	end 

	methods (Static)
        function loopStudies
            pwd0 = pwd;
            [~,folder] = fileparts(pwd0);
            assert(strcmp('GluT', folder));
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            for d = 1:length(dt.dns)
                cd(fullfile(pwd0, dt.dns{d}, ''));
                fprintf('GlutWorker.loopStudies:  working in %s\n', pwd);
                for s = 1:2
                    try
                        mlarbelaez.GlutWorker.writeTsc(s);
                    catch ME
                        handwarning(ME)
                    end
                end
                cd(pwd0);
            end
        end
        function maskAparc
            aparc = 'aparc_a2009s+aseg';
            assert(lexist(sprintf('%s.nii.gz', aparc),   'file'));
            toremove = [16 7 8 46 47 14 15 4 43 31 63 24]; % brainstem cerebellumx4 ventriclesx4 choroidplexus csf
            
            import mlfourd.*;
            nii = NIfTI.load(aparc);
            for r = 1:length(toremove)
                nii.img(nii.img == toremove(r)) = 0;
            end
            nii.img = nii.img > 0;
            nii.saveas('aparc_a2009s+aseg_mask.nii.gz');
        end
        function mcflirtGluc(snum)
            assert(isnumeric(snum));
            pnum = str2pnum(pwd);
            
            import mlfourd.*;
            dyn = DynamicNIfTId.load(sprintf('%sgluc%i.nii.gz', pnum, snum));
            dyn = dyn.mcflirtedAfterBlur([16 16 16]);
            dyn = dyn.revertFrames(NIfTId.load(sprintf('%sgluc%i.nii.gz', pnum, snum)), 1:5);
            dyn.freeview;
            dyn.save;
            
            dyn_summed = dyn;
            dyn_summed = dyn_summed.timeSummed;
            dyn_summed.save;
        end
        function timeSumGluc(snum)
            assert(isnumeric(snum));
            pnum = str2pnum(pwd);
            
            import mlfourd.*;
            dyn_summed = DynamicNIfTId.load(sprintf('%sgluc%i_mcf_revf1to5.nii.gz', pnum, snum));
            dyn_summed = dyn_summed.timeSummed;
            dyn_summed.freeview;
            dyn_summed.save;            
        end
        function flirtFreesurferImage(snum)
            %% FLIRTAPARC flirts aparc_a2009s+aseg_mask, then reviews registrations with fslview
            %  Usage:  glutWorker3() 

            assert(isnumeric(snum));
            pnum      = str2pnum(pwd);
            fsImage   = 'brain_finalsurfs';
            revFrames = [1 5];
            
            sumGluc   = sprintf(      '%sgluc%i_mcf_revf%ito%i_sumt', pnum, snum, revFrames(1), revFrames(2));            
            fsReg  = sprintf('%s_on_%sgluc%i', fsImage, pnum, snum);

            assert(lexist(sprintf('%s.nii.gz', sumGluc), 'file'));
            assert(lexist(sprintf('%s.nii.gz', fsImage), 'file'));

            system(sprintf('flirt -in %s -ref %s.nii.gz -out %s.nii.gz -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                            fsImage, sumGluc, fsReg, fsReg));
            system(sprintf('freeview %s.nii.gz %s.nii.gz', fsReg, sumGluc));
        end
        function flirtFreesurferImage2(snum)
            %% FLIRTAPARC flirts aparc_a2009s+aseg_mask, then reviews registrations with fslview
            %  Usage:  glutWorker3() 

            assert(isnumeric(snum));
            pnum      = str2pnum(pwd);
            revFrames = [1 5];
            fsImage   = 'orig'; 
            t1        = '001';
            gluc      = sprintf('%sgluc%i', pnum, snum);            
            fsReg_    = sprintf('%s_on_%s', fsImage, t1);
            glucSumt  = sprintf(      '%s_mcf_revf%ito%i_sumt', gluc, revFrames(1), revFrames(2));  
            t1Reg_    = sprintf('%s_on_%s', t1, glucSumt);          
            fsReg     = sprintf('%s_on_%s', fsImage, gluc);
            aparcMsk  = 'aparc_a2009s+aseg_mask';
            aparcReg  = sprintf('%s_on_%s_mcf', aparcMsk, gluc);

            assert(lexist(sprintf('%s.nii.gz', fsImage), 'file'));
            assert(lexist(sprintf('%s.nii.gz', t1),      'file'));
            assert(lexist(sprintf('%s.nii.gz', glucSumt), 'file'));
            
            system(sprintf('flirt -in %s -ref %s.nii.gz -out %s.nii.gz -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                            fsImage, t1, fsReg_, fsReg_));
            system(sprintf('flirt -in %s -ref %s.nii.gz -out %s.nii.gz -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                            t1, glucSumt, t1Reg_, t1Reg_));
            system(sprintf('convert_xfm -omat %s.mat -concat %s.mat %s.mat', fsReg, t1Reg_, fsReg_));            
            system(sprintf('flirt -in %s -applyxfm -init %s.mat -out %s -paddingsize 0.0 -interp nearestneighbour -ref %s',  ...
                            aparcMsk, fsReg, aparcReg, glucSumt));
                        
            system(sprintf('freeview %s.nii.gz %s.nii.gz', aparcReg, glucSumt));
        end
        function flirtFreesurferImage3(snum)
            %% FLIRTAPARC flirts aparc_a2009s+aseg_mask, then reviews registrations with fslview
            %  Usage:  glutWorker3() 

            assert(isnumeric(snum));
            pnum      = str2pnum(pwd);
            revFrames = [1 5];
            blur      = [10 10 10];
            fsImage   = 'orig'; 
            t1        = '001';
            gluc      = sprintf('%sgluc%i', pnum, snum);            
            fsReg_    = sprintf('%s_on_%s', fsImage, t1);
            glucSumt  = sprintf('%s_mcf_revf%ito%i_sumt', gluc, revFrames(1), revFrames(2));  
            t1Reg_    = sprintf('%s_on_%s', t1, glucSumt);          
            fsReg     = sprintf('%s_on_%s', fsImage, gluc);
            aparcMsk  = 'aparc_a2009s+aseg_mask';
            aparcReg  = sprintf('%s_on_%s_mcf', aparcMsk, gluc);

            assert(lexist(sprintf('%s.nii.gz', fsImage), 'file'));
            assert(lexist(sprintf('%s.nii.gz', t1),      'file'));
            assert(lexist(sprintf('%s.nii.gz', glucSumt), 'file'));
            
            dnii = mlfourd.DynamicNIfTId.load([glucSumt '.nii.gz']);
            dnii = dnii.blurred(blur);
            dnii.save;
            glucSumtB = dnii.fileprefix;
            
            %system(sprintf('flirt -in %s -ref %s.nii.gz -out %s.nii.gz -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', ...
            %                fsImage, t1, fsReg_, fsReg_));
            system(sprintf('flirt -in %s -ref %s.nii.gz -out %s.nii.gz -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', ...
                            t1, glucSumtB, t1Reg_, t1Reg_));
            system(sprintf('convert_xfm -omat %s.mat -concat %s.mat %s.mat', fsReg, t1Reg_, fsReg_));            
            system(sprintf('flirt -in %s -applyxfm -init %s.mat -out %s -paddingsize 0.0 -interp nearestneighbour -ref %s',  ...
                            aparcMsk, fsReg, aparcReg, glucSumtB));
                        
            system(sprintf('freeview %s.nii.gz %s.nii.gz', aparcReg, glucSumtB));
        end
        function renameFiles(snum)
            
            assert(isnumeric(snum));
            pnum     = str2pnum(pwd);
            gluc     = sprintf('%sgluc%i_mcf', pnum, snum);            
            brain    = sprintf('brain_finalsurfs_on_%str%i', pnum, snum); 
            brainReg = sprintf('brain_finalsurfs_on_%sgluc%i_mcf', pnum, snum);
            middleReg = sprintf('%str%i_on_%sgluc%i_mcf', pnum, snum, pnum, snum);
            
            assert(lexist(sprintf('%s.nii.gz', brain),   'file'));
            
            %system(sprintf('mv %s_on_%s.nii.gz %s.nii.gz', brain, gluc, brainReg));
            system(sprintf('mv %s.mat %s.mat', brainReg, middleReg));
        end
        function concatFiles(snum)
            
            assert(isnumeric(snum));
            pnum     = str2pnum(pwd);
            reg1 = sprintf('nu_noneck_on_%str%i', pnum, snum);
            reg2 = sprintf('%str%i_on_%sgluc%i_mcf', pnum, snum, pnum, snum);
            reg  = sprintf('nu_noneck_on_%sgluc%i_mcf', pnum, snum);
            
            assert(lexist(sprintf('%s.mat', reg1), 'file'));
            assert(lexist(sprintf('%s.mat', reg2), 'file'));
            
            system(sprintf('convert_xfm -omat %s.mat -concat %s.mat %s.mat', reg, reg2, reg1));
        end
        function flirtAparc(snum)
            %% FLIRTAPARC flirts aparc_a2009s+aseg_mask, then reviews registrations with fslview
            %  Usage:  glutWorker3() 
            
            fsImage        = 'brain_finalsurfs';
            revertedFrames = [1 5];

            assert(isnumeric(snum));
            pnum     = str2pnum(pwd);
            aparcMsk = 'aparc_a2009s+aseg_mask';
            reg      = sprintf('%s_on_%sgluc%i', fsImage, pnum, snum);
            aparcReg = sprintf('%s_on_%sgluc%i_mcf', aparcMsk, pnum, snum);
            sumGluc  = sprintf('%sgluc%i_mcf_revf%ito%i_sumt', pnum, snum, revertedFrames(1), revertedFrames(2));

            assert(lexist(sprintf('%s.nii.gz', aparcMsk), 'file'));
            assert(lexist(sprintf('%s.nii.gz', sumGluc),  'file'));

            system(sprintf('flirt -in %s -applyxfm -init %s.mat -out %s -paddingsize 0.0 -interp nearestneighbour -ref %s',  ...
                            aparcMsk, reg, aparcReg, sumGluc));
            system(sprintf('fslview "%s" %s', sumGluc, aparcReg));
        end
        function copyImgRec(snum)
            pnum = str2pnum(pwd);
            rec0 = sprintf('%sgluc%i.img.rec', pnum, snum);
            rec  = sprintf('%sgluc%i_mcf_revf1to5.img.rec', pnum, snum);
            system(sprintf('cp %s %s', rec0, rec));
        end
        function writeTsc(snum)
            [~,folder] = fileparts(pwd);
            if (strncmp(folder, 'scan', 4))
                cd('..'); end
            [~,folder] = fileparts(pwd);
            if (strcmp(folder, 'PET'))
                cd('..'); end
                
            tsc = mlarbelaez.GlutWorker.loadTsc(pwd, snum);
            tsc.save;
            figure;
            plot(tsc.times, tsc.counts ./ tsc.taus);
            title(tsc.fqfilename);
        end
        function this = loadTsc(pnumPth, scanIdx)
            %% LOADTSC
 			%  Usage:  this = TSC.loadTsc(pnumber_path, scan_index) 
            %          this = TSC.loadTsc('/path/to/p1234data', 1)
            
            assert(lexist(pnumPth, 'dir'));
            pnum = str2pnum(pnumPth);
            if (isnumeric(scanIdx)); scanIdx = num2str(scanIdx); end
            
            ecatLoc = fullfile(pnumPth, 'PET', ['scan' scanIdx], [pnum 'gluc' scanIdx '_mcf_revf1to5.nii.gz']);
            tscLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'wb' scanIdx '.tsc']);
            dtaLoc  = fullfile(pnumPth, 'jjl_proc', [pnum 'g'  scanIdx '.dta']);
            maskLoc = sprintf('aparc_a2009s+aseg_mask_on_%sgluc%i_mcf.nii.gz', pnum, scanIdx);
            this = mlpet.TSC.load(tscLoc, ecatLoc, dtaLoc, maskLoc);            
        end
        function [dt,ks,kmps] = loopKinetics4(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:}); 
            
            import mlarbelaez.*;
            pwd0 = pwd;            
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            
            cd(subjectsPth);
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2);
            kmps = cell(length(dt.dns),2);
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('Kinetics4McmcProblems.loopKinetics4_%s.log', datestr(now, 30)));
            diary(logFn);
            for d = 1:length(dt.dns)
                for s = 1:2
                    try
                        pth = fullfile(subjectsPth, dt.dns{d}, '');
                        cd(pth);
                        fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                        fprintf('GlutWorker.loopKinetics4:  working in %s\n', pth);
                        [ks{d,s},kmps{d,s}] = Kinetics4McmcProblem.run(pth, s);
                    catch ME
                        handwarning(ME)
                    end
                end                
            end
            cd(subjectsPth);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            cd(p.Results.figFolder);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            mlpet.AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end
        function [dt,ks,kmps] = loopKinetics4_scan1(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:}); 
            
            import mlarbelaez.*;
            pwd0 = pwd;            
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            
            cd(subjectsPth);
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2);
            kmps = cell(length(dt.dns),2);
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('Kinetics4McmcProblems.loopKinetics4_%s.log', datestr(now, 30)));
            diary(logFn);
            for d = 1:length(dt.dns)
                for s = 1:1
                    try
                        pth = fullfile(subjectsPth, dt.dns{d}, '');
                        cd(pth);
                        fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                        fprintf('GlutWorker.loopKinetics4:  working in %s\n', pth);
                        [ks{d,s},kmps{d,s}] = Kinetics4McmcProblem.run(pth, s);
                    catch ME
                        handwarning(ME)
                    end
                end                
            end
            cd(subjectsPth);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            cd(p.Results.figFolder);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            mlpet.AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end
        function [dt,ks,kmps] = loopKinetics4_scan2(varargin)
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:}); 
            
            import mlarbelaez.*;
            pwd0 = pwd;            
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            
            cd(subjectsPth);
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2);
            kmps = cell(length(dt.dns),2);
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('Kinetics4McmcProblems.loopKinetics4_%s.log', datestr(now, 30)));
            diary(logFn);
            for d = 1:length(dt.dns)
                for s = 2:2
                    try
                        pth = fullfile(subjectsPth, dt.dns{d}, '');
                        cd(pth);
                        fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                        fprintf('GlutWorker.loopKinetics4:  working in %s\n', pth);
                        [ks{d,s},kmps{d,s}] = Kinetics4McmcProblem.run(pth, s);
                    catch ME
                        handwarning(ME)
                    end
                end                
            end
            cd(subjectsPth);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            cd(p.Results.figFolder);
            save(sprintf('Kinetics4McmcProblems.loopKinetics4_%s.mat', datestr(now,30)));
            mlpet.AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end
        function [dt, ks,kmps] = regionalKinetics4(varargin)          
            
            regions = {'amygdala' 'hippocampus' 'hypothalamus' 'large-hypothalamus' 'thalamus'};
            
            p = inputParser;
            addOptional(p, 'figFolder', pwd, @(x) lexist(x, 'dir'));
            parse(p, varargin{:}); 
            
            import mlarbelaez.*;
            pwd0 = pwd;            
            subjectsPth = '/Volumes/InnominateHD2/Arbelaez/GluT';
            
            cd(subjectsPth);
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2,length(regions));
            kmps = cell(length(dt.dns),2,length(regions));
            
            cd(subjectsPth);
            logFn = fullfile(subjectsPth, sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.log', datestr(now, 30)));
            diary(logFn);
            for d = 11:11 % 1:length(dt.dns)
                for s = 1:2
                    for r = 1:length(regions)
                        try
                            pth = fullfile(subjectsPth, dt.dns{d}, '');
                            cd(pth);
                            fprintf('-------------------------------------------------------------------------------------------------------------------------------\n');
                            fprintf('GlutWorker.regionalKinetics4:  working in %s, region %s\n', pth, regions{r});
                            [ks{d,s,r},kmps{d,s,r}] = Kinetics4McmcProblem.runRegion( ...
                                                      pth, s, sprintf('%s_on_gluc%i', regions{r}, s));
                        catch ME
                            handwarning(ME)
                        end
                    end
                end                
            end
            cd(subjectsPth);
            save(sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.mat', datestr(now,30)));
            cd(p.Results.figFolder);
            save(sprintf('Kinetics4McmcProblems.regionalKinetics4_%s.mat', datestr(now,30)));
            mlpet.AutoradiographyTester.saveFigs;
            cd(pwd0);
            diary off
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

