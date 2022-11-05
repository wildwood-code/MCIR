% VOLTAGE   electronic voltage source
%
% Description:
%   VOLTAGE is a 2-terminal voltage source with optional series resistance
%
% Interface:
%   V = voltage(n1, n2, DC)
%   V.alter(params)
%   V.DC = dc-value
%   V.AC = ac-value
%   V.Rser = series-R
%   V.params = param-card      - alternate to alter
%   V.equations                - generate equations for the source
%   V.list                     - list the source
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef voltage < MCIR.Source
    
    properties (Dependent)
        card
    end
    
    properties (Hidden)
        Rser
    end
    
    properties (Hidden, Dependent)
        params % write-only
    end
    
    methods % interface methods
        
        function obj = voltage(n1, n2, params)
            narginchk(3,3)
            name = 'V@'; % auto-generated
            obj@MCIR.Source(n1, n2, name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
        end
        
        function new = copy(obj)
            parms = struct('DC', obj.DC, 'AC', obj.AC, 'RSER', obj.Rser);
            new = MCIR.voltage(obj.nodes{1}, obj.nodes{2}, parms);
            new.name = obj.name;
            new.tr = obj.tr;  % copy transient info from Source
        end
        
        function str = list(obj)
            str = obj.list_source;
            if obj.Rser>0
                str = str + sprintf(" RSER=%s", MCIR.Device.encode_value(obj.Rser));
            end
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            narginchk(2,Inf)
            obj.stuff_params(MCIR.Device.parse_input(varargin{:}), false);
        end
        
    end % interface methods
    
    methods % get/set methods
        function set.params(obj, parms)
            obj.alter(parms)
        end
        
        function set.Rser(obj, rs)
            rs = MCIR.Device.eval_value(rs);
            [rs,tf] = MCIR.Device.eval_value(rs);
            if ~tf || rs<0.0 || isinf(rs)
                throw(MCIR.voltage.ME_InvalidValue);
            end
            obj.Rser = rs;
        end
        
        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'voltage';
        end
        
        function stuff_params(obj, VS, default)
            VS = stuff_params@MCIR.Source(obj, VS, default);
            if default
                obj.Rser = 0;
            end
            if isfield(VS, 'RSER')
                obj.Rser = VS.RSER;
            end
        end
        
        function eqns = generate_equations(obj)
            name = obj.name;
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.I(name);
            eqns = obj.pack_equations([0 0 1 0;0 0 -1 0;-1 1 obj.Rser 1],v);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('voltage:InvalidValue','Invalid value');
        end
    end
    
    methods (Static, Access=public)
        function [V,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'V', 2);
            if ~isempty(name)
                tf = true;
                V = MCIR.voltage(nodes{1}, nodes{2}, params);
                V.name = name;
            else
                tf = false;
                V = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net