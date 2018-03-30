classdef Glucnoflow
    %% GLUCNOFLOW
    
    %  $Revision$
    %  was created $Date$
    %  by $Author$,
    %  last modified $LastChangedDate$
    %  and checked into repository $URL$,
    %  developed on Matlab 8.4.0.150421 (R2014b)
    %  $Id$
    
    
    properties
        localBasePath = '/Volumes/InnominateHD3/Arbelaez/GluT'
        nilBasePath = '/data/nil-bluearc/hershey/unix/AMA/GluT'
        csvFile = '/Volumes/InnominateHD3/Arbelaez/GluT/Glucnoflow.csv'
        pnumPath
        petIndex          % integer  
        isotope = '11C'
        useBecquerels = false % boolean for dividing by sampling durations of each time-frame to obtain 1/sec    
        
        pie = 4.88;
        kinit = [0.6 0.6 0.02 3]; % initial guesses for [k21 k12 k32 k43]
        
        mask
        petGluc_decayCorrect
        injectionTIme
        times
        taus
        dtaDuration
        gluTxlsx
    end
    
    properties (Dependent)
        fslPath
        petPath
        scanPath
        procPath 
        pnumber
        
        maskFqFilename
        glucFqFilename
        recFqFilename
    end
    
    methods %% GET
        function pth = get.fslPath(this)
            pth = fullfile(this.pnumPath, 'fsl', '');
        end
        function pth = get.petPath(this)
            pth = fullfile(this.pnumPath, 'PET', '');
        end
        function pth = get.scanPath(this)
            pth = fullfile(this.petPath, ['scan' num2str(this.petIndex)], '');
        end
        function pth = get.procPath(this)
            if (1 == this.petIndex)
                pth = fullfile(this.pnumPath, 'wjp_proc_v2', '');
            else                
                pth = fullfile(this.pnumPath, 'wjp_proc2_v2', '');
            end
        end
        function p   = get.pnumber(this)
            p = str2pnum(this.pnumPath);
        end
        function f   = get.maskFqFilename(this)
            f = sprintf('brain_finalsurfs_on_%str1.nii.gz', this.pnumber);
            f = fullfile(this.fslPath, f);
        end
        function f   = get.glucFqFilename(this)
            f = sprintf('%sgluc%i.nii.gz', this.pnumber, this.petIndex);
            f = fullfile(this.scanPath, f);
        end
        function f   = get.recFqFilename(this)
            f = sprintf('%sgluc%i.img.rec', this.pnumber, this.petIndex);
            f = fullfile(this.scanPath, f);
        end        
    end
    
    methods (Static)
        function fslviewLooper
            dt = mlsystem.DirTool('p*_JJL');
            assert(dt.length > 0, 'Glucnoflow.looper found no folders "p*_JJL"');
            dns = dt.dns;
            for d = 2:dt.length
                for idx = 1:2
                    fqfp_sumall = fullfile(dns{d}, 'PET', ['scan' num2str(idx)], sprintf('%sgluc%i_sumall', str2pnum(dns{d}), idx));
                    fqfp_brain  = fullfile(dns{d}, 'fsl',                        sprintf('brain_finalsurfs_on_%str%i', str2pnum(dns{d}), idx));
                    fprintf('process %i is working with %s\n', d, fqfp_sumall);
                    try
                        system(sprintf('fslview %s %s', fqfp_sumall, fqfp_brain));
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function petScanLooper(hand)
            dt = mlsystem.DirTool('p*_JJL');
            assert(dt.length > 0, 'Glucnoflow.looper found no folders "p*_JJL"');
            dns = dt.dns;
            for d = 1:dt.length
                for idx = 1:2
                    fprintf('process %i is working with %s and pet index %i\n', d, dns{d}, idx);
                    try
                        hand(dns{d}, idx);
                    catch ME
                        handwarning(ME);
                    end
                end
            end
        end
        function createSumall(fqfp)
            try
                gluc = mlfourd.NIfTI.load(fqfp);
                sz = gluc.size;
                img = zeros(sz(1:3));
                for t = 1:gluc.size(4)
                    img = img + gluc.img(:,:,:,t);
                end
                gluc.img = img;
                gluc.saveas([fqfp '_sumall']);
            catch ME
                handexcept(ME);
            end
        end
        function this = createProcfiles(pth, idx)
            %% CREATEPROCFILES
            %  Usage:  this = Glucnoflow.createProcfiles(pnumber_path, pet_index)
            
            try
                this = mlarbelaez.Glucnoflow(pth, idx);
                this.injectionTIme = this.getInjectionTime;
                this.mask = this.makeMask( ...
                    NIfTI.load(this.maskFqFilename));
                [this.petGluc_decayCorrect,this.times,this.taus] = ...
                    this.decayCorrect( ...
                        this.maskPet( ...
                            NIfTI.load(this.glucFqFilename), this.mask));
                this.dtaDuration = this.getDtaDuration;  
                fqfn = fullfile(this.procPath, sprintf('%swb%i.tsc', this.pnumber, this.petIndex));
                label = [this.petGluc_decayCorrect.fqfilename];
                counts = plotPet(this, this.petGluc_decayCorrect, this.mask); 
                this.printTsc(fqfn, label, counts, this.mask);
                this.printIn;
                this.printPbl;
                this.printRun;
                this.printJob;
            catch ME
                handexcept(ME);
            end
        end
        function this = createCsv(pth, idx)
            try
                this = mlarbelaez.Glucnoflow(pth, idx);
                if (~lexist(this.csvFile))
                    this.printCsvHeader; end
                this.printCsv;
            catch ME
                handexcept(ME);
            end
        end
    end
    
    methods
        function this = Glucnoflow(ppath, petidx)
            %% GLUCNOFLOW
            %  Usage:  this = Glucnoflow(pnumber_path, pet_index)   
            
            assert(lexist(ppath, 'dir'));
            assert(strcmp('p', ppath(end-8)) && strcmp('_JJL', ppath(end-3:end)), ...
                'mlarbelaez:unexpectedString', 'Glucnoflow.ctor.ppath -> %s', ppath);
            this.pnumPath = ppath;    
            
            assert(isnumeric(petidx));
            this.petIndex = petidx;
            
            import mlfourd.*;          
            this.gluTxlsx = mlarbelaez.GluTxlsx;
        end
           
        function nii = sumPet(~, nii, range)
            %% SUMPET sums time-frames of PET embedded in NIfTI
            %   
            %  Usage:  nifti_summed = sumPet(nifti, [first_frame last_frame]) 
            %                                       ^ 1x2 double 

            assert(isa(nii, 'mlfourd.NIfTI'));
            assert(isnumeric(range));
            assert(all([1 2] == size(range)));

            img = zeros(nii.size);
            img = img(:,:,:,1);
            for f = range(1):range(2)
                img = img + nii.img(:,:,:,f);
            end
            nii.img = img;
            nii.fileprefix = sprintf('%s_f%ito%i', nii.fileprefix, range(1), range(2));
        end
        function msk = makeMask(~, nii)
            
            assert(isa(nii, 'mlfourd.NIfTI'));
            assert(3 == length(nii.size), 'mlarbelaez:dataFormatNotSupported', 'Glucnoflow.makeMask.nii.size -> % i', nii.size); %#ok<*MCNPN>
            
            msk = mlfourd.NIfTI(nii);
            msk.fileprefix = [nii.fileprefix '_mask'];
            msk.img = abs(msk.img) > eps;
        end
        function pet = maskPet(~, pet, msk)
            %% MASKPET accepts PET and mask NIfTIs and masks each time-frame of PET by the mask
            %  Usage:  pet_masked_nifti = maskPet(pet_nifti, mask_nifti) 

            assert(isa(pet, 'mlfourd.NIfTI'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(3 == length(msk.size));

            for t = 1:pet.size(4)
                pet.img(:,:,:,t) = pet.img(:,:,:,t) .* msk.img;
            end
            pet.fileprefix = [pet.fileprefix '_masked'];
        end
        function [nii,times,taus] = decayCorrect(this, nii)
            %% DECAYCORRECT ... 
            %  Usage:  [nifti,times,durations] = decayCorrect(nifti);
            %                 ^     ^ double
            %  Uses:  this.isotope, this.injectionTIme 
            %         ^ char:  "15O", "11C"
            %                       ^ float, sec

            sz = nii.size;
            NN = 70; % time-resolution used internally for calculations; truncated to nii.size(4)
            switch (this.isotope)
                case '15O'        
                    halfLife           = 122.1;
                    lambda             = log(2) / halfLife; % lambda \equiv 1/tau, tau = 1st-order rate constant 
                    times              = zeros(1,NN);
                    taus               = zeros(1,NN);
                    img                = zeros(sz(1),sz(2),sz(3),NN);
                    img(:,:,:,1:sz(4)) = nii.img;
                    nii.pixdim(4)      = 2;

                    times( 1:31) = this.injectionTIme +      2*([2:32] - 2);
                    times(32:NN) = this.injectionTIme + 60 + 6*([33:NN+1] - 32);

                    taus( 1:30) = 2;
                    taus(31:NN) = 6;

                    if (this.useBecquerels)
                        scaling = [2 6]; %#ok<*UNRCH> % duration of sampling
                    else
                        scaling = [1 1];
                    end

                    for t = 1:30
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(1); end
                    for t = 31:NN
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(2); end

                case '11C'
                    halfLife           = 20.334*60;
                    lambda             = log(2) / halfLife;
                    times              = zeros(1,NN);
                    taus               = zeros(1,NN);
                    img                = zeros(sz(1),sz(2),sz(3),NN);
                    img(:,:,:,1:sz(4)) = nii.img;
                    nii.pixdim(4)      = 30;

                    times( 1:17) = this.injectionTIme +         30*([ 2:18] -  2); %#ok<*NBRAK>
                    times(18:25) = this.injectionTIme + 480  +  60*([19:26] - 18);
                    times(26:41) = this.injectionTIme + 960  + 120*([27:42] - 26);
                    times(42:49) = this.injectionTIme + 2880 + 180*([43:50] - 42);
                    times(50:NN) = this.injectionTIme + 4320 + 240*([51:NN+1] - 50);

                    taus( 1:16) = 30;
                    taus(17:24) = 60;
                    taus(25:40) = 120;
                    taus(41:48) = 180;
                    taus(49:NN) = 240;        

                    if (this.useBecquerels)
                        scaling = [30 60 120 180 240]; % duration of sampling
                    else
                        scaling = [1 1 1 1 1];
                    end

                    for t = 1:16
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(1); end
                    for t = 17:24
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(2); end
                    for t = 25:40
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(3); end
                    for t = 41:48
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(4); end
                    for t = 49:NN
                        img(:,:,:,t) = img(:,:,:,t) * exp(lambda * times(t)) / scaling(5); end

                otherwise
                    error('mfiles:unsupportedPropertyValue', 'decayCorrect did not recognize %s', this.isotope);
            end

            nii.img = img(:,:,:,1:sz(4));
            times   = times(1:sz(4));
            taus    = taus( 1:sz(4));
            nii.fileprefix = [nii.fileprefix '_decayCorrect'];
            if (this.useBecquerels)
                nii.fileprefix = [nii.fileprefix '_Bq']; end
        end
        function counts = plotPet(this, nii, msk)
            %% PLOTPET plots the time-evolution of the PET data summed over all positions from the tomogram
            %  Usage:  counts = plotPet(PET_NIfTI, mask_NIfTI) 
            %          ^ double vector                       

            assert(isa(nii,    'mlfourd.NIfTI'));
            assert(isa(msk, 'mlfourd.NIfTI'));
            assert(4 == length(nii.size), 'plotPet:  PET NIfTI has no temporal data');
            nii_size = nii.size;
            assert(all(nii_size(1:3) == msk.size));

            counts = zeros(1,nii.size(4));
            for t = 1:nii.size(4)
                counts(t) = sum(sum(sum(nii.img(:,:,:,t) .* msk.img, 1), 2), 3);
            end
            figure;
            plot(counts);
            title([nii.fileprefix ' && ' msk.fileprefix], 'Interpreter', 'none');
            xlabel('time-frame/arbitrary');
            if (~this.useBecquerels); ylabel('counts/time-frame');
            else                  ylabel('activity/Bq'); end
        end
        function counts = printTsc(this, fqfn, label, counts, mask)
            %% PRINTTSC ...
            %  Usage:  printTsc(label, counts, mask)
            %                   ^ string
            %                          ^ double, PETcnts
            %                                  ^ boolean NIfTI
            
            fid = fopen(fqfn, 'w');
            
            Nf = this.getNf;
            PIE = 4.88; % 3D [11C] scans from 2012
            if (getenv('VERBOSE'))
                fprintf('printTsc:  using pie->%f\n', PIE); end
            Npixels = mask.dipsum;
            
            % \pi \equiv \frac{wellcnts/cc/sec}{PETcnts/pixel/min}
            % wellcnts/cc = \pi \frac{PETcnts}{pixel} \frac{sec}{min}
            
            counts = PIE * (counts/Npixels) * 60;
            fprintf(fid, '%s\n', label);
            fprintf(fid, '    %i,    %i\n', Nf, 3);
            for f = 1:Nf
                fprintf(fid, '%12.1f %12.1f %14.2f\n', this.times(f), this.taus(f), counts(f));
            end
            fprintf(fid, 'bool(brain.finalsurfs)\n\n');
            
            fclose(fid);
        end    
        function printIn(this)
            
            fqdn = fullfile(this.nilBasePath, this.procPath, '');
            fqfn = fullfile(this.localBasePath, this.procPath, sprintf('%swb%s.in', this.pnumber, num2str(this.petIndex)));
            
            fid = fopen(fqfn, 'w');
            fprintf(fid, '%swb%i.tsc\n',  fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%sg%i.dta\n',   fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%swb%i.pbl\n',  fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%swb%ia.log\n', fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%swb%ib.log\n', fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%swb%ic.log\n', fullfile(fqdn, this.pnumber), this.petIndex);
            fprintf(fid, '%swb%id.log\n', fullfile(fqdn, this.pnumber), this.petIndex);
            fclose(fid);
        end
        function printPbl(this)
            
            import mlarbelaez.*;
            gx_pid_scan = this.gluTxlsx.pid_map(this.pnumber).(['scan' num2str(this.petIndex)]);
            glu = GluTxlsx.glu_mmol(gx_pid_scan.glu, gx_pid_scan.hct);
            timeDelay = 3;
            cbv = gx_pid_scan.cbv;
            assert(~isnan(cbv), 'Glucnoflow.printPbl failed for %s pet-index %i', this.pnumPath, this.petIndex);
            cbf = GluTxlsx.cbf_fromcbv(gx_pid_scan.cbv);
            
            fqfn = fullfile(this.localBasePath, this.procPath, sprintf('%swb%s.pbl', this.pnumber, num2str(this.petIndex)));            
            fid = fopen(fqfn, 'w');
            fprintf(fid, '0 %4.2f %4.2f 0 %i %4.2f %4.2f %4.2f %4.2f 0 0.0 0.0 0.0 0.0\n', ...
                this.pie, glu, timeDelay, this.kinit(1), this.kinit(2), this.kinit(3), this.kinit(4));
            fprintf(fid, '0 0 0 0 0 0\n');
            fprintf(fid, '5\n');
            fprintf(fid, '5 6 7 8 9\n');
            fprintf(fid, '2\n');
            fprintf(fid, '1 2\n');
            fprintf(fid, '%5.2f %5.2f\n', cbf, cbv);
            fclose(fid);
        end
        function printJob(this)
            fqfn = fullfile(this.localBasePath, this.procPath, sprintf('%swb%s.job', this.pnumber, num2str(this.petIndex))); 
            fid = fopen(fqfn, 'w');
            fprintf(fid, './glucsun.run < %swb%i.in >& %swb%i.out\n', this.pnumber, this.petIndex, this.pnumber, this.petIndex);
            fclose(fid);
        end
        function printRun(this)
            fqfn = fullfile(this.localBasePath, this.procPath, 'glucsun.run'); 
            fid = fopen(fqfn, 'w');
            fprintf(fid, '#!/bin/sh\n');
            fprintf(fid, 'rsh petsun24.neuroimage.wustl.edu /home/usr/joanne/sun24/bin/glucnoflow.tsk\n');
            fclose(fid);
        end
        function flirtMasks(this, pth, idx)
            %% FLIRTMASKS ... 
            %  Usage:  flirtMasks(path_to_images, scan_index) 
            %                     ^ to pXXXX_JJL or pXXXX_JJL/fsl 
            %                                     ^ 1, 2, per PET scanning conventions

            try
                if (~lstrfind(pth, 'fsl'))
                    pth = fullfile(pth, 'fsl', ''); end
                cd(pth); 
                assert(~isempty(this.pnumber)); assert(isnumeric(idx));
                idx = num2str(idx);

                in_xas   = 'nu_noneck';
                ref      = [this.pnumber 'tr' idx];
                out_xas  = 'nu_noneck_on_xaxissearch';
                omat_xas = 'nu_noneck_on_xaxissearch.mat';
                this.flirt_xaxissearch(in_xas, ref, out_xas, omat_xas)

                in_fs   = 'nu_noneck_on_xaxissearch';
                ref     = [this.pnumber 'tr' idx];
                out_fs  = ['nu_noneck_on_' ref];
                omat_fs = ['xaxissearch_on_' ref '.mat'];
                this.flirt_rngsearch(in_fs, ref, out_fs, omat_fs, 20)

                omat = ['nu_noneck_on_' ref '.mat'];
                this.concat(omat, omat_fs, omat_xas);

                in   = 'brain.finalsurfs';
                out  = ['brain_finalsurfs_on_' ref];
                this.applyxfm(in, ref, out, omat);

            catch ME
                handwarning(ME, 'pth->%s, idx->%s', pth, idx);
            end
        end  
        function [results,rrow] = readDLog(this)
            try
                fid = fopen( ...
                    fullfile(this.procPath, sprintf('%swb%id_db.log', this.pnumber, this.petIndex)));
            catch      %#ok<CTCH>
                try
                    fid = fopen( ...
                        fullfile(this.procPath, sprintf('%swb60d_db.log', this.pnumber)));
                catch ME
                    handexcept(ME);
                end
            end
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%s',    1, 'Delimiter', '\n');
            textscan(fid, '%d %d', 1, 'Delimiter', '\n');
            ts = cell2mat(textscan(fid, '%f %f %f %f %f %f %f',    'Delimiter', ' ', 'MultipleDelimsAsOne', true));
            
            results.cbf     = ts(1,1);
            results.cbv     = ts(1,2);
            results.glu_art = ts(1,3);
            results.k04     = ts(1,4);
            results.k21     = ts(1,5);
            results.k12     = ts(1,6);
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
        function [results,rrow] = readALogTail(this)
            tp = mlio.TextParser.load( ...
                 fullfile(this.procPath, sprintf('%swb%ia_db.log', this.pnumber, this.petIndex)));
            tmp = tp.parseRightAssociatedNumeric2('WEIGHTED SUM-OF-SQUARES & RMSE');
            results.weighted_sum_of_squares = tmp(1);
            results.rmse = tmp(2);
            rrow = [tmp(1) tmp(2)];
        end
        function printCsvHeader(this)      
            fid = fopen(this.csvFile, 'w');
            results = ...
                'p#,scan#,glu (mg/dL),Hct,cbf,cbv,glu art,k04,k21,k12,k32,k43,t0,t12,util. frac.,glu met,chi,kd,forward flux,brain glu,cond. #,det(FI),wt sum squares,rmse\n';
            fprintf(fid, results);
            fclose(fid);
        end
        function printCsv(this)            
            fid = fopen(this.csvFile, 'a');            
            gx = this.gluTxlsx.pid_map(this.pnumber).(['scan' num2str(this.petIndex)]);          
            [~,rALogH] = this.readDLog;
            [~,rOut]   = this.readOut;
            [~,rALogT] = this.readALogTail;
            results = this.cell2csv([{this.pnumber this.petIndex gx.glu gx.hct} num2cell(rALogH) num2cell(rOut) num2cell(rALogT)]);
            fprintf(fid, results);
            fprintf(fid, '\n');
            fclose(fid);
        end
    end
    
    %% PRIVATE
    
    properties (Access = 'private', Constant)   
        FLIRTBIN = '/usr/local/fsl/bin/flirt'
        CONVERTBIN = '/usr/local/fsl/bin/convert_xfm'
    end
    
    properties (Access = 'private')
        xlsraw_
    end
    
    methods (Access = 'private')   
        function stime = getInjectionTime(this)
            try
                tp = mlio.TextParser.load(this.recFqFilename);
                stime = tp.parseAssignedNumeric('Start time');
            catch ME
                fprintf('Glucnoflow.getInjectionTime failed for %s pet-index %i', this.petPath, this.petIndex);
                handexcept(ME);
            end
        end
        function t = getDtaDuration(this)
            dta = mlpet.DTA( ...
                      sprintf('%s/%sg%i', this.procPath, this.pnumber, this.petIndex));
            t = dta.times(dta.length);
        end
        function nf = getNf(this)
            nf = min([length(this.times) length(this.taus)]);
            for f = 1:nf
                if (this.times(f) + this.taus(f) > this.dtaDuration)
                    nf = f - 1;
                    break; 
                end
            end
        end
        function flirt_xaxissearch(this, in, ref, out, omat)

            in_ng  = [in  '.nii.gz'];
            ref_ng = [ref '.nii.gz'];
            out_ng = [out '.nii.gz'];
            cmd    = sprintf( ...
                '%s -in %s -ref %s -out %s -omat %s -bins 256 -cost corratio -searchrx -90 90 -searchry -0 0 -searchrz -0 0 -dof 6  -refweight %s -interp trilinear', ...
                this.FLIRTBIN, in_ng, ref_ng, out_ng, omat, ref_ng);
            fprintf([cmd '\n']);
            system(cmd);
        end
        function flirt_rngsearch(this, in, ref, out, omat, rng)

            assert(isnumeric(rng) && rng > 0 && rng <= 90);
            nrng = -1*rng;

            in_ng  = [in  '.nii.gz'];
            ref_ng = [ref '.nii.gz'];
            out_ng = [out '.nii.gz'];
            cmd    = sprintf( ...
                '%s -in %s -ref %s -out %s -omat %s -bins 256 -cost corratio -searchrx %i %i -searchry %i %i -searchrz %i %i -dof 6  -refweight %s -interp trilinear', ...
                this.FLIRTBIN, in_ng, ref_ng, out_ng, omat, nrng, rng, nrng, rng, nrng, rng, ref_ng);
            fprintf([cmd '\n']);
            system(cmd);
        end
        function applyxfm(this, in, ref, out, init)
            in_ng  =  [in '.nii.gz'];
            ref_ng = [ref '.nii.gz'];
            out_ng = [out '.nii.gz'];
            cmd    = sprintf( ...
                '%s -in %s -ref %s -out %s -applyxfm -init %s -paddingsize 0.0 -interp trilinear', ...
                this.FLIRTBIN, in_ng, ref_ng, out_ng, init);
            fprintf([cmd '\n']);
            system(cmd);
        end
        function concat(this, xfm13, xfm23, xfm12)
            cmd = sprintf('%s -omat %s -concat %s %s', this.CONVERTBIN, xfm13, xfm23, xfm12);
            fprintf([cmd '\n']);
            system(cmd);
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

