% COUPLING   mutual inductive coupling
%
% Description:
%   COUPLING is not a device by itself, but a mutual coupling between
%   multiple inductors in a Circuit object.
%   k is the coupling coefficient: 0.0 < k <= 1.0
%
% Interface:
%   K = coupling(L1, ..., Ln, k)
%   K.alter(k)
%   K.k = k
%   K.equations                - generate equations for the coupling
%   K.list                     - list the coupling device
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

% Note from the author:
%   coupling was by far the most difficult circuit element to create and
%   the one that has the least elegant implementation. I had to hack in a
%   way for the Circuit object to attach itself to the coupling object when
%   it is created to allow the coupling object to obtain the inductance
%   values needed to calculate mutual inductance from the coupling
%   coefficient.

classdef coupling < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        k
    end
    
    properties (Access=protected)
        kval
        int_refs
        obj_cir
    end
    
    methods (Access=?MCIR.Circuit)
        function attach_circuit(obj,obj_cir)
            obj.obj_cir = obj_cir;
        end
    end
    
    methods % interface methods
        
        function obj = coupling(varargin)
            narginchk(3,Inf)
            name = 'K@'; % auto-generate
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(varargin{end}), true)
            obj.obj_cir = [];
            obj.int_refs = struct('ref',{}, 'ivar',{});
            for i=1:length(varargin)-1
                [il,nl] = MCIR.Device.I(varargin{i});
                obj.int_refs(i).ref = nl;
                obj.int_refs(i).ivar = il;
            end
        end
        
        function new = copy(obj)
            nr = length(obj.int_refs);
            crefs = cell(nr,1);
            for i=1:nr
                crefs{i} = obj.int_refs(i).ref;
            end
            new = MCIR.coupling(crefs{:},obj.kval);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s", obj.name);
            nr = length(obj.int_refs);
            for i=1:nr
                str = str + sprintf(" %s", obj.int_refs(i).ref);
            end
            str = str + sprintf(" %s", MCIR.Device.encode_value(obj.kval));
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            % only coupling value can be altered
            narginchk(2,2)
            obj.stuff_params(MCIR.Device.parse_input(varargin{:}), false)
        end
        
        function refs = refs(obj)
            nr = length(obj.int_refs);
            refs = cell(nr,1);
            for i=1:nr
                refs{i} = obj.int_refs(i).ref;
            end
        end
        
    end % interface methods
    
    methods % get/set methods
        
        function k = get.k(obj)
            k = obj.kval;
        end
        
        function set.k(obj, value)
            [value,tf] = MCIR.Device.eval_value(value);
            % note that coercing value to "almost unity" is done in generate_equations
            if ~tf || value<=0 || value>1  
                throw(MCIR.coupling.ME_InvalidValue);
            end
            obj.kval = value;
        end

        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'coupling';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.kval = 1;
            end
            if isfield(P,'K')
                obj.k = P.K;
            elseif isfield(P,'VALUE')
                obj.k = P.VALUE;
            end
        end
        
        function eqns = generate_equations(obj)
            kv = obj.kval;
            if kv>=1
                % tweak this to "nearly unity" to avoid singular matrix
                kv = 0.9999;
            end
            nr = length(obj.int_refs);
            x = struct('name', {}, 'ic', {});
            P = zeros(nr,nr);
            if ~isempty(obj.obj_cir)
                for i=1:nr
                    Li = obj.obj_cir.get_device(obj.int_refs(i).ref);
                    Liv = Li{1}.L;
                    x(i).name = obj.int_refs(i).ivar;
                    x(i).ic = [];
                    for j=1:nr
                        if j~=i
                            Lj = obj.obj_cir.get_device(obj.int_refs(j).ref);
                            Ljv = Lj{1}.L;
                            M = kv*sqrt(Liv*Ljv);
                            P(i,j) = P(i,j) + M;
                        end
                    end
                end
            end
            eqns = MCIR.Device.pack_equations(P, [], [], [], x);
        end
    end

    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('coupling:InvalidValue','Invalid coupling coefficient');
        end
    end

    methods (Static, Access=public)
        function [K,tf] = SPICE(card)
            [name, ~, params, refs] = MCIR.Device.SPICE_card(card, 'K', 0, 'L', Inf); % Inf -> unknown number of L refs
            if ~isempty(name)
                tf = true;
                K = MCIR.coupling(refs{:}, params);
                K.name = name;
            else
                tf = false;
                K = MCIR.Device.undef;
            end
        end
    end

end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net