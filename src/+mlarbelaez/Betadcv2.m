classdef Betadcv2  
	%% BETADCV2  

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%% $Id$ 
            
    properties (Constant)
        NBINMAX = 4096
        NUCLIDE = { ...
            'O-15 ' ...
            'N-13 ' ...
            'C-11 ' ...
            'Ga-68' ...
            'F-18 ' ...
            'NONE (no decay)' ...
            'O-15 '}
        RUN_TYPE = { ...
            'O-15 Oxygen Metabolism Study   (OO)' ...
            'O-15 Water Blood Flow Study    (HO)' ...
            'O-15 Blood Volume Study        (CO)' ...
            'C-11 Butanol Blood Flow Study  (BU)' ...
            'F-18 Study                         ' ...
            'Misc. Study                        ' ...
            'O-15 Oxygen Steady-State Study (OO)'};
        HALF_LIFE = [122.1 597.8 1223 4100 6583.2 1e9]  
    end
    
	properties          
        nbin = 120      
        sampleTime = 1 % Sample time (sec/bin)
        wellFactor = 22.74
        nSmoothing = 2
        catheterId = 1
        nExpand = 7
        scanType = 2
        isotope = 1
        Hct = 44        
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
    
    methods (Static)
        function [bsrf,blood,dcv] = createKernel(filename)
            this = mlarbelaez.Betadcv2(filename);
            [bsrf,blood,dcv] = this.silentBETADCV;
        end        
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
        function BSRF                  = tryKernel(this, T0, AK1, E)
            %% TRYKERNEL
            %  b = Betadcv2(study_id_string);
            %  BSRF = b.tryTKE(T0, AK1, E)
            %                  T0 is time offset
            %                      AK1 is a rate-constant
            %                           E ~ 1/variance
            
            import mlarbelaez.*;            
            while (true)
                TIMPBINE = this.sampleTime * (.5)^this.nExpand;
                U = AK1 * (this.NBINMAX * TIMPBINE - T0);
                if (U > 0. && E * U^2 > 20.); break; end
                this.nExpand = this.nExpand - 1;
            end
            NBUF = 20. / this.sampleTime + 1;   % 20-sec deconvolution buffer
            N    = log((this.NBINMAX) / (this.nbin + NBUF)) / log(2.);
            
            this.nExpand = floor(min(this.nExpand, N));
            TIMPBINE = this.sampleTime * (.5)^this.nExpand; % factor for enlarging working array
            if (2^this.nExpand * this.nbin > this.NBINMAX)
                error('mlarbelaez:fortranStop', 'NBIN TOO LARGE->%f', this.nbin);
            end
            
            %%	KERNEL CALCULATION
            
            BSRF = zeros(this.NBINMAX, 1);	% Blood sucker impulse response function
            for I = 1:this.NBINMAX
                U = AK1 * ((I - 1) * TIMPBINE - T0);
                if (U <= 0. || E * U^2 > 20.)
                    BSRF(I) = 0.;
                else
                    R = 1. / (1. + U);
                    BSRF(I) = AK1 * TIMPBINE * R * exp(-E * U^2) * (2. * E * U + R);
                end
            end
            BSRF = BSRF / sum(BSRF);             
        end
        function [BSRF,BLOOD,dcvBlood] = tryTKE(this, T0, AK1, E)
            %% TRYTKE
            %  b = Betadcv2(study_id_string);
            %  [BSRF,BLOOD,dcvBlood] = b.tryTKE(T0, AK1, E)
            
            import mlarbelaez.*;            
            BSRF     = zeros(this.NBINMAX, 1);	% Blood sucker impulse response function
            dcvBlood = zeros(this.NBINMAX, 1);	% Decay corrected deconvolved blood curve  
            TMP      = zeros(2*this.NBINMAX + 4, 1); % Legacy scratch array
            
            BLOOD    = this.countsTable_ * this.wellFactor;            
            BLOOD(1) = BLOOD(3);  % For 961 files >= p5999 (25 Feb 2002), set first 2 points equal to third
            BLOOD(2) = BLOOD(3);
            
            while (true)
                TIMPBINE = this.sampleTime * (.5)^this.nExpand;
                U = AK1 * (this.NBINMAX * TIMPBINE - T0);
                if (U > 0. && E * U^2 > 20.); break; end
                this.nExpand = this.nExpand - 1;
            end
            NBUF = 20. / this.sampleTime + 1;   % 20-sec deconvolution buffer
            N    = log((this.NBINMAX) / (this.nbin + NBUF)) / log(2.);
            
            this.nExpand = floor(min(this.nExpand, N));
            TIMPBINE = this.sampleTime * (.5)^this.nExpand; % factor for enlarging working array
            if (2^this.nExpand * this.nbin > this.NBINMAX)
                error('mlarbelaez:fortranStop', 'NBIN TOO LARGE->%f', this.nbin);
            end
            
            %%	KERNEL CALCULATION
            
            for I = 1:this.NBINMAX
                U = AK1 * ((I - 1) * TIMPBINE - T0);
                if (U <= 0. || E * U^2 > 20.)
                    BSRF(I) = 0.;
                else
                    R = 1. / (1. + U);
                    BSRF(I) = AK1 * TIMPBINE * R * exp(-E * U^2) * (2. * E * U + R);
                end
            end
            BSRF = BSRF / sum(BSRF);            
            
            %%  Expand blood vector
            
            BLOOD(this.nbin + 1:this.NBINMAX) = 0;
            NBINE = this.nbin;
            for K = 1:this.nExpand
                [BLOOD, NBINE] = this.EXPAND(BLOOD, NBINE);
            end
            
            %%	Decay-correct blood curve
            
            LAMBDA = log(2.) / this.HALF_LIFE(this.isotope);
            for I = 1:NBINE
                BLOOD(I) = BLOOD(I) * exp(LAMBDA * I * TIMPBINE);
            end
            NBUFE = NBUF * 2^this.nExpand;
            BLOOD(this.NBINMAX-NBUFE+1:this.NBINMAX) = BLOOD(1);
             
            %%	Deconvolve
             
            dcvBlood = Betadcv2.DECONV(BLOOD, BSRF, dcvBlood, this.NBINMAX, TMP);
            K = NBINE / this.nbin;
            for I = 1:this.nbin
                dcvBlood(I) = dcvBlood(I * K);
            end
            for I = 1:this.nSmoothing
                dcvBlood = Betadcv2.CRVSMO(dcvBlood, this.nbin);
            end
            dcvBlood = dcvBlood(1:this.nbin);
             
            %%	Eliminate negative counts
             
            dcvBlood = Betadcv2.CRVMIN(dcvBlood, this.nbin, 0.0);  
            
            %%  Trim arrays
            
            BSRF = BSRF(1:this.nbin);
            BLOOD = BLOOD(1:this.nbin);
            dcvBlood = dcvBlood(1:this.nbin);
            
        end
        function [BSRF,BLOOD,dcvBlood] = silentBETADCV(this)
            %% SILENTBETADCV
            %  b = Betadcv2(study_id_string)
            %  [BSRF,BLOOD,dcvBlood] = b.silentBETADCV
            
            [T0, AK1, E] = this.silentGETTKE;
            [BSRF,BLOOD,dcvBlood] = this.tryTKE(T0, AK1, E);
        end
        function [T,AK,E]              = silentGETTKE(this)

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
        function curv                  = standardizeCurve(this, curv)
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
        function curv                  = normalizeCurve(this, curv)
            %% NORMALIZECURVE makes data-curve lengths consistent & normalizes data-curves 
            
            curv = this.standardizeCurve(curv);   
            curv = curv / max(abs(curv));
            curv = [curv; zeros(this.dataLength, 1)]; % zero-pad
        end
  		function this                  = Betadcv2(varargin)
 			%% BETADCV2 
 			%  Usage:  this = Betadcv2('p1234ho1')  			 
            
            p = inputParser;
            addOptional(p, 'fileprefix', 'AMAtest6', @ischar);
            parse(p, varargin{:});
            
            this.fileprefix_ = p.Results.fileprefix;
            this = this.readcrv;
            this = this.readdcv;
            this = this.readCountsTable;
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
        fileprefix_
        crv_
        dcv_
        response_
        respMean240_
        countsTable_
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
        function this = readCountsTable(this)
            
            aTable = readtable(this.crvName, 'FileType', 'text', 'ReadVariableNames', false, 'Delimiter', ' ','HeaderLines', 2);
            this.countsTable_ = aTable.Var2;
        end
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
        end
        function A = CRVSMO(A, N)
            lenA = length(A);
            T = A(1);
            for I = 2:N
                U = A(I - 1) + 2 * A(I) + A(I + 1);
                A(I - 1) = T;
        		T = .25 * U;
            end
            A = A(1:lenA);
        end        
        function F = DECONV(H,G,~,N,~)
            %% CALCULATE F where H=F*G given H,G
            %  length N, scratch array A
            
            F = ifft(fft(H, N) ./ fft(G, N));
        end
        function BLDENTER(LAMBDA, LASTTIME, CORCNTS, SCANTYPE)
            %% FORTRAN HEADER
            %$Header: /home/npggw/tom/src/betadcv/RCS/bldenter.f,v 2.0 2004/02/13 19:45:46 tom Exp $
            %$Log: bldenter.f,v $
            % Revision 2.0  2004/02/13  19:45:46  tom
            % Feb 2004
            %
            % Revision 1.3  2002/11/27  22:01:56  tom
            % *** empty log message ***
            %
            % Revision 1.2  1998/07/27  17:51:43  tom
            % automatically subtract 105 sec for added points to CO curve
            %
            % Revision 1.1  1995/10/03  18:37:03  tom
            % Initial revision
            %
            % CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
            %
            %  Subroutine:	bldenter.f
            %  Author:		Tom O. Videen
            %  Date:		27-Oct-86
            %  Written for:	BLOOD.FTN
            %  Intent:		Get blood curve points from user.
            %
            %  History:
            %     Modified 14-Jan-88 by TOV so decay correction is computed by
            %	  including the average decay during the well counting period.
            %	  This is now always computed through a single subroutine BLDDECOR.
            %			Modified 02-Dec-93 by TOV for betadta.
            %
            %  Common Variables whose values are set in this subroutine:
            %     COUNTS - counts per COUNTIME seconds from well counter;
            %     DRYWEIGHT - dry weight of syringe;
            %     WETWEIGHT - weight of syringe with blood sample;
            %     COUNTIME - seconds summed in well counter (usually 10);
            %     TIMEDRAW - time blood sample was taken (MIN.SEC);
            %     TIMECNT - time blood sample was counted (MIN.SEC);
            %     CORCNTS - decay corrected counts/(ml*sec);
            %	  (corrected to time of injection)
            %     BLOODDEN = density of blood (g/ml);
            %
            %  Uses Function:
            %     SECS in BLDSECS
            %%

            % 	REAL*4   LAMBDA
            % 	REAL*4	 SC1
            % 	REAL*4	 SC2
            % 	REAL*4	 BLOODDEN
            % 	REAL*4	 DRYWEIGHT
            % 	REAL*4	 WETWEIGHT
            % 	REAL*4	 WEIGHT
            % 	REAL*4	 SECS
            % 	REAL*4	 COUNTIME
            % 	REAL*4	 LASTTIME
            % 	REAL*4	 TIMEDRAW
            % 	REAL*4	 TIMESECS
            % 	REAL*4	 TIMECNT
            % 	REAL*4	 TIMECOUNTED
            % 	REAL*4	 CORCNTS
            % 	REAL*4	 CORRECTN
            % 	REAL*4	 COUNTS1
            % 
            % 	INTEGER*4    SCANTYPE
            % 	INTEGER*4    USERIN    ! log unit assigned for terminal input!
            % 	INTEGER*4    USEROUT   ! log unit for terminal output!
            % 	INTEGER*4		 COUNTS
            % 
            % 	CHARACTER*80 Q
            % 	CHARACTER*1  BELL
            % 	CHARACTER*256	RCSHEADER
            % 
            % 	COMMON /USRIO/ USERIN,USEROUT
            % 
            % 	DATA SC1, SC2 /1.026, -0.0522/		! new caps, 3cc syringes
            % 	DATA BLOODDEN /1.05/
            % 	RCSHEADER = "$Id: bldenter.f,v 2.0 2004/02/13 19:45:46 tom Exp $"
            % 	BELL = CHAR(7)
            % 
            % 	Q = 'Dry syringe weight (grams)'
            % 	CALL GETREAL (Q, DRYWEIGHT, 0.0, 100.0)
            % 
            % 	Q = 'Wet syringe weight (grams)'
            % 	CALL GETREAL (Q, WETWEIGHT, 0.0, 100.0)
            % 
            % 	WEIGHT   = WETWEIGHT - DRYWEIGHT
            % 	IF (WEIGHT .EQ. 0.) THEN
            % 	  RETURN
            % 	END IF
            % 
            % 	WRITE(USEROUT,*) " "
            % 	WRITE(USEROUT,*) ">>> NOTE THE FORMAT FOR ENTERING TIME!"
            % 	IF (SCANTYPE .EQ. 3) THEN
            % 		WRITE(USEROUT,*) "   (Time will be adjusted by -1:45 for standard CO study)"
            % 	ENDIF
            % 	WRITE(USEROUT,*) " "
            % 10    Q = 'Time Sampled (MIN.SEC)'
            % 	CALL GETREAL (Q, TIMEDRAW, 0., 120.)
            % 	TIMESECS = SECS (TIMEDRAW)
            % 	IF (SCANTYPE .EQ. 3) TIMESECS = TIMESECS - 105
            % 	IF (TIMESECS .LT. LASTTIME) THEN
            % 		WRITE(USEROUT,*) "Sample Time must be >= ", LASTTIME,BELL
            % 		GO TO 10
            % 	END IF
            % 
            % 20    Q = 'Time Counted (MIN.SEC)'
            % 	CALL GETREAL (Q, TIMECNT, 1., 121.0)
            % 	TIMECOUNTED = SECS (TIMECNT)
            % 	IF (SCANTYPE .EQ. 3) TIMECOUNTED = TIMECOUNTED - 105
            % 	IF (TIMECOUNTED .LT. TIMESECS) THEN
            % 		WRITE(USEROUT,*) "Count Time must be >= ", TIMESECS,BELL
            % 		GO TO 20
            % 	END IF
            % 
            % 	Q = 'Well count period (seconds)'
            % 	COUNTIME = 10.
            % 	CALL GETREAL (Q, COUNTIME, 1.0, 1000.0)
            % 
            % 	Q = 'Number of counts'
            % 	CALL GETINT (Q, COUNTS, 0, 999999)
            % C
            % C	Decay correct counts
            % C
            % 	COUNTS1 = FLOAT(COUNTS)*LAMBDA/(1.-EXP(-LAMBDA*COUNTIME))
            % 	CORCNTS = BLOODDEN*COUNTS1*EXP(LAMBDA*TIMECOUNTED)/WEIGHT
            % 
            % 	CORRECTN = SC1 + SC2*WEIGHT
            % 	IF (CORRECTN.GT.0.) THEN
            % 	  CORCNTS = CORCNTS/CORRECTN
            % 	ELSE
            % 	  WRITE(USEROUT,*)'*** TOO MUCH BLOOD IN SYRINGE ***'
            % 	  WRITE(USEROUT,*)'*** Number of Counts Estimated ***',BELL
            % 	  CORCNTS = CORCNTS*10.
            % 	END IF
            % 
            % 	LASTTIME = TIMESECS
            % 
            % 	RETURN
        end
    end
        
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

