classdef Betadcv3  
	%% BETADCV3 duplicates functionality of the original betadcv from Avi Snyder.
    %  The model of the catheter impulse response is in silentGETTKE.  silentBETADCV
    %  returns the response and the dcv as vectors.

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%% $Id$ 
            
	properties          
        nbinMax = 4096
        nbin = 120
        nuclide = { ...
            'O-15 ' ...
            'N-13 ' ...
            'C-11 ' ...
            'Ga-68' ...
            'F-18 ' ...
            'NONE (no decay)' ...
            'O-15 '}
        runType = { ...
            'O-15 Oxygen Metabolism Study   (OO)' ...
            'O-15 Water Blood Flow Study    (HO)' ...
            'O-15 Blood Volume Study        (CO)' ...
            'C-11 Butanol Blood Flow Study  (BU)' ...
            'F-18 Study                         ' ...
            'Misc. Study                        ' ...
            'O-15 Oxygen Steady-State Study (OO)'};
        halfLife = [122.1 597.8 1223 4100 6583.2 1e9]        
        sampleTime = 1 % Sample time (sec/bin)
        wellFactor = nan
        nSmoothing = 2
        catheterId = 1
        nExpand = 7
        scanType = 2
        isotope = 1
        Hct = 42
        
        fileprefix_
        crv_
        dcv_
        response_
    end 
    
    properties (Dependent)        
        crvName
        dcvName
        dataLength
        fileprefix
        crv
        dcv
        response
    end
    
    methods %% GET
        function n = get.crvName(this)
            n = [this.fileprefix_ '.crv'];
        end
        function n = get.dcvName(this)
            n = [this.fileprefix_ '.dcv'];
        end
        function n = get.dataLength(this)
            n = min(length(this.crv_), length(this.dcv_));
        end
        function x = get.fileprefix(this)
            assert(~isempty(this.fileprefix_));
            x = this.fileprefix_;
        end
        function x = get.crv(this)
            assert(~isempty(this.crv_));
            x = this.crv_;
        end
        function x = get.dcv(this)
            assert(~isempty(this.dcv_));
            x = this.dcv_;
        end
        function x = get.response(this)
            assert(~isempty(this.response_));
            x = this.response_;
        end
    end

    methods        
        function [BSRF, BLOOD]       = silentBETADCV(this)
            
            import mlarbelaez.Betadcv2.*;            
            BSRF     = zeros(this.nbinMax, 1);	% Blood sucker impulse response function
            BLOOD    = zeros(this.nbinMax, 1);	% Raw blood curve         
            
            aTable = readtable(this.crvName, 'FileType', 'text', 'ReadVariableNames', false, 'Delimiter', ' ','HeaderLines', 2);
            countsTable = aTable.Var2;
            for I = 1:this.nbin
                BLOOD(I) = countsTable(I) * this.wellFactor;
            end
            
            % For 961 files >= p5999 (25 Feb 2002), set first 2 points equal to third
            BLOOD(1) = BLOOD(3);
            BLOOD(2) = BLOOD(3);
            
            [T0, AK1, E] = this.silentGETTKE;
            NBUF = 20. / this.sampleTime + 1;   % 20-sec deconvolution buffer
            
            while (true)
                TIMPBINE = this.sampleTime * (.5)^this.nExpand;
                U = AK1 * (this.nbinMax * TIMPBINE - T0);
                if (U > 0. && E * U^2 > 20.); break; end
                this.nExpand = this.nExpand - 1;
            end
            N = log((this.nbinMax) / (this.nbin + NBUF)) / log(2.);
            
            this.nExpand = floor(min(this.nExpand, N));
            TIMPBINE = this.sampleTime * (.5)^this.nExpand;
            if (2^this.nExpand * this.nbin > this.nbinMax)
                fprintf('Too many time bins  %i', this.nbin);
                error('mlarbelaez:fortranStop', 'NBIN TOO LARGE');
            end
            
            %	KERNEL CALCULATION
            for I = 1:this.nbinMax
                U = AK1 * ((I - 1) * TIMPBINE - T0);
                if (U <= 0. || E * U^2 > 20.)
                    BSRF(I) = 0.;
                else
                    R = 1. / (1. + U);
                    BSRF(I) = AK1 * TIMPBINE * R * exp(-E * U^2) * (2. * E * U + R);
                end
            end
            sumBSRF = 0.;
            for I = 1:this.nbinMax
                sumBSRF = sumBSRF + BSRF(I);
            end
            fprintf('Impulse response fn area = %8.4f\n', sumBSRF);
            for I = 1:this.nbinMax
                BSRF(I) = BSRF(I) / sumBSRF;
            end
            
            %  Get this.isotope if it is not specified by the scan type
             
            if (this.scanType == 6)
                error('mlarbelaez:fortranStop', 'scanType %i is not supported', this.scanType);
            else
                if (this.scanType == 4)
                    this.isotope = 3;
                elseif (this.scanType == 5)
                    this.isotope = 5;
                else
                    this.isotope = 1;
                end
            end
            LAMBDA = log(2.) / this.halfLife(this.isotope);
            fprintf('Isotope = %s Halflife = %9.2f seconds  Lambda = %g\n', this.nuclide{this.isotope}, this.halfLife(this.isotope), LAMBDA);
            
            for I = this.nbin + 1:this.nbinMax
                BLOOD(I) = 0.;
            end
            NBINE = this.nbin;
            for K = 1:this.nExpand
                [BLOOD, NBINE] = this.EXPAND(BLOOD, NBINE);
            end
            
            %	Decay-correct blood curve
            
            for I = 1:NBINE
                BLOOD(I) = BLOOD(I) * exp(LAMBDA * I * TIMPBINE);
            end
            NBUFE = NBUF * 2^this.nExpand;
            for I = 1:NBUFE
                BLOOD(this.nbinMax-I+1) = BLOOD(1);
            end
             
            %	Deconvolve
             
            % DECONV(BLOOD, BSRF, dcvBlood, this.nbinMax, TMP)
            % K = NBINE / this.nbin;
            % for I = 1:this.nbin
            %     dcvBlood(I) = dcvBlood(I * K);
            % end
            % for I = 1:this.nSmoothing
            %     dcvBlood = CRVSMO(dcvBlood, this.nbin);
            % end
             
            %	Eliminate negative counts
             
            % dcvBlood = CRVMIN(dcvBlood, this.nbin, 0.0);              
            
            %	Two extra points for oxygen
            
            XBIN = 0;
            TIME1 = (this.nbin) * this.sampleTime;
            COUNT1 = 0.;
            OXYCONT = 0.;
            ANSWER = false;
            if (this.scanType == 1)
                OXYCONT = this.GETREAL('Oxygen Content (ml/ml)', 0.01, 0.40);
                fprintf('Add 2 blood points to end of curve for oxygen\n');
                fprintf('for calculation of recirculating water fraction.\n');
                fprintf('Last point should be the plasma counts.\n');
                error('mlarbelaez:notImplemented', 'silentBETADCV''s calls to BLDENTER disabled'); % 800		CALL BLDENTER(LAMBDA, TIME1, COUNT1, this.scanType)
                if (COUNT1 > 0.) %#ok<UNRCH>
                    XBIN = XBIN + 1;
                    TIME(XBIN) = TIME1;
                    COUNTS(XBIN) = COUNT1;
                end
                % ANSWER = this.YESNO('Add another point (y/N)')
                % if (ANSWER) GO TO 800
            else
                % ANSWER = this.YESNO('Add a point to the curve (y/N)')
                if (ANSWER)
                    error('mlarbelaez:notImplemented', 'silentBETADCV''s calls to BLDENTER disabled'); % 810			CALL BLDENTER(LAMBDA, TIME1, COUNT1, this.scanType)
                    if (COUNT1 > 0.) %#ok<UNRCH>
                        XBIN = XBIN + 1;
                        TIME(XBIN) = TIME1;
                        COUNTS(XBIN) = COUNT1;
                    end
                    % Q = 'Add another point to the curve'
                    % CALL YESNO(Q,ANSWER)
                    % if (ANSWER) GO TO 810
                end
            end
            
            fprintf('dcv-file header:  %i %8.4f %6.1f this.wellFactor=%8.4f T0=%5.2f K1=%6.3f E=%4.3f this.nSmoothing=%i %s\n', ...
                this.nbin+XBIN, OXYCONT, this.Hct, this.wellFactor, T0, AK1, E, this.nSmoothing, this.crvName);
        end
        function [T,AK,E]            = silentGETTKE(this)

            import mlarbelaez.Betadcv2.*;            
            if (this.Hct > 1)
                this.Hct = this.Hct / 100.;
            end
            if (this.catheterId == 1) 
                % 35    cm @  5.00 cc/min        1  (standard)
                T = 3.4124 - 3.4306 * (this.Hct - .3552);
                AK = 0.2919 - 0.5463 * (this.Hct - .3552);
                E = 0.0753 - 0.1621 * (this.Hct - .3552);
            else
                % 35+10 cm @  5.00 cc/min        2  (extension)
                T = 5.8971 - 3.2983 * (this.Hct - .3523);
                AK = 0.2095 - 0.1476 * (this.Hct - .3523);
                E = 0.0302 - 0.0869 * (this.Hct - .3523);
            end
            return
        end       
  		function this                = Betadcv3(varargin)
 			%% BETADCV3
 			%  Usage:  this = Betadcv3('p1234ho1')  			 
            
            p = inputParser;
            addOptional(p, 'fileprefix', 'AMAtest6', @ischar);
            parse(p, varargin{:});
            
            this.fileprefix_ = p.Results.fileprefix;
            this = this.readcrv;
            this = this.readdcv;
            
            crvObj = mlpet.CRV.load(this.crvName);
            this.wellFactor = crvObj.wellFactor;
            %load('/Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez/respMean240.mat');
            %this.respMean240_ = respMean240;
 		end 
    end 
    
    methods (Static)
        function this                = plotDeNovoDeconv(fileprefix)
            this = mlarbelaez.Betadcv2(fileprefix);          
            
            crv  = this.normalizeCurve(this.crv_);
            dcv  = this.deNovoDeconv(fileprefix);
            this.makePlot([ crv dcv this.respMean240_ ], '(de novo)');  
        end
        function [deconv,this]       = deNovoDeconv(fileprefix)  
            this = mlarbelaez.Betadcv2(fileprefix);
            assert(lexist(this.crvName, 'file'));
            
            crv  = this.normalizeCurve(this.crv_);
            assert(length(crv) == length(this.respMean240_));
            this.dcv_ = max(this.crv_) * this.normalizeCurve( ...
                             ifft(fft(crv) ./ fft(this.respMean240_)));
            this.dcv_ = this.dcv_(1:length(this.crv_));
            deconv = this.dcv_;
        end
        function this                = plotExistingDeconv(fileprefix)
            this = mlarbelaez.Betadcv2(fileprefix);
            assert(lexist(this.dcvName, 'file'));
            
            crv  = this.normalizeCurve(this.crv_);
            dcv  = this.normalizeCurve(this.dcv_);            
            this.response_ = this.normalizeCurve( ...
                             ifft(fft(crv) ./ fft(dcv)));
            this.makePlot([ crv dcv this.response_ ], '(FFT)');              
        end
        function this                = plotAMAtest(fileprefix)
            if (~exist('fileprefix', 'var'))
                fileprefix = 'AMAtest6'; % Hct = 38% 
            end
            
            [resp,crv,dcv,this] = responseAMAtest(fileprefix);
            this.makePlot([ crv dcv resp ], '(diff)'); 
        end
        function [resp,crv,dcv,this] = responseAMAtest(fileprefix)
            if (~exist('fileprefix', 'var'))
                fileprefix = 'AMAtest6'; % Hct = 38% 
            end
            pwd0 = pwd;
            cd('/Users/jjlee/MATLAB-Drive/mlarbelaez/src/+mlarbelaez');            
            this = mlarbelaez.Betadcv2(fileprefix);                
            
            crv  = this.normalizeCurve(this.crv_);
            dcv  = this.normalizeCurve(this.dcv_);            
            this.response_ = this.normalizeCurve( ...
                             diff(smooth(this.standardizeCurve(this.crv_)))); 
            resp = this.response_; 
            
            cd(pwd0);
        end
    end

    %% PROTECTED
    
    properties (Access = 'protected')
        respMean240_
    end
    
    methods (Static, Access = 'protected')
        function r  = GETINT(q, inf, sup)
            r = mlarbelaez.Betadcv2.GETREAL(q, inf, sup);
        end
        function r  = GETREAL(q, inf, sup)
            queried = '';
            while (isempty(queried))
                queried = input([q ' -> '], 's');
                r = str2double(queried);
                if (r < inf || r > sup); queried = ''; end
            end
        end
        function tf = YESNO(q)
            queried = input([q ' -> '], 's');
            tf = strfncmpi('y', queried, 1);
        end
    end
    
    %% PRIVATE
    
    methods (Access = 'private')        
        function this = readcrv(this)
            crv = readtable(this.crvName, 'FileType', 'text', 'ReadVariableNames', false, 'Delimiter', ' ','HeaderLines', 2);
            this.crv_ = crv.Var2;
        end
        function this = readdcv(this)
            if (strfind(this.dcvName, 'AMAtest'))
                this.dcv_ = mean(this.crv_) * ones(length(this.crv_), 1);
                return
            end
            fid = fopen(this.dcvName);
            dcv = textscan(fid, '%f %f', 'delimiter', ' ', 'MultipleDelimsAsOne', true, 'HeaderLines', 1);
            this.dcv_ = dcv{2};
            fclose(fid);
        end
        function        makePlot(this, data, respAnnot)
            assert(isnumeric(data));
            assert(ischar(respAnnot));
            figure;
            plot(data);
            legend({ sprintf('crv/%g',            max(abs(this.crv_))); ...
                     sprintf('dcv/%g',            max(abs(this.dcv_))); ...
                     sprintf('response/%g %s', max(abs(this.response_)), respAnnot) });
            title(this.fileprefix_, 'FontSize', 16); 
        end 
        function curv                = normalizeCurve(this, curv)
            %% NORMALIZECURVE makes data-curve lengths consistent & normalizes data-curves 
            
            curv = this.standardizeCurve(curv);   
            curv = curv / max(abs(curv));
            curv = [curv; zeros(this.dataLength, 1)]; % zero-pad
        end
        function curv                = standardizeCurve(this, curv)
            %% STANDARDIZECURVE makes data-curve lengths consistent throughout the class; first two data-points are also ignored
            
            len = this.dataLength;
            if (length(curv) < len) % pad with last available data point to obtain this.dataLength
                tmp = zeros(len, 1);
                tmp(1:length(curv)) = curv;
                tmp(length(curv)+1:end) = curv(end)*ones(len - length(curv), 1);
                curv = tmp;
            end
            if (length(curv) > len) % truncate data to this.dataLength
                curv = curv(1:len);
            end
            curv(1) = curv(3);
            curv(2) = curv(3);
        end
    end
    
    methods (Static, Access = 'private')

        function [A, NBIN] = EXPAND(A, NBIN)
            for I = 1:NBIN
                II = NBIN - I + 1;
        		A(2*II) = A(II);
            end
            for I = 1:NBIN - 1
                II = 2 * I;
        		A(II+1) = .5 * (A(II) + A(II + 2));
            end
            NBIN = 2 * NBIN;
            A = A(1:NBIN);
            return
        end
        function X = CRVMIN(X, N, A)
            for I = 1:N
                X(I) = max(X(I), A);
            end
            X = X(1:N);
            return
        end
        function A = CRVSMO(A, N)
            T = A(1);
            for I = 2:N
                U = A(I - 1) + 2. * A(I) + A(I + 1);
                A(I - 1) = T;
        		T = .25 * U;
            end
            A = A(1:2*N);
            return
        end        

        function CONV(F,G,H,N,A)
            %% FORTRAN HEADER        
            % $Header: /home/npggw/tom/src/betadcv/RCS/deconv.f,v 2.0 2004/02/13 19:45:46 tom Exp $
            % $Log: deconv.f,v $
            % Revision 2.0  2004/02/13  19:45:46  tom
            % Feb 2004
            % 
            % Revision 1.2  2002/11/27  22:01:56  tom
            % *** empty log message ***
            % 
            % Revision 1.1  1995/10/03  18:37:03  tom
            % Initial revision
            % 
            % Revision 1.3  1993/12/02  22:30:02  tom
            % Fix rcsheader
            % 
            % Revision 1.2  1993/12/02  22:22:34  tom
            % Added libpe utilities.
            % Allow all scan types (co, oo, etc.)
            % Add extra points of oxygen
            % Add RCSHEADER
            %%

            % %     CALCULATE H=F*G given F,G
            %       REAL*4 H(N),G(N),F(N),A(2*N+4)
            % 			CHARACTER*256	RCSHEADER
            % 			RCSHEADER = "$Id: deconv.f,v 2.0 2004/02/13 19:45:46 tom Exp $"
            %       CALL GCONV(F,G,H,N,A,.TRUE.)
            %       RETURN
        end
        function DECONV(H,G,F,N,A)
            % %     CALCULATE F where H=F*G given H,G
            %       REAL*4 H(N),G(N),F(N),A(2*N+4)
            %       CALL GCONV(H,G,F,N,A,.FALSE.)
            %       RETURN
            %       end
            % 
            %       function GCONV(H,G,F,N,A,L)
            %       REAL*4 H(N),G(N),F(N),A(2*N+4)
            %       LOGICAL*4 L
            %       COMPLEX*8 CH,CG
            %       J=N/2+1
            %       IHR=1
            %       IHI=IHR+J
            %       IGR=IHI+J
            %       IGI=IGR+J
            %       J=1
            %       DO 1 I=0,N/2-1
            %       A(IHR+I)=H(J)
            %       A(IGR+I)=G(J)
            %       J=J+1
            %       A(IHI+I)=H(J)
            %       A(IGI+I)=G(J)
            %       J=J+1
            %     1 CONTINUE
            %       CALL FFT(A(IHR),A(IHI),1,N/2,1,-1)
            %       CALL REALS(A(IHR),A(IHI),N/2,-1)
            %       CALL FFT(A(IGR),A(IGI),1,N/2,1,-1)
            %       CALL REALS(A(IGR),A(IGI),N/2,-1)
            %       DO 2 I=0,N/2
            %       CH=CMPLX(A(IHR+I),A(IHI+I))
            %       CG=CMPLX(A(IGR+I),A(IGI+I))
            % %     TYPE 601,I,CH,CG
            % % 601 FORMAT(I6,4F10.4)
            %       IF(L)THEN
            %       CH=CH*CG
            %       ELSE
            %       CH=CH/CG
            %       ENDIF
            %       A(IHR+I)=REAL(CH)
            %       A(IHI+I)=AIMAG(CH)
            %     2 CONTINUE
            %       CALL REALS(A(IHR),A(IHI),N/2,+1)
            %       CALL FFT(A(IHR),A(IHI),1,N/2,1,+1)
            %       J=1
            %       DO 3 I=0,N/2-1
            %       F(J)=A(IHR+I)
            %       J=J+1
            %       F(J)=A(IHI+I)
            %       J=J+1
            %     3 CONTINUE
            %       RETURN
        end

    end
        
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

