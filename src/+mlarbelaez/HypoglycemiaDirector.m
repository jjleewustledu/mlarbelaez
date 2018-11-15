classdef HypoglycemiaDirector < mlarbelaez.StudyDirector
	%% HYPOGLYCEMIADIRECTOR  

	%  $Revision$
 	%  was created 05-Jan-2018 19:15:33 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.3.0.713579 (R2017b) for MACI64.  Copyright 2018 John Joowon Lee.
 	
    methods (Static)
        function sessd = constructSessionData(pth, v, s)
            import mlarbelaez.*;
            sessd = HypoglycemiaSessionData( ...
                'studyData', HypoglycemiaStudy, ...
                'sessionPath', pth, ...
                'vnumber', v, ...
                'snumber', s);
        end
        function this  = sortDownloads(downloadPath, sessionFolder, v, varargin)
            %% SORTDOWNLOADS installs data from rawdata into HypoglycemiaStudy.subjectsDir; 
            %  start here after downloading rawdata.  
            
            ip = inputParser;
            addRequired(ip, 'downloadPath', @isdir);
            addRequired(ip, 'sessionFolder', @ischar);
            addRequired(ip, 'v', @isnumeric);
            addOptional(ip, 'kind', '', @ischar);
            parse(ip, downloadPath, sessionFolder, v, varargin{:});

            import mlarbelaez.*;
            pth = fullfile(HypoglycemiaStudy.subjectsDir, sessionFolder, '');
            if (~isdir(pth))
                mkdir(pth);
            end
            pwd0 = pushd(pth);
            this = HypoglycemiaDirector( ...
                'sessionData', ...
                HypoglycemiaSession('studyData', HypoglycemiaStudy, 'sessionPath', pth, 'vnumber', v));
            switch (lower(ip.Results.kind))
                case 'freesurfer'
                    this = this.instanceSortDownloadFreesurfer(downloadPath);
                otherwise
                    this = this.instanceSortDownloads(downloadPath);
            end
            cd(pwd0);
        end
    end
    
	methods
        
        %%
        
        function this = instanceSortDownloads(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.vLocation, ...
                    'sessionData', this.sessionData);
            catch ME
                handexcept(ME, 'mlarbelaez:filesystemError', ...
                    'HypoglycemiaDirector.instanceSortDownloads.downloadPath->%s may be missing folders SCANS, RESOURCES', ...
                    downloadPath);
            end
        end
        function this = instanceSortDownloadCT(this, downloadPath)
            import mlfourdfp.*;
            try
                DicomSorter.CreateSorted( ...
                    'srcPath', downloadPath, ...
                    'destPath', this.sessionData_.sessionPath, ...
                    'sessionData', this.sessionData);
            catch ME
                handexcept(ME, 'mlraichle:filesystemError', ...
                    'HyperglycemiaDirector.instanceSortDownloadCT.downloadPath->%s may be missing folder SCANS', downloadPath);
            end
        end
        function this = instanceSortDownloadFreesurfer(this, downloadPath)
            try
                [~,downloadFolder] = fileparts(downloadPath);
                dt = mlsystem.DirTool(fullfile(downloadPath, 'ASSESSORS', '*freesurfer*'));
                for idt = 1:length(dt.fqdns)
                    DATAdir = fullfile(dt.fqdns{idt}, 'DATA', '');
                    if (~isdir(this.sessionData.freesurferLocation))
                        if (isdir(fullfile(DATAdir, downloadFolder)))
                            DATAdir = fullfile(DATAdir, downloadFolder);
                        end
                        movefile(DATAdir, this.sessionData.freesurferLocation);
                    end
                end
            catch ME
                handexcept(ME, 'mlarbelaez:filesystemError', ...
                    'HypoglycemiaDirector.instanceSortDownloadFreesurfer.downloadPath->%s may be missing folder ASSESSORS', ...
                    downloadPath);
            end
        end
        function this = prepareAbstractADA2018(this)
            ada2018 = mlarbelaez.ADA2018;
            ada2018.prepareAbstract;
        end
		  
 		function this = HypoglycemiaDirector(varargin)
 			%% HYPOGLYCEMIADIRECTOR
 			%  Usage:  this = HypoglycemiaDirector()
 			
            this = this@mlarbelaez.StudyDirector(varargin{:});
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

