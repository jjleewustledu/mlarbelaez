classdef GluTxlsx < mlarbelaez.IGluTxlsx 
	%% GLUTXLSX is a rapid prototype that read xlsx files containing whole-brain data or data 
    %  obtained using Alex Shimony's ROIs.  It is used primarily for its property pid_map.
    %  See also:  /Volumes/SeagateBP4/Arbeleaz/GluT/GluT de novo 2015aug11.xlsx 
    %             mlarbelaez.Kinetics4McmcProblem
    %             mlarbelaez.RegionalMeasurements

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 

	properties  	
        xlsx_filename	 
        sheet_wholeBrain = 'wholeBrain'
        sheet_regional = 'regional'
        mode = 'WholeBrain'
        pid_map
    end 

    properties (Dependent)
        title
        defaultFilename
    end
    
    methods %% GET
        function t = get.title(this)
            [~,t] = fileparts(this.xlsx_filename);
        end
        function f = get.defaultFilename(this) %#ok<MANU>
            f = mlarbelaez.ArbelaezRegistry.instance.gluTxlsxFqfilename;
        end
    end
    
    methods (Static)
        function g = glu_mmol(g,hct)
            mw_glu = 180.1559 - 1.0111; % g/mol, for [11C]
            if (hct > 1)
                hct = hct/100; end
            g = g*(10/mw_glu)*(1 - 0.3*hct);
        end
        function f = cbf_fromcbv(v)
            f = 20.84*v^0.671;
        end
    end
    
	methods 		
 		function this = GluTxlsx(varargin)            
            ip = inputParser;
            addParameter(ip, 'Mode',     'WholeBrain',         @ischar);
            addParameter(ip, 'Filename', this.defaultFilename, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            this.xlsx_filename = ip.Results.Filename;
            this.mode = ip.Results.Mode;
            switch (this.mode)
                case 'WholeBrain'
                    this = this.loadWholeBrain;
                case 'AlexsRois'
                    this = this.loadAlexsRois;
                otherwise
                    error('mlarbelaez:switchFailure', 'GluTxlsx.ctor');
            end
 		end 
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        raw_
        col_npid_ = 1
        col_pid_  = 2
        col_scan_ = 3
        col_glu_  = 4 % mg/dL
        col_cbf_  = 5
        col_cbv_  = 6
        col_hct_  = 7
        col_region_ = 11
        scan1_rows_ =  [2 19]
        scan2_rows_ = [20 37]
        scan1_rows__ = [2  6]
        scan2_rows__ = [7 11]
    end
    
    methods (Access = 'protected')
        function this = loadWholeBrain(this)            
            [~,~,this.raw_] = xlsread(this.xlsx_filename, this.sheet_wholeBrain);
            this.pid_map = containers.Map;
            D = this.scan2_rows_(1) - this.scan1_rows_(1);
            for p = this.scan1_rows_(1):this.scan1_rows_(2)
                this.pid_map(this.raw_{p,this.col_pid_}) = ...
                    struct('scan1', ...
                            struct('glu', this.raw_{p,this.col_glu_}, ...
                                   'cbf', this.raw_{p,this.col_cbf_}, ...
                                   'cbv', this.raw_{p,this.col_cbv_}, ...
                                   'hct', this.raw_{p,this.col_hct_}), ...
                           'scan2', ...
                            struct('glu', this.raw_{p+D,this.col_glu_}, ...
                                   'cbf', this.raw_{p+D,this.col_cbf_}, ...
                                   'cbv', this.raw_{p+D,this.col_cbv_}, ...
                                   'hct', this.raw_{p+D,this.col_hct_}));
            end
        end
        function this = loadAlexsRois(this)  
            [~,~,this.raw_] = xlsread(this.xlsx_filename, this.sheet_regional);
            this.pid_map = containers.Map;
            D = length(mlarbelaez.ArbelaezRegistry.instance.regionLabels);
            for p = 2:2
                cbfs1 = zeros(D,1);
                cbvs1 = zeros(D,1);
                cbfs2 = zeros(D,1);
                cbvs2 = zeros(D,1);
                for r = 1:D
                    cbfs1(r) = this.raw_{p+r-1,this.col_cbf_};
                    cbvs1(r) = this.raw_{p+r-1,this.col_cbv_};
                    cbfs2(r) = this.raw_{p+r-1+D,this.col_cbf_};
                    cbvs2(r) = this.raw_{p+r-1+D,this.col_cbv_};
                end
                this.pid_map(this.raw_{p,this.col_pid_}) = ...
                    struct('scan1', ...
                            struct('glu', this.raw_{p,this.col_glu_}, ...
                                   'cbf', cbfs1, ...
                                   'cbv', cbvs1, ...
                                   'hct', this.raw_{p,this.col_hct_}), ...
                           'scan2', ...
                            struct('glu', this.raw_{p+D,this.col_glu_}, ...
                                   'cbf', cbfs2, ...
                                   'cbv', cbvs2, ...
                                   'hct', this.raw_{p+D,this.col_hct_}));
            end
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

