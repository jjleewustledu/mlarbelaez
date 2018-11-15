classdef CatheterAnalysis2018 
	%% CATHETERANALYSIS2018 provides a normalized kernel for catheter convolution calculations.  
    %  The experimentally characterized assembly included the two-compartment AIF phantom with needle-junction from
    %  Avi Snyder, the red 0.7447 mL cath from Edwards TruWave REF PX284R and a smaller volume cath, similar to the green
    %  0.6 mL cath from Braun REF V5424, attached to the peristaltic pump and external detector at the BJH NNICU Ecat 
    %  Exact HR+.  H2[15O] labelled whole blood at normal hematocrit within one phantom compartment. The pump extracted 
    %  blood from the unlabelled compartment to attain steady-state flow.  The detector began AIF acquisition 
    %  simultaneously with opening of the needle junction.  Data are stored in AMAtest4-7.crv.  The experiment was 
    %  directed by William J. Powers and Ana Maria Arbelaez on 7/16/2014 between 16:09 - 16:34.  
    %
    %  kernelBest.mat is the result of operations using CatheterSavitzkyGolay2018 and Test_CatheterSavitzkyGolay2018
    %  and uses no decay-correction during analysis.  
    %
    %  See also:  mlarbelaez.CatheterSavitzkyGolay2018,
    %             mlarbelaez/src/+mlarbelaez/kernelBest.mat
    %             mlarbelaez/doc 2018oc15/*.jpeg
    %             mlarbelaez_unittest.Test_CatheterSavitzkeyGolay2018
    %             mlarbelaez/test/+mlarbelaez_unittest/AMAtest6_decaying.fig
    %             mlarbelaez/test/+mlarbelaez_unittest/AMAtest6_decaying.png

	%  $Revision$
 	%  was created 15-Oct-2018 19:43:23 by jjlee,
 	%  last modified $LastChangedDate$ and placed into repository /Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.4.0.813654 (R2018a) for MACI64.  Copyright 2018 John Joowon Lee.
 	
	properties (Constant)
 		CATH_DEAD_SPACE = 1.3481 % (21.8125 g - 20.4644 g) (1 mL/g) measured as depicted in *.jpeg.
        KERNEL_FILE = fullfile(getenv('HOME'), 'MATLAB-Drive', 'mlarbelaez', 'src', '+mlarbelaez', 'kernelBest.mat')
    end
    
    properties (Dependent)
        cathDeadTime
        cathKernel
        cathPumpRate
    end

	methods 
        
        %% GET
        
        function g = get.cathDeadTime(this)
            %% CATHDEADTIME in sec.
            
            g = (this.CATH_DEAD_SPACE/this.cathPumpRate)*60;
        end
        function g = get.cathKernel(this)
            g = this.kernel_;
        end
        function g = get.cathPumpRate(this)
            g = this.pumpRate_;
        end
        
        %%
		  
 		function this = CatheterAnalysis2018(varargin)
 			%% CATHETERANALYSIS2018
 			%  @param pumpRate.

            ip = inputParser;
            addParameter(ip, 'pumpRate', 5, @isnumeric);
            addParameter(ip, 'kernelFile', this.KERNEL_FILE, @(x) lexist(x, 'file'));
            parse(ip, varargin{:});
            
            this.pumpRate_ = ip.Results.pumpRate;
            this.kernel_ = this.buildKernel;
 		end
    end 
    
    %% PRIVATE
    
    properties (Access = private)
        kernel_
        pumpRate_
    end
    
    methods (Access = private)
        function K = buildKernel(this)
            load(this.KERNEL_FILE);
            K = ensureRowVector(kernelBest);
            [~,idxIn] = max(K > 0);
            idxIn = idxIn - 1;
            [~, idxOut] = max(flip(K) > 0);
            idxOut = idxOut - 1;
            idxOut = length(K) - idxOut + 1;
            K = [zeros(1, round(this.cathDeadTime)) K(idxIn:idxOut)];
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

