% vccs   voltage-controlled current source
%
% Description:
%   vccs is a voltage-controlled current source
%
% Interface:
%   G = vccs(n1, n2, nc1, nc2, gain)
%   G.alter(params)
%   G.gain = gain
%   G.params = param-card      - alternate to alter
%   G.equations                - generate equations for the device
%   G.list                     - list the device
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS CCVS CCCS NULLOR

classdef vccs < MCIR.Device
    
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
        
        function obj = vccs(n1, n2, nc1, nc2, params)
            narginchk(5,5)
            name = 'G@'; % auto-generated
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
            new = MCIR.vccs(obj.nodes{1}, obj.nodes{2}, obj.nodes{3}, obj.nodes{4}, obj.int_gain);
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
                throw(MCIR.vccs.ME_InvalidValue)
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
            type = 'vccs';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.int_gain = 1;
            end
            if isfield(P,'G')
                obj.gain = P.G;
            elseif isfield(P,'VALUE')
                obj.gain = P.VALUE;
            end
        end
        
        function eqns = generate_equations(obj)
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.V(obj.nodes{3});
            v(4).name = MCIR.Device.V(obj.nodes{4});
            eqns = obj.pack_equations([0 0 obj.int_gain -obj.int_gain;0 0 -obj.int_gain obj.int_gain;0 0 0 0;0 0 0 0],v);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('vccs:InvalidValue','Invalid gain');
        end
    end
    
    methods (Static, Access=public)
        function [G,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'G', 4);
            if ~isempty(name)
                tf = true;
                G = MCIR.vccs(nodes{1}, nodes{2}, nodes{3}, nodes{4}, params);
                G.name = name;
            else
                tf = false;
                G = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net