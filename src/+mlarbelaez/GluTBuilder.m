classdef GluTBuilder
    
	%% GLUTBUILDER 

	%  $Revision$
 	%  was created 27-Jul-2017 18:37:24 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.2.0.538062 (R2017a) for MACI64.  Copyright 2017 John Joowon Lee.
 	
	properties
 		
 	end

	methods         
        function this = buildSessionData(this, varargin)
            ip = inputParser;
            addParameter(ip, 'sessionID', @ischar); % e.g., p1234, p1234_JJL
            addParameter(ip, 'intervention', @isnumeric); % e.g., scan 1, 2
            parse(ip, varargin{:});
            sessid = ip.Results.sessionID;
            if (~lstrfind(sessid, '_JJL'))
                sessid = [sessid '_JJL'];
            end
            
            this.sessionData_ = mlarbelaez.SessionData( ...
                'studyData', this.studyData_, ...
                'sessionPath', fullfile(this.studyData_.subjectsDir, sessid, ''), ...
                'pnumber', sessid(1:5), ...
                'intervention', ip.Results.intervention);
            this.product_ = this.sessionData_;            
        end
        function this = buildClampingCondition(this, varargin)
            ip = inputParser;
            addOptional(ip, 'fqfnXlsx', this.registry_.gluTxlsxFileprefix, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});            
            
            assert(~isempty(this.sessionData_));
            warning('off', 'MATLAB:table:ModifiedVarnames');   
            warning('off', 'MATLAB:table:ModifiedAndSavedVarnames');  
            tbl = readtable(ip.Results.fqfnXlsx, ...
                'Sheet', 'wholeBrain', ...
                'FileType', 'spreadsheet', 'ReadVariableNames', true, 'ReadRowNames', false);
            for idx = 1:length(tbl.plasma_glu)
                if (strcmp(tbl.P(idx), this.sessionData_.pnumber) && ...
                           tbl.scan(idx) == this.sessionData_.intervention)
                    this.sessionData_.plasmaGlucose = tbl.plasma_glu(idx);
                    break
                end
            end
            warning('on', 'MATLAB:table:ModifiedVarnames');
            warning('on', 'MATLAB:table:ModifiedAndSavedVarnames');
            
            this.product_ = this.sessionData_.plasmaGlucose;
        end
        function this = buildRegion(this, varargin)
            ip = inputParser;
            addParameter(ip, 'region', 'hypothalamus');
            parse(ip, varargin{:});
            
            assert(~isempty(this.sessionData_));
            switch (ip.Results.region)
                case {'brainmask' 'wholebrain'}
                    region = mlfourd.ImagingContext( ...
                        fullfile(this.sessionData_.petLocation, '001_on_p8047gluc1_sumt.nii.gz'));
                case 'hypothalamus'
                    region = mlfourd.ImagingContext( ...
                        fullfile(this.sessionData_.scanLocation, '001-true-hypothalamus_on_p8047gluc1.nii.gz'));
                otherwise
                    error('mlarbelaez:unsupportedSwitchCase', ...
                          'GluTBuider.buildRegion.ip.Results.region->%s', ip.Results.region);
            end
            this.sessionData_.region = region;
            this.product_ = region;
        end
        function this = buildModel(this)
            import mlpet.*;  
            sessd = this.sessionData;
            region = sessd.region('typ', 'fileprefix');
            gtf = mlarbelaez.GluTFiles2( ...
                'pnumPath',  sessd.sessionPath, ...
                'scanIndex', sessd.snumber, ...
                'region',    region);
            dta_ = DTA.load(gtf.dtaFqfilename);
            tsc_ = TSC.loadGluTFiles(gtf);
            kin  = mlarbelaez.C11GlucoseKinetics( ...
                {tsc_.times}, ...
                {tsc_.specificActivity}, ...
                dta_, sessd.pnumber, sessd.snumber, 'region', region);
            
            fprintf('AbstractC11GlucoseKinetics.runRegions.pth  -> %s\n', pth);
            fprintf('AbstractC11GlucoseKinetics.runRegions.snum -> %i\n', snum);
            fprintf('AbstractC11GlucoseKinetics.runRegions.region -> %s\n', sessd.region);
            disp(dta_)
            disp(tsc_)
            disp(kin)
            
            kin = kin.doItsBayes;
            this.product_ = kin;
        end
		  
 		function this = GluTBuilder(varargin)
 			%% GLUTBUILDER
 			%  Usage:  this = GluTBuilder()

            import mlarbelaez.*;
            this.registry   = ArbelaezRegistry.instance;
            this.studyData_ = StudyData;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        product_
        registry_
        studyData_
        sessionData_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

