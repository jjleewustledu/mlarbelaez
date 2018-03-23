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
        crv5
        crv6
        kernel5
        kernel6
        
        HOME = fullfile(getenv('HOME'), 'MATLAB-Drive/mlarbelaez')
 	end 

	methods (Test)
        function this = test_kernel6_crv6(this)
            
            crv6_ = smooth(this.crv6.decayCorrectedCounts, 10);
            crv6_ = concatReflection(crv6_);
            figure;
            plot(crv6_);
            title('test\_kernel6\_crv6:  crv6');
            
            d = mlarbelaez.Deconvolution;
            dcvTilde = d.byFFT_pchip(crv6_, this.kernel6);
            len = length(dcvTilde);
            figure;
            plotyy(1:len, real(dcvTilde), 1:len, imag(dcvTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_kernel6\_crv6:  dcv6^~');
        end
        function this = test_kernel5_crv5(this)
            
            crv5_ = smooth(this.crv5.decayCorrectedCounts, 10);
            crv5_ = concatReflection(crv5_);
            figure;
            plot(crv5_);
            title('test\_kernel5\_crv5:  crv5');
            
            d = mlarbelaez.Deconvolution;
            dcvTilde = d.byFFT_pchip(crv5_, this.kernel5);
            len = length(dcvTilde);
            figure;
            plotyy(1:len, real(dcvTilde), 1:len, imag(dcvTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_kernel5\_crv5:  dcv5^~');
        end
        function this = test_kernel5_Heaviside(this)
            
            heavi5_5 = conv(this.kernel5, [0 ones(1,this.Nheavi-1)]);
            %heavi5_5 = heavi5_5(1:this.Nheavi);
            figure;
            plot(heavi5_5);
            title('test\_kernel5\_Heaviside:  kernel5 * Heaviside');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(heavi5_5, this.kernel5);
            len = length(heaviTilde);
            figure;
            plotyy(1:len, real(heaviTilde), 1:len, imag(heaviTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_kernel5\_Heaviside:  Heaviside^~');
        end
        function this = test_byFFT_Heaviside(this)
            %% TEST_BYFFT_HEAVISIDE uses only pure Heaviside, pure Gaussians
            
            heavi5_5 = conv(this.gauss5_5, [0 ones(1,this.Nheavi-1)]);
            %heavi5_5 = heavi5_5(1:this.Nheavi);
            figure;
            plot(heavi5_5);
            title('test\_byFFT\_Heaviside:  gauss5\_5 * Heaviside');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(heavi5_5, this.gauss5_5);
            len = length(heaviTilde);
            figure;
            plotyy(1:len, real(heaviTilde), 1:len, imag(heaviTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_byFFT\_Heaviside:  Heaviside^~');
        end
        function this = test_byFFT_bluntedHeaviside(this)
            %% TEST_BYFFT_BLUNTEDHEAVISIDE uses only pure Heaviside, pure Gaussians
            
            heavi5_5 = conv(this.gauss5_5, conv(this.gauss1_0, ones(1,this.Nheavi)));
            %heavi5_5 = heavi5_5(1:this.Nheavi);
            figure;
            plot(heavi5_5);
            title('test\_byFFT\_bluntedHeaviside:  gauss5\_5 * gauss1\_0 * Heaviside');
            
            d = mlarbelaez.Deconvolution;
            heaviTilde = d.byFFT(heavi5_5, this.gauss5_5);
            len = length(heaviTilde);
            figure;
            plotyy(1:len, real(heaviTilde), 1:len, imag(heaviTilde));
            legend('real(f^~)', 'imag(f^~)');
            title('test\_byFFT\_bluntedHeaviside:  Heaviside^~');
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
            pwd0 = pwd;
            cd(fullfile(this.HOME, 'src/+mlarbelaez'));
            load('AMAtest5_kernel.mat'); 
            load('AMAtest5_smoothed_normed.mat'); 
            this.AMAtest_kernel = AMAtest_kernel;  %#ok<*CPROP>
            this.AMAtest_smooth = AMAtest_smooth;
            cd(fullfile(this.HOME, 'data'));
            load('kernelBest.mat');
            this.kernel5 = zeros(1,128);
            this.kernel5(13:40) = kernelBest(13:40);
            this.kernel5 = this.kernel5/sum(this.kernel5);
            load(fullfile(this.HOME, 'data/kernel6_span33_deg4.mat'));
            this.kernel6 = kernel;
            this.crv5 = mlarbelaez.CRV.load('AMAtest5.crv');
            this.crv6 = mlarbelaez.CRV.load('AMAtest6.crv');
            cd(pwd0);
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
        function f = gauss5_5_centered(this)
            %% GAUSS5_5_CENTERED
            %  sigma = 5.5206 sec, fwhh = 13 sec, t0 = 0
            t = 1:this.Nkernel;             
            f1 = exp(-(t - 1).^2/(2*5.5206^2));
            f2 = exp(-(this.Nkernel - t + 1).^2/(2*5.5206^2));
            f  = [f1(1:this.Nkernel/2) f2(this.Nkernel/2+1:end)];
            f  = f/sum(f);
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

