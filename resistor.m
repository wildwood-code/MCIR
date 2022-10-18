% RESISTOR   linear electronic resistor
%
% Description:
%   RESISTOR is a linear, 2-terminal resistor.
%
% Interface:
%   R = resistor(n1, n2, value)
%   R.alter(value)
%   R.R = resistance
%   R.params = param-card      - alternate to alter
%   R.equations                - generate equations for the resistor
%   R.list                     - list the resistor
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef resistor < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        R
        params % write-only
    end
    
    properties (Access=protected)
        Rval
        nodes
    end
    
    methods % interface methods
        function obj = resistor(n1, n2, params)
            narginchk(3,3)
            name = 'R@'; % auto-generated
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
        end
        
        function new = copy(obj)
            new = MCIR.resistor(obj.nodes{1}, obj.nodes{2}, obj.Rval);
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s %s", obj.name, obj.nodes{1}, obj.nodes{2}, MCIR.Device.encode_value(obj.Rval));
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            narginchk(2,2)
            obj.stuff_params(MCIR.Device.parse_input(varargin{:}), false)
        end
        
    end % interface methods
    
    methods % get/set methods
        
        function set.params(obj, parms)
            obj.alter(parms)
        end
        
        function R = get.R(obj)
            R = obj.Rval;
        end
        
        function set.R(obj, value)
            [value,tf] = MCIR.Device.eval_value(value);
            if ~tf || value<=0.0
                throw(MCIR.resistor.ME_InvalidValue);
            end
            obj.Rval = value;
        end

        function card = get.card(obj)
            card = obj.list;
        end
        
    end % set/get methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'resistor';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.Rval = MCIR.Device.undef;
            end
            if isfield(P,'R')
                obj.R = P.R;
            elseif isfield(P,'VALUE')
                obj.R = P.VALUE;
            end
        end
        
        function eqns = generate_equations(obj)
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            eqns = MCIR.Device.pack_equations([1 -1;-1 1]/obj.Rval,v);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('resistor:InvalidValue','Invalid resistance');
        end
    end

    methods (Access=public)  % TODO: change this to protected - add for all other components
        function value = get_param(obj, name)
            if strcmpi(name, 'R') || strcmpi(name, [obj.name '.R'])
                value = obj.Rval;
            else
                value = [];
            end
        end
    end
    
        
    methods (Static, Access=public)
        function [R,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'R', 2);
            if ~isempty(name)
                tf = true;
                R = MCIR.resistor(nodes{1}, nodes{2}, params);
                R.name = name;
            else
                tf = false;
                R = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net