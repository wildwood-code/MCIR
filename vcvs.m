% vcvs   voltage-controlled voltage source
%
% Description:
%   vcvs is a voltage-controlled voltage source
%
% Interface:
%   E = vcvs(n1, n2, nc1, nc2, gain)
%   E.alter(params)
%   E.gain = gain
%   E.params = param-card      - alternate to alter
%   E.equations                - generate equations for the device
%   E.list                     - list the device
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCCS CCVS CCCS NULLOR

classdef vcvs < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        gain
        params % write-only
    end
    
    properties (Access=protected)
        int_gain
        nodes
    end
    
    methods % interface methods
        
        function obj = vcvs(n1, n2, nc1, nc2, params)
            narginchk(5,5)
            name = 'E@'; % auto-generated
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            [~,nc1] = MCIR.Device.V(nc1);
            [~,nc2] = MCIR.Device.V(nc2);
            obj.nodes = cell(1,4);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
            obj.nodes{3} = nc1;
            obj.nodes{4} = nc2;
        end
        
        function new = copy(obj)
            new = MCIR.vcvs(obj.nodes{1}, obj.nodes{2}, obj.nodes{3}, obj.nodes{4}, obj.int_gain);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, obj.nodes{3}, obj.nodes{4}, MCIR.Device.encode_value(obj.int_gain));
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, params)
            narginchk(2,2)
            obj.stuff_params(MCIR.Device.parse_input(params), false);
        end
        
    end % interface methods
    
    methods % get/set methods
        function set.params(obj, parms)
            obj.alter(parms)
        end
        
        function set.gain(obj, gain)
            [gain,tf] = MCIR.Device.eval_value(gain);
            if ~tf
                throw(MCIR.vcvs.ME_InvalidValue)
            elseif MCIR.Device.is_undef(gain)
                gain = 1;
            end
            obj.int_gain = gain;
        end
        
        function gain = get.gain(obj)
            gain = obj.int_gain;
        end
        
        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'vcvs';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.int_gain = 1;
            end
            if isfield(P,'E')
                obj.gain = P.E;
            elseif isfield(P,'VALUE')
                obj.gain = P.VALUE;
            end
        end
        
        function eqns = generate_equations(obj)
            name = obj.name;
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.V(obj.nodes{3});
            v(4).name = MCIR.Device.V(obj.nodes{4});
            v(5).name = MCIR.Device.I(name);
            eqns = obj.pack_equations([0 0 0 0 1;0 0 0 0 -1;0 0 0 0 0;0 0 0 0 0;1 -1 -obj.int_gain obj.int_gain 0],v);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('vcvs:InvalidValue','Invalid gain');
        end
    end
    
    methods (Static, Access=public)
        function [E,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'E', 4);
            if ~isempty(name)
                tf = true;
                E = MCIR.vcvs(nodes{1}, nodes{2}, nodes{3}, nodes{4}, params);
                E.name = name;
            else
                tf = false;
                E = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net