classdef GluTxlsxMacaque < mlarbelaez.IGluTxlsx  
	%% GLUTXLSXMACAQUE   

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.5.0.197613 (R2015a) 
 	%  $Id$ 
 	 

	properties  	
        sheet_hemispheres = 'hemispheres'	 	 
        mode = 'Hemisphere'
        pid_map
 	end 

    properties (Dependent)
        title
        xlsx_filename
        defaultFilename
    end
    
    methods %% GET
        function t = get.title(this)
            [~,t] = fileparts(this.xlsx_filename);
        end
        function x = get.xlsx_filename(this)
            x = this.defaultFilename;
        end
        function x = get.defaultFilename(this) %#ok<MANU>
            x = fullfile(getenv('ARBELAEZ'), 'pet6_c11monkey', 'Macaques 1995.xlsx');
        end
    end
    
	methods 
		  
 		function this = GluTxlsxMacaque() 
 			%% GLUTXLSXMACAQUE 
 			%  Usage:  this = GluTxlsxMacaque() 
      
            assert(strcmp('Hemisphere', this.mode));
            [~,~,this.raw_] = xlsread(this.xlsx_filename, this.sheet_hemispheres);
            this.pid_map = containers.Map;
            
            for p = this.scan_rows_(1):2:this.scan_rows_(2)-1
                this.pid_map(this.raw_{p,this.col_pid_}) = ...
                    struct('left', ...
                            struct('glu', this.raw_{p,this.col_glu_}, ...
                                   'cbf', this.raw_{p,this.col_cbf_}, ...
                                   'cbv', this.raw_{p,this.col_cbv_}, ...
                                   'hct', this.raw_{p,this.col_hct_}), ...
                           'right', ...
                            struct('glu', this.raw_{p+1,this.col_glu_}, ...
                                   'cbf', this.raw_{p+1,this.col_cbf_}, ...
                                   'cbv', this.raw_{p+1,this.col_cbv_}, ...
                                   'hct', this.raw_{p+1,this.col_hct_}));
            end 			 
 		end 
    end 
    
    %% PROTECTED
    
    properties (Access = 'protected')
        raw_
        col_npid_ = 1
        col_pid_  = 2
        col_hemi_ = 3
        col_glu_  = 4 % mg/dL
        col_cbf_  = 5
        col_cbv_  = 6
        col_hct_  = 7
        scan_rows_ = [2 17]
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

