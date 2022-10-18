% CURRENT   electronic current source
%
% Description:
%   CURRENT is a 2-terminal current source with optional parallel resistance
%
% Interface:
%   I = current(n1, n2, DC)
%   I.alter(params)
%   I.DC = dc-value
%   I.AC = ac-value
%   I.Rpar = parallel-R
%   I.params = param-card      - alternate to alter
%   I.equations                - generate equations for the source
%   I.list                     - list the source
%
% See also:
%   DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE VCVS VCCS CCVS CCCS NULLOR

classdef current < MCIR.Source
    
    properties (Dependent)
        card
    end
    
    properties (Hidden)
        Rpar
    end
    
    properties (Hidden, Dependent)
        params % write-only
    end
    
    methods % interface methods
        
        function obj = current(n1, n2, params)
            narginchk(3,3)
            name = 'I@'; % auto-generated
            obj@MCIR.Source(n1, n2, name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
        end
        
        function new = copy(obj)
            parms = struct('DC', obj.DC, 'AC', obj.AC, 'RPAR', obj.Rpar);
            new = MCIR.current(obj.nodes{1}, obj.nodes{2}, parms);
            new.name = obj.name;
        end
         
        function str = list(obj)
            str = obj.list_source;
            if ~isinf(obj.Rpar)
                str = str + sprintf(" RPAR=%s", MCIR.Device.encode_value(obj.Rpar));
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
        
        function set.params(obj,parms)
            obj.alter(parms)
        end
        
        function set.Rpar(obj, rp)
            [rp,tf] = MCIR.Device.eval_value(rp);
            if ~tf || rp<=0.0
                throw(MCIR.current.ME_InvalidValue);
            elseif MCIR.Device.is_undef(rp)
                rp = Inf;
            end
            obj.Rpar = rp;
        end
        
        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'current';
        end
        
        function stuff_params(obj, IS, default)
            IS = stuff_params@MCIR.Source(obj, IS, default);
            if default
                obj.Rpar = Inf;
            end
            if isfield(IS, 'RPAR')
                obj.Rpar = IS.RPAR;
            end
        end

        function eqns = generate_equations(obj)
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            eqns = obj.pack_equations([1/obj.Rpar -1/obj.Rpar 1 ;-1/obj.Rpar 1/obj.Rpar -1],v);
        end
    end
    
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('current:InvalidValue','Invalid value');
        end
    end
    
    methods (Static, Access=public)
        function [I,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'I', 2);
            if ~isempty(name)
                tf = true;
                I = MCIR.current(nodes{1}, nodes{2}, params);
                I.name = name;
            else
                tf = false;
                I = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net