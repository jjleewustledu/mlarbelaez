classdef T4ResolveBuilder < mlfourdfp.T4ResolveBuilder
	%% T4RESOLVEBUILDER  

	%  $Revision$
 	%  was created 18-Apr-2016 18:56:37
 	%  by jjlee,
 	%  last modified $LastChangedDate$
 	%  and checked into repository /Users/jjlee/Local/src/mlcvl/mlarbelaez/src/+mlarbelaez.
 	%% It was developed on Matlab 9.0.0.341360 (R2016a) for MACI64.
 	

    properties (Dependent)	
        blurArg
        gaussArg
    end
    
    methods % GET
        function g = get.blurArg(this)
            g = 1.5*this.petBlur;
        end
        function g = get.gaussArg(this)
            g = 3*this.F_HALF_x_FWHM/this.petBlur;
        end
    end
    
	properties 	
        atlasTag  = 'TRIO_Y_NDC'
        firstCrop = 1      
        initialT4 = fullfile(getenv('RELEASE'), 'T_t4')
 	end

    methods (Static)
        function sessds = parallel
            
            setenv('DEBUG', ''); 
            
            studyd   = mlarbelaez.StudyDataSingleton.instance('initialize');
            iterator = studyd.createIteratorForSessionData;
            sessds   = cell(1,20);
            for p = 1:20
                sessds{p} = iterator.next;
            end
                          
            parfor p = 1:20
                for s = 1:2
                    if (p > 2)
                        if (isa(sessds{p}, 'mlpipeline.SessionData'))
                            sessds{p}.snumber = s;
                            disp(sessds{p});
                            this = mlarbelaez.T4ResolveBuilder('sessionData', sessds{p});
                            this.t4ResolveSubject;
                        else
                            warning('mlarbelaez:unexpectedTypeclass', ...
                                    'class(T4ResolveBuilder.sessds{%i})->%s', p, class(sessds{p}));
                        end
                    end
                end
            end
        end
        function sessds = batch
            
            setenv('DEBUG', ''); 
            
            studyd   = mlarbelaez.StudyDataSingleton.instance('initialize');
            iterator = studyd.createIteratorForSessionData;
            sessds   = cell(1,20);
            for p = 1:20
                sessds{p} = iterator.next;
            end
                          
            for p = 1:1
                for s = 1:2
                    sessds{p}.snumber = s;
                    disp(sessds{p});
                    this = mlarbelaez.T4ResolveBuilder('sessionData', sessds{p});
                    this.t4ResolveSubject;
                end
            end
        end
    end
    
	methods 
		function this = t4ResolveSubject(this)
            this = this.t4ResolvePET;
        end
        function this = t4ResolvePET(this)            
            pnum        = this.sessionData.pnumber;            
            snum        = this.sessionData.snumber;
            petPth      = this.sessionData.petPath;
            mriPth      = this.sessionData.mriPath;
            mpr_fp      = 'T1';
            mpr_4       = [mpr_fp '.4dfp.img'];
            mpr_mgz     = [mpr_fp '.mgz'];
            mprToAtl_t4 = [mpr_fp '_to_' this.atlasTag '_t4'];
            
            cd(petPth);
            mlbash('cp -f ../T1* .');
            if (~lexist(mpr_4, 'file'))
                if (~lexist(fullfile(mriPth, mpr_4)))
                    this.buildVisitor.cp(fullfile(mriPth, mpr_mgz));
                    this.ensure4dfp(mpr_mgz);
                else
                    error('mlfourdfp:fileNotFound', 'T4ResolveBuilder.t4ResolvePET:  could not find %s', mpr_4);
                end
            end
            if (~lexist(mprToAtl_t4))
                this.msktgenMprage(mpr_fp, this.atlasTag);
            end
            
            this.product_ = [];
            tracers = {'gluc' 'ho'};
            for t = 1:length(tracers)
                if (lexist(fullfile(petPth, sprintf('%s%s%i.4dfp.img', pnum, tracers{t}, snum))))
                    tracerdir = fullfile(petPth, sprintf('%s%i', upper(tracers{t}), snum), '');
                    this.buildVisitor.mkdir(tracerdir);
                    cd(tracerdir);
                    this.buildVisitor.cp(     fullfile(petPth, mprToAtl_t4));
                    this.buildVisitor.cp_4dfp(fullfile(petPth, mpr_fp));
                    this.ensure4dfp(          fullfile(petPth, sprintf('%s%s%i', pnum, tracers{t}, snum)));
                    this.buildVisitor.cp_4dfp(fullfile(petPth, sprintf('%s%s%i', pnum, tracers{t}, snum)));
                    fdfp0 = sprintf('%s%s%i', pnum, tracers{t}, snum);
                    fdfp1 = sprintf('%s%s%i', pnum, tracers{t}, snum);
                    this.t4ResolveIterative(fdfp0, fdfp1, mpr_fp);
                end
            end
        end
        
 		function this = T4ResolveBuilder(varargin)
 			%% T4RESOLVEBUILDER
 			%  Usage:  this = T4ResolveBuilder()

 			this = this@mlfourdfp.T4ResolveBuilder(varargin{:});
            this.firstCrop = 1;
 		end
 	end 

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy
 end

