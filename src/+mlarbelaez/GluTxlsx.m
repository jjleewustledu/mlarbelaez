classdef GluTxlsx  
	%% GLUTXLSX   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties  		 
        glut_xlsx = '/Volumes/PassportStudio2/Arbelaez/GluT/GluT de novo, JJL, 2014nov19.xlsx'
        glut_sheet = 'GluT Data'
        pid_map
    end 

    properties (Dependent)
        title
    end
    
    methods %% GET
        function t = get.title(this)
            t = [this.raw_{1,1} '; ' this.raw_{2,1} '; ' this.raw_{3,1}];
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
		
 		function this = GluTxlsx() 
            [~,~,this.raw_] = xlsread(this.glut_xlsx, this.glut_sheet);
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
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        raw_
        col_pid_ = 1
        col_glu_ = 2 % mg/dL
        col_cbf_ = 3
        col_cbv_ = 4
        col_hct_ = 5
        scan1_rows_ = [7 24]
        scan2_rows_ = [27 44]
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

