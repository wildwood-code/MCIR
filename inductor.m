% INDUCTOR   linear electronic inductor
%
% Description:
%   INDUCTOR is a linear, 2-terminal inductor model including series and
%   parallel resistance.
%
% Interface:
%   L = inductor(n1, n2, value)
%   L.alter(value)
%   L.L = inductance
%   L.Rser = series-R
%   L.Rpar = parallel-R
%   L.IC = initial-condition
%   L.params = param-card      - alternate to alter
%   L.equations                - generate equations for the inductor
%   L.list                     - list the inductor
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef inductor < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        L
        Rser
        Rpar
        IC
        params % write-only
    end
    
    properties (Access=protected)
        Lval
        nodes
        rs
        rp
        ic
    end
    
    methods % interface methods
        
        function obj = inductor(n1, n2, params)
            narginchk(3,3)
            name = 'L@'; % auto-generate
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
        end
        
        function new = copy(obj)
            parms = struct('L', obj.Lval, 'IC', obj.ic, 'RPAR', obj.rp, 'RSER', obj.rs);
            new = MCIR.inductor(obj.nodes{1}, obj.nodes{2}, parms);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, MCIR.Device.encode_value(obj.Lval));
            if obj.rs>0
                str = str + sprintf(" Rser=%s", MCIR.Device.encode_value(obj.rs));
            end
            if ~isinf(obj.rp)
                str = str + sprintf(" Rpar=%s", MCIR.Device.encode_value(obj.rp));
            end
            if ~isempty(obj.ic)
                str = str + sprintf(" IC=%s", MCIR.Device.encode_value(obj.ic));
            end
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            narginchk(2,Inf)
            obj.stuff_params(MCIR.Device.parse_input(varargin{:}), false)
        end
        
    end % interface methods
    
    methods % get/set methods
        
        function set.params(obj, parms)
            obj.alter(parms)
        end
        
        function L = get.L(obj)
            L = obj.Lval;
        end
        
        function set.L(obj, value)
            [value,tf] = MCIR.Device.eval_value(value);
            if ~tf || value<=0.0
                throw(MCIR.inductor.ME_InvalidValue);
            end
            obj.Lval = value;
        end
        
        function rser = get.Rser(obj)
            rser = obj.rs;
        end
        
        function set.Rser(obj, rs)
            rs = MCIR.Device.eval_value(rs);
            [rs,tf] = MCIR.Device.eval_value(rs);
            if ~tf || rs<0.0 || isinf(rs)
                throw(MCIR.inductor.ME_InvalidValue);
            end
            obj.rs = rs;
        end
        
        function rpar = get.Rpar(obj)
            rpar = obj.rp;
        end
        
        function set.Rpar(obj, rp)
            [rp,tf] = MCIR.Device.eval_value(rp);
            if ~tf || rp<=0.0
                throw(MCIR.inductor.ME_InvalidValue);
            elseif MCIR.Device.is_undef(rp)
                rp = Inf;
            end
            obj.rp = rp;
        end
        
        function IC = get.IC(obj)
            IC = obj.ic;
        end
        
        function set.IC(obj, ic)
            if isempty(ic)
                obj.ic = ic;
            else
                [ic,tf] = MCIR.Device.eval_value(ic);
                if ~tf
                    throw(MCIR.inductor.ME_InvalidValue);
                elseif MCIR.Device.is_undef(ic)
                    obj.ic = MCIR.Device.undef;
                else
                    obj.ic = ic;
                end
            end
        end

        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'inductor';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.Lval = MCIR.Device.undef;
                obj.rs = 0;
                obj.rp = Inf;
                obj.ic = MCIR.Device.undef;
            end
            if isfield(P,'L')
                obj.L = P.L;
            elseif isfield(P,'VALUE')
                obj.L = P.VALUE;
            end
            if isfield(P, 'RSER')
                obj.Rser = P.RSER;
            end
            if isfield(P, 'RPAR')
                obj.Rpar = P.RPAR;
            end
            if isfield(P, 'IC')
                obj.IC = P.IC;
            end
        end
        
        function eqns = generate_equations(obj)
            name = obj.name;
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.V(name,'VL');
            x.name = MCIR.Device.I(name);
            x.ic = obj.ic;
            eqns = MCIR.Device.pack_equations([obj.Lval 0 0 -1;1 1/obj.rp -1/obj.rp 0;-1 -1/obj.rp 1/obj.rp 0;obj.rs -1 1 1], v, [], [], x);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('inductor:InvalidValue','Invalid inductance');
        end
    end
    
    methods (Static, Access=public)
        function [L,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'L', 2);
            if ~isempty(name)
                tf = true;
                L = MCIR.inductor(nodes{1}, nodes{2}, params);
                L.name = name;
            else
                tf = false;
                L = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net