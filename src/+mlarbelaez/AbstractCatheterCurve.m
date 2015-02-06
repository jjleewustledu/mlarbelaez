classdef AbstractCatheterCurve  
	%% ABSTRACTCATHETERCURVE 

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$  	 
    
    properties (Abstract, Constant)
        EXTENSION
    end 
    
    properties
        dt = 1
        scanDuration = 120 % sec
    end
    
	properties (Dependent)
        studyId
        pathname
        filename
        times
        timesNoManual
        counts
        countsNoManual
        length
    end 
    
    methods %% GET, SET
        function s    = get.studyId(this)
            s = this.studyId_;
        end
        function this = set.studyId(this, s)
            assert(this.wellFormedStudyId(s));
            this.studyId_ = s;
        end
        function p    = get.pathname(this)
            p = this.pathname_;
        end
        function this = set.pathname(this, p)
            assert(lexist(p, 'dir'));
            this.pathname_ = p;
        end
        function f    = get.filename(this)
            f = fullfile(this.pathname, [this.studyId this.EXTENSION]);
        end
        function t    = get.times(this)
            assert(~isempty(this.times_));
            t = this.times_;
        end
        function t    = get.timesNoManual(this)
            assert(~isempty(this.times_));
            t = this.times_(1:this.scanDuration);
        end
        function this = set.times(this, t)
            assert(isnumeric(t));
            this.times_ = t;
        end
        function c    = get.counts(this)
            assert(~isempty(this.counts_));
            c = this.counts_;
        end
        function c    = get.countsNoManual(this)
            assert(~isempty(this.counts_));
            c = this.counts_(1:this.scanDuration);
        end
        function this = set.counts(this, c)
            assert(isnumeric(c));
            this.counts_ = c;
        end
        function l    = get.length(this)
            l = min(length(this.times), length(this.counts));
        end
    end
    
	methods 
        function d    = double(this)
            d = this.counts;
        end
        function c    = cell(this)
            c = {this.times this.counts};
        end
    end 
    
    %% PROTECTED
    
    methods (Access = 'protected')        
        function tf = wellFormedStudyId(~, sid)
            tf = true;
            if ( lstrfind(sid, 'AMAtest')); return; end
            if (~ischar(sid)); tf = false; return; end
            if ( strcmp('/', sid(1)))
                [~,f] = fileparts(sid);
                sid = f;
            end
            if (~strcmp('p', sid(1))); tf = false; return; end
            if (~lstrfind(sid, {'ho' 'oo' 'oc' 'g'})); tf = false; return; end
            if ( isnan(str2double(sid(2:5)))); tf = false; return; end
        end
    end

    %% PRIVATE
    
    properties (Access = 'private')
        pathname_
        studyId_
        times_
        counts_
    end
    
	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

