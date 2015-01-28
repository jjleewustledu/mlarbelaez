classdef Test_Deconvolution < matlab.unittest.TestCase 
	%% TEST_DECONVOLUTION  

	%  Usage:  >> results = run(mlarbelaez_unittest.Test_Deconvolution)
 	%          >> result  = run(mlarbelaez_unittest.Test_Deconvolution, 'test_dt')
 	%  See also:  file:///Applications/Developer/MATLAB_R2014b.app/help/matlab/matlab-unit-test-framework.html

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$ 
 	 

	properties 
        Nkernel = 120  
        Nheavi  = 120
        AMAtest_kernel
        AMAtest_smooth
 	end 

	methods (Test)
        function this = test_byFFT_ideal(this)
            %% TEST_BYFFT_IDEAL uses only pure Heaviside, pure Gaussians
            
            heavi5_5 = conv(this.gauss5_5, conv(this.gauss1_0, ones(1,this.Nheavi)));
            %heavi5_5 = heavi5_5(1:this.Nheavi);
            figure;
            plot(heavi5_5);
            title('test\_byFFT\_ideal:  gauss5\_5 * gauss1\_0 * Heaviside');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(heavi5_5, this.gauss5_5);
            len = length(heaviTilde);
            figure;
            plotyy(1:len, real(heaviTilde), 1:len, imag(heaviTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_byFFT\_ideal:  Heaviside^~');
        end
        function this = test_byFFT_AMAtest(this)
            %% TEST_BYFFT_IDEAL uses only pure Heaviside, pure Gaussians
            
            shoulder = conv(this.gauss1_0, ones(1,this.Nheavi));
            shoulder = shoulder(1:this.Nheavi);
            figure;
            plot(shoulder);
            title('test\_byFFT\_AMAtest:  gauss1\_0 * Heaviside');
            
            observed  = conv(this.AMAtest_kernel, shoulder);
            observed  = observed(1:this.Nheavi);
            observed1 = observed(end)*ones(1,this.Nheavi) - observed;
            observed  = [observed observed1];
            figure;
            plot(observed);
            title('test\_byFFT\_AMAtest:  AMAtest\_kernel * gauss1\_0 * Heaviside');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(observed, this.AMAtest_kernel);
            len = length(heaviTilde);
            figure;
            plotyy(1:len, real(heaviTilde), 1:len, imag(heaviTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_byFFT\_AMAtest:  Heaviside^~');
        end
        function this = test_byFFT_AMAtest2(this)
            %% TEST_BYFFT_IDEAL uses only pure Heaviside, pure Gaussians
            
            observed  = this.AMAtest_smooth;
            observed1 = observed(end)*ones(1,length(observed)) - observed;
            observed  = [observed observed1];
            figure;
            plot(observed(1:120));
            title('test\_byFFT\_AMAtest2:  observed from blood-sucker');
            xlabel('time/s');
            ylabel('arbitrary');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(observed, this.AMAtest_kernel);
            figure;
            plotyy(1:120, real(heaviTilde(1:120)), 1:120, imag(heaviTilde(1:120)));
            legend('real(activity^~)', 'imag(activity^~)');
            title('test\_byFFT\_AMAtest2:  estimated deconvolution by symmetrized FFT');
            xlabel('time/s');
            ylabel('arbitrary');
        end
    end
    
    methods
  		function this = Test_Deconvolution(varargin) 
 			this = this@matlab.unittest.TestCase(varargin{:});            
            load('/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/AMAtest5_kernel.mat'); 
            load('/Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez/AMAtest5_smoothed_normed.mat'); 
            this.AMAtest_kernel = AMAtest_kernel;  %#ok<*CPROP>
            this.AMAtest_smooth = AMAtest_smooth;
 		end 
    end 
    
    %% PRIVATE
    
    methods (Access = 'private')
        function f = gauss1_0(this)
            %% GAUSS1_0
            %  sigma = 1 sec
            t = 1:this.Nkernel; 
            f = exp(-(t - 1).^2/2);
            f = f/sum(f);
        end
        function f = gauss5_5(this)
            %% GAUSS5_5
            %  sigma = 5.5206 sec, fwhh = 13 sec, t0 = 31, matched to AMAtest5 from 2014jul16
            t = 1:this.Nkernel;             
            f = exp(-(t - 31).^2/(2*5.5206^2));
            f = f/sum(f);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

