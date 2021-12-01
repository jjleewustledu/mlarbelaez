classdef LogA < mlio.IOInterface
	%% LOGA

	%  $Revision$ 
 	%  was created $Date$ 
 	%  by $Author$,  
 	%  last modified $LastChangedDate$ 
 	%  and checked into repository $URL$,  
 	%  developed on Matlab 8.4.0.150421 (R2014b) 
 	%  $Id$  	 

    properties (Dependent) 
        bloodFlow
        
        filename
        filepath
        fileprefix 
        filesuffix
        fqfilename
        fqfileprefix
        fqfn
        fqfp
    end

    methods %% GET
        function x = get.bloodFlow(this)
            x = this.tp_.parseLeftAssociatedNumeric('BLOOD FLOW       ML/MIN/100G');
        end

        function f = get.filename(this)
            f = this.tp_.filename;
        end
        function f = get.filepath(this)
            f = this.tp_.filepath;
        end
        function f = get.fileprefix(this)
            f = this.tp_.fileprefix;
        end
        function f = get.filesuffix(this)
            f = this.tp_.filesuffix;
        end
        function f = get.fqfilename(this)
            f = this.tp_.fqfilename;
        end
        function f = get.fqfileprefix(this)
            f = this.tp_.fqfileprefix;
        end
        function f = get.fqfn(this)
            f = this.tp_.fqfn;
        end
        function f = get.fqfp(this)
            f = this.tp_.fqfp;
        end
    end

	methods (Static)
        function this = load(fn) 
            this = LogA(mlio.TextParser.load(fn));
        end
    end
    methods
        function c = char(this, varargin)
            c = char(this.fqfilename, varargin{:});
        end
        function s = string(this, varargin)
            s = string(this.fqfilename, varargin{:});
        end
        function save(~)
            warning('mlio:notImplemented', 'LogA.save');
        end
        function saveas(~)
            warning('mlio:notImplemented', 'LogA.saveas');
        end
        function this = LogA(txtParser)
            assert(isa(txtParser, 'mlio.TextParser'));
            this.tp_ = txtParser;
        end
    end 
    
    %% PRIVATE
    
    properties (Access = 'private')
        tp_
    end

	%  Created with Newcl by John J. Lee after newfcn by Frank Gonzalez-Morphy 
end

