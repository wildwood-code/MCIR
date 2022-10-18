% CAPACITOR   linear electronic capacitor
%
% Description:
%   CAPACITOR is a linear, 2-terminal capacitor model including series and
%   parallel resistance.
%
% SPICE card syntax:
%   Cref node1 node2 value [Rser=rs Rpar=rp IC=ic]
%
% Interface:
%   C = capacitor(n1, n2, params)
%   C.alter(params)
%   C.C = capacitance
%   C.Rser = series-R
%   C.Rpar = parallel-R
%   C.IC = initial-condition
%   C.params = param-card      - alternate to alter
%   C.equations                - generate equations for the capacitor
%   C.list                     - list the capacitor
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef capacitor < MCIR.Device
    
    properties (Dependent)
        card % read-only
    end
    
    properties (Hidden, Dependent)
        C
        Rser
        Rpar
        IC
        params  % write-only
    end
    
    properties (Access=protected)
        cap
        nodes
        rs
        rp
        ic
    end
    
    methods % interface methods
        function obj = capacitor(n1, n2, params)
            narginchk(3,3)
            name = 'C@'; % auto-generated
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
        end
        
        function new = copy(obj)
            parms = struct('C', obj.cap, 'IC', obj.ic, 'RPAR', obj.rp, 'RSER', obj.rs);
            new = MCIR.capacitor(obj.nodes{1}, obj.nodes{2}, parms);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, MCIR.Device.encode_value(obj.cap));
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
        
        function C = get.C(obj)
            C = obj.cap;
        end
        
        function set.C(obj, value)
            [value,tf] = MCIR.Device.eval_value(value);
            if ~tf || value<=0.0
                throw(MCIR.capacitor.ME_InvalidValue);
            end
            obj.cap = value;
        end
        
        function rser = get.Rser(obj)
            rser = obj.rs;
        end
        
        function set.Rser(obj, rs)
            rs = MCIR.Device.eval_value(rs);
            [rs,tf] = MCIR.Device.eval_value(rs);
            if ~tf || rs<0.0 || isinf(rs)
                throw(MCIR.capacitor.ME_InvalidValue);
            end
            obj.rs = rs;
        end
        
        function rpar = get.Rpar(obj)
            rpar = obj.rp;
        end
        
        function set.Rpar(obj, rp)
            [rp,tf] = MCIR.Device.eval_value(rp);
            if ~tf || rp<=0.0
                throw(MCIR.capacitor.ME_InvalidValue);
            elseif MCIR.Device.is_undef(rp)
                rp = Inf;
            end
            obj.rp = rp;
        end
        
        function IC = get.IC(obj)
            IC = obj.ic;
        end
        
        function set.IC(obj, ic)
            [ic,tf] = MCIR.Device.eval_value(ic);
            if ~tf
                throw(MCIR.capacitor.ME_InvalidValue);
            elseif MCIR.Device.is_undef(ic)
                obj.ic = MCIR.Device.undef;
            else
                obj.ic = ic;
            end
        end
        
        function card = get.card(obj)
            card = obj.list;
        end
 
    end % get/set methods

    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'capacitor';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.cap = MCIR.Device.undef;
                obj.rs = 0;
                obj.rp = Inf;
                obj.ic = MCIR.Device.undef;
            end
            if isfield(P,'C')
                obj.C = P.C;
            elseif isfield(P,'VALUE')
                obj.C = P.VALUE;
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
            v(3).name = MCIR.Device.I(name);
            x.name = MCIR.Device.V(name,'VC');
            x.ic = obj.ic;
            eqns = MCIR.Device.pack_equations([obj.cap 0 0 -1;0 1/obj.rp -1/obj.rp 1;0 -1/obj.rp 1/obj.rp -1;1 -1 1 obj.rs],v,[],[],x);
        end
    end
    
    methods (Access=public)  % TODO: change this to protected
        function value = get_param(obj, name)
            if strcmpi(name, 'C') || strcmpi(name, [obj.name '.C'])
                value = obj.cap;
            elseif strcmpi(name, 'Rpar') || strcmpi(name, [obj.name '.Rpar'])
                value = obj.rp;
            elseif strcmpi(name, 'Rser') || strcmpi(name, [obj.name '.Rser'])
                value = obj.rs;
            elseif strcmpi(name, 'IC') || strcmpi(name, [obj.name '.IC'])
                value = obj.ic;
            else
                value = [];
            end
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('capacitor:InvalidValue','Invalid capacitance');
        end
    end % exceptions
    
    methods (Static, Access=public)
        function [C,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'C', 2);
            if ~isempty(name)
                tf = true;
                C = MCIR.capacitor(nodes{1}, nodes{2}, params);
                C.name = name;
            else
                tf = false;
                C = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net