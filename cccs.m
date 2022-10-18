% cccs   current-controlled current source
%
% Description:
%   cccs is a current-controlled current source
%
% Interface:
%   F = cccs(n1, n2, Vname, gain)
%   F.alter(params)
%   F.gain = gain
%   F.params = param-card      - alternate to alter
%   F.equations                - generate equations for the device
%   F.list                     - list the device
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS NULLOR

classdef cccs < MCIR.Device
    
    properties (Dependent)
        card % read-only
    end
    
    properties (Hidden, Dependent)
        gain
        params % write-only
    end
    
    properties (Access=protected)
        int_gain
        nodes
        ctrl
    end
    
    methods % interface methods
        
        function obj = cccs(n1, n2, ctrl, params)
            narginchk(4,4)
            name = 'F@'; % auto-generated
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            [~,ctrl] = MCIR.Device.I(ctrl);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
            obj.ctrl = ctrl;
        end
        
        function new = copy(obj)
            new = MCIR.cccs(obj.nodes{1}, obj.nodes{2}, obj.ctrl, obj.int_gain);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, obj.ctrl, MCIR.Device.encode_value(obj.int_gain));
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
                throw(MCIR.cccs.ME_InvalidValue)
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
            type = 'cccs';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.int_gain = 1;
            end
            if isfield(P,'F')
                obj.gain = P.F;
            elseif isfield(P,'VALUE')
                obj.gain = P.VALUE;
            end
        end
        
        function eqns = generate_equations(obj)
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.I(obj.ctrl);
            eqns = obj.pack_equations([0 0 obj.int_gain;0 0 -obj.int_gain;0 0 0],v);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('cccs:InvalidValue','Invalid gain');
        end
    end
    
    methods (Static, Access=public)
        function [F,tf] = SPICE(card)
            [name, nodes, params, refs] = MCIR.Device.SPICE_card(card, 'F', 2, 'V');
            if ~isempty(name)
                tf = true;
                F = MCIR.cccs(nodes{1}, nodes{2}, refs{1}, params);
                F.name = name;
            else
                tf = false;
                F = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net