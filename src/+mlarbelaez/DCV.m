classdef DCV < mlarbelaez.AbstractCatheterCurve	
	%% DCV objectifies Snyder-Videen *.dcv files, replacing the first two count measurements with the third,
    %  adding hand-measured counts at the end for assessment of detector drift

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.3.0.532 (R2014a) 
 	%  $Id$ 

    properties (Constant)
        EXTENSION = '.dcv'
    end 
    
	properties (Dependent)
        header
        headerString
        extraSamples
    end 
    
    methods %% GET 
        function h = get.header(this)
            assert(~isempty(this.header_) && isstruct(this.header_));
            h = this.header_;
        end
        function s = get.headerString(this)
            assert(~isempty(this.header_) && isstruct(this.header_));
            s = this.header.string;
        end
        function s = get.extraSamples(this)
            s = [];
            if (length(this.times)*this.dt > this.scanDuration)
                endScan = ceil(this.scanDuration/this.dt);
                t = this.times(endScan+1:end);
                c = this.counts(endScan+1:end);
                s = {t c};
            end
        end
    end

	methods 
        function this = save(this)
            fid = fopen(this.filename, 'w');
            fprintf(fid, '%s\n', this.headerString);
            for f = 1:length(this.counts)
                fprintf(fid, '%9.1f\t%14.1f\n', this.times(f), this.counts(f));
            end
            fclose(fid);            
            %dlmwrite(this.filename, round([this.times' this.counts']), '-append', 'delimiter', '\t');
        end
        function this = updateEarlyCounts(this, c)
            tmp = this.counts;
            tmp(1:length(c)) = c;
            this.counts = tmp;
        end
  		function this = DCV(varargin) 
 			%% DCV 
 			%  Usage:  this = DCV(studyId_string[, path_string]) 

            p = inputParser;
            addRequired(p, 'studyId',       @ischar);
            addOptional(p, 'pathname', pwd, @ischar);
            parse(p, varargin{:});
            
            this.studyId  = p.Results.studyId;
            this.pathname = p.Results.pathname;
            if (lexist(this.filename))
                this = this.readdcv;
            end
        end         
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        header_ % struct
        HEADER_EXPRESSION_ = ...
            ['(?<clock>\d+:\d+)\s+(?<samples>\d+)\s+(?<n1>\d+.\d+)\s+(?<n2>\d+.\d+)\s+' ...
             'WELLF=\s*(?<wellf>\d+.\d+)\s+T0=\s*(?<t0>\d+.\d+)\s+K1=\s*(?<k1>\d+.\d+)\s+E=\s*(?<e>\d*.\d+)\s+NSMO=\s*(?<nsmo>\d+)\s+' ...
             '(?<filename>\w+.\w+)']
        % matches contents similar to:
        % '2:19       121  0.0000  28.4  WELLF= 22.7400 T0= 3.66 K1= 0.331 E=.087 NSMO= 2  p8425ho2.crv        '
    end
    
    methods (Access = 'private')
        function this = readdcv(this)
            fid = fopen(this.filename);
            this.header_ = this.readHeader(fid);
            ts = textscan(fid, '%f %f', 'Delimiter', ' ', 'MultipleDelimsAsOne', true);
            this.times = ts{1}';
            this.counts = ts{2}';
            fclose(fid);            
            
            this.scanDuration = this.times(end);
        end
        function h    = readHeader(this, fid)
            str = textscan(fid, '%s', 1, 'Delimiter', '\n');
            str = str{1}; str = str{1};
            h   = regexp(str, this.HEADER_EXPRESSION_, 'names');
            
            h.string  = str;
            h.samples = uint8(str2double(h.samples));
            h.n1      = str2double(h.n1);
            h.n2      = str2double(h.n2);
            h.wellf   = str2double(h.wellf);
            h.t0      = str2double(h.t0);
            h.k1      = str2double(h.k1);
            h.e       = str2double(h.e);
            h.nsmo    = uint8(str2double(h.nsmo));
        end
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

