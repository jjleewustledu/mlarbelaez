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
        function flirtBrainFinalsurfs(snum)
            %% FLIRTAPARC flirts aparc_a2009s+aseg_mask, then reviews registrations with fslview
            %  Usage:  glutWorker3() 

            assert(isnumeric(snum));
            pnum     = str2pnum(pwd);
            sumGluc  = sprintf('(sum)%sgluc%i_mcf', pnum, snum);
            brain    = sprintf('brain_finalsurfs_on_%str%i', pnum, snum);
            brainReg = sprintf('brain_finalsurfs_on_%sgluc%i_mcf', pnum, snum);

            assert(lexist(sprintf('%s.nii.gz', sumGluc), 'file'));
            assert(lexist(sprintf('%s.nii.gz', brain),   'file'));

            system(sprintf('flirt -in %s -ref "%s" -out %s -omat %s.mat -bins 256 -cost normmi -dof 6 -interp trilinear', brain, sumGluc, brainReg, brainReg));
            %system(sprintf('fslview %s_on_%s "%s"', brain, gluc, sumGluc));
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

            assert(isnumeric(snum));
            pnum     = str2pnum(pwd);
            sumGluc  = sprintf('(sum)%sgluc%i_mcf', pnum, snum);
            reg      = sprintf('nu_noneck_on_%sgluc%i_mcf', pnum, snum);
            tr       = sprintf('%str%i', pnum, snum);
            aparcMsk = 'aparc_a2009s+aseg_mask';
            aparcReg = sprintf('%s_on_%sgluc%i_mcf', aparcMsk, pnum, snum);

            assert(lexist(sprintf('%s.nii.gz', sumGluc),  'file'));
            assert(lexist(sprintf('%s.nii.gz', aparcMsk), 'file'));

            system(sprintf('flirt -in %s -applyxfm -init %s.mat -out %s -paddingsize 0.0 -interp nearestneighbour -ref %s', aparcMsk, reg, aparcReg, tr));
            system(sprintf('fslview "%s" %s', sumGluc, aparcReg));
        end
        function copyFiles(snum)
            pnum = str2pnum(pwd);
            rec0 = fullfile(pwd, 'PET', sprintf('scan%i', snum), sprintf('%sgluc%i.img.rec', pnum, snum));
            rec  = fullfile(pwd, 'PET', sprintf('scan%i', snum), sprintf('%sgluc%i_mcf.img.rec', pnum, snum));
            system(sprintf('cp %s %s', rec0, rec));
        end
        function writeTsc(snum)
            tsc = mlpet.TSC.loadGluT(pwd, snum);
            tsc.save;
            figure;
            plot(tsc.times, tsc.counts ./ tsc.taus);
            title(tsc.fqfilename);
        end
        function [dt,ks,kmps] = loopKinetics4            
            pwd0 = pwd;
            [~,folder] = fileparts(pwd0);
            assert(strcmp('GluT', folder));
            dt = mlsystem.DirTool('p*_JJL');
            assert(~isempty(dt.dns));
            ks   = cell(length(dt.dns),2);
            kmps = cell(length(dt.dns),2);
            
            for d = 1:length(dt.dns)
                pth = fullfile(pwd0, dt.dns{d}, '');
                fprintf('GlutWorker.loopKinetics4:  working in %s\n', pth);
                for s = 1:2
                    try
                        [ks{d,s},kmps{d,s}] = mlarbelaez.Kinetics4McmcProblem.run(pth, s);
                    catch ME
                        handwarning(ME)
                    end
                end                
            end
            cd(pwd0);
        end
        function [ks,kmps] = singleKinetics4(dirname)          
            pwd0 = pwd;
            [~,folder] = fileparts(pwd0);
            assert(strcmp('GluT', folder));
            ks   = cell(1,2);
            kmps = cell(1,2);

            pth = fullfile(pwd0, dirname, '');
            fprintf('GlutWorker.loopKinetics4:  working in %s\n', pth);
            for s = 1:2
                try
                    [ks{1,s},kmps{1,s}] = mlarbelaez.Kinetics4McmcProblem.run(pth, s);
                catch ME
                    handwarning(ME)
                end
            end
            cd(pwd0);
        end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

