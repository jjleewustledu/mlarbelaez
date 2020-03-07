classdef HypoglycemiaStudy < handle & mlpipeline.IStudyData
	%% HYPOGLYCEMIASTUDY  

	%  $Revision$
 	%  was created 21-Jan-2016 12:55:31
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.307022 (R2016a) Prerelease for MACI64.
 	
    properties (Dependent)
        freesurfersDir
        rawdataDir
        subjectsDir
    end

    methods (Static)
        function this = instance(varargin)
            persistent instance_
            if (~isempty(varargin))
                instance_ = [];
            end
            if (isempty(instance_))
                instance_ = mlarbelaez.HypoglycemiaStudy(varargin{:});
            end
            this = instance_;
        end
    end
    
    methods
        
        %% GET
        
        function d = get.freesurfersDir(~)
            d = fullfile(getenv('ARBELAEZ'), 'BOLDHypo', 'freesurfer');
        end
        function d = get.rawdataDir(~)
            d = fullfile(getenv('ARBELAEZ'), 'BOLDHypo', 'rawdata', '');
        end
        function d = get.subjectsDir(~)
            d = fullfile(getenv('ARBELAEZ'), 'BOLDHypo', 'jjlee');
        end
        
        %%
        
        function a = seriesDicom(~, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', '');
        end
        function a = seriesDicomAsterisk(this, fqdn)
            assert(isdir(fqdn));
            assert(isdir(fullfile(fqdn, 'DICOM')));
            a = fullfile(fqdn, 'DICOM', ['*' mlpipeline.ResourcesRegistry.instance().dicomExtension]);
        end
    end
    
    %% PROTECTED
    
	methods (Access = protected) 
 		function this = HypoglycemiaStudy(varargin)
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

