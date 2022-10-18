% SOURCE Abstract, independent source
classdef Source < MCIR.Device
    
    properties (Hidden, Dependent)
        TR % read-only
    end
    
    properties (Hidden)
        DC
        AC
    end
    
    properties (Access=protected)
        tr   % struct: StimType field specifies type
        nodes   % cell array of nodes (2)
    end
    
    methods (Access=protected)
        function obj = Source(n1, n2, name)
            obj@MCIR.Device(name);
            obj.DC = MCIR.Device.undef;
            obj.AC = MCIR.Device.undef;
            obj.tr = {};
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
        end
        
        function SRC = stuff_params(obj, SRC, default)
            % called by derived classes
            % returns VS reduced by the fields used
            if default
                obj.DC = MCIR.Device.undef;
                obj.AC = MCIR.Device.undef;
                obj.tr = {};
            end
            if isfield(SRC,'DC')
                obj.DC = SRC.DC;
                SRC = rmfield(SRC,'DC');
            elseif isfield(SRC,'VALUE')
                obj.DC = SRC.VALUE;
                SRC = rmfield(SRC,'VALUE');
            end
            if isfield(SRC, 'AC')
                obj.AC = SRC.AC;
                SRC = rmfield(SRC,'AC');
            end
            if isfield(SRC, 'PULSE')
                obj.tr = { 'PULSE', MCIR.Source.tr_list(SRC.PULSE, 8) };
                SRC = rmfield(SRC,'PULSE');
            elseif isfield(SRC, 'SINE')
                obj.tr = { 'SINE', MCIR.Source.tr_list(SRC.SINE, 7) };
                SRC = rmfield(SRC,'SINE');
            elseif isfield(SRC, 'EXP')
                obj.tr = { 'EXP', MCIR.Source.tr_list(SRC.EXP, 6) };
                SRC = rmfield(SRC,'EXP');
            elseif isfield(SRC, 'SFFM')
                obj.tr = { 'SFFM', MCIR.Source.tr_list(SRC.SFFM, 5) };
                SRC = rmfield(SRC,'SFFM');
            elseif isfield(SRC, 'PWL')
                obj.tr = { 'PWL', MCIR.Source.tr_list(SRC.PWL, 0) };
                SRC = rmfield(SRC,'PWL');
            elseif isfield(SRC, 'RAND')
                obj.tr = { 'RAND', MCIR.Source.tr_list(SRC.RAND, 3) };
                SRC = rmfield(SRC,'RAND');
            elseif isfield(SRC, 'RANDN')
                obj.tr = { 'RANDN', MCIR.Source.tr_list(SRC.RANDN, 3) };
                SRC = rmfield(SRC,'RANDN');
            elseif isfield(SRC, 'ARB')
                obj.tr = { 'ARB', SRC.ARB };
                SRC = rmfield(SRC,'ARB');
            elseif isfield(SRC, 'PWLFILE')
                obj.tr = { 'PWLFILE', SRC.PWLFILE };
                SRC = rmfield(SRC,'PWLFILE');
            end
        end
        
        function type = get_type(obj) %#ok<MANU>
            type = 'Source';
        end
        
        function eqns = pack_equations(obj,P,v)
            % From a source, P is always size nv x (nv+1)
            % The last column holds the stimulus, with a 1 wherever the
            % stimulus is added, a -1 where it is subtracted, and a 0
            % everywhere else
            % Source.pack_equations generates u depending upon the presence
            % of DC, AC, and TR
            
            nv = length(v);
            Pu = P(:,nv+1);
            P = P(:,1:nv);
            u = struct('name', {}, 'type', {}, 'params', {}, 'DC', {});
            
            if ~MCIR.Device.is_undef(obj.DC) && obj.DC~=0
                u(end+1) = struct('name', 'DC', 'type', 'DC', 'params', [], 'DC', obj.DC);
                P = [P,Pu*obj.DC];
            end
            if ~isempty(obj.AC) && obj.AC~=0
                u(end+1) = struct('name', 'AC', 'type', 'AC', 'params', [], 'DC', obj.DC);
                P = [P,Pu*obj.AC];
            end
            if ~isempty(obj.tr)
                u(end+1) = struct('name', sprintf('TR(%s)', obj.name), 'type', obj.tr{1}, 'params', obj.tr{2}, 'DC', obj.DC);
                P = [P,Pu];
            end
            
            eqns = MCIR.Device.pack_equations(P,v,u);
        end
        
        % Source does not implement list(), alter(), copy(), or generate_equations() methods and is therefore abstract
        
        function str = list_source(obj)
            str = sprintf("%s %s %s", obj.name, obj.nodes{1}, obj.nodes{2});
            if ~MCIR.Device.is_undef(obj.DC)
                str = str + sprintf(" DC=%s", MCIR.Device.encode_value(obj.DC));
            end
            if ~MCIR.Device.is_undef(obj.AC) && obj.AC~=0
                str = str + sprintf(" AC=%s", MCIR.Device.encode_value(obj.AC));
            end
            if ~isempty(obj.tr)
                str = str + " " + obj.TR;
            end
        end
    end

    
    methods % get/set methods

        function TR = get.TR(obj)
            if ~isempty(obj.tr)
                pr = obj.tr{2};
                TR = string(obj.tr{1})+"(";
                for i=1:length(pr)-1
                    TR = TR+MCIR.Device.encode_value(pr(i))+" ";
                end
                TR = TR+MCIR.Device.encode_value(pr(end))+")";
            end
        end
        
        function set.DC(obj, dc)
            if MCIR.Device.is_undef(dc)
                dc = MCIR.Device.undef;
            else
                [dc,tf] = MCIR.Device.eval_value(dc);
                if ~tf
                    throw(MCIR.Source.ME_InvalidValue)
                end
            end
            obj.DC = dc;
        end
        
        function set.AC(obj,ac)
            if MCIR.Device.is_undef(ac)
                ac = MCIR.Device.undef;
            else
                [ac,tf] = MCIR.Device.eval_value(ac);
                if ~tf
                    throw(MCIR.Source.ME_InvalidValue)
                end
            end
            obj.AC = ac;
        end

    end % get/set methods
    
    methods (Static, Access=private)
        list = tr_list(str, len)
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('Source:InvalidValue','Invalid value');
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net