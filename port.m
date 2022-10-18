% PORT   inport|output used for port analysis
%
% Description:
%   PORT is a 2-pin device that may act as a source or a load. It is used
%   for port analysis.
%
% Interface:
%   PORT = port(n1, n2, params)
%   PORT.alter(value)
%   PORT.port = 'inport'|'outport'|'open'|'short'
%   PORT.R = resistance
%   PORT.params = param-card      - alternate to alter
%   PORT.equations                - generate equations for the port
%   PORT.list                     - list the port
%
% See also:
%   DEVICE CIRCUIT PROBE
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef port < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        Port
        R
        params % write-only
        Z0 % write-only
    end
    
    properties (Access=protected)
        Rval
        port_type  % 0==out, 1==in, 2=open, 3=short
        nodes
    end
    
    methods % interface methods
        function obj = port(n1, n2, params)
            narginchk(3,4)
            name = 'PORT@'; % auto-generated
            obj@MCIR.Device(name);
            obj.stuff_params(MCIR.Device.parse_input(params), true)
            [~,n1] = MCIR.Device.V(n1);
            [~,n2] = MCIR.Device.V(n2);
            obj.nodes = cell(1,2);
            obj.nodes{1} = n1;
            obj.nodes{2} = n2;
        end
        
        function new = copy(obj)
            new = MCIR.port(obj.nodes{1}, obj.nodes{2}, obj.Rval);
            new.port_type = obj.port_type;
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s %s PORT=%s R=%s", obj.name, obj.nodes{1}, obj.nodes{2}, obj.Port, MCIR.Device.encode_value(obj.Rval));
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            narginchk(2,3)
            obj.stuff_params(MCIR.Device.parse_input(varargin{:}), false)
        end
        
        function [vp,ip,vpe,ipe] = get_outputs(obj)
            name = obj.name;
            ip = [name '.IP'];
            ipe = MCIR.Device.I(name,'IP');
            vp = [name '.VP'];
            vpe = MCIR.Device.V(name,'VP');            
        end
        
    end % interface methods
    
    methods % get/set methods
        
        function set.params(obj, parms)
            obj.alter(parms)
        end
        
        function R = get.R(obj)
            R = obj.Rval;
        end
        
        function set.Z0(obj,value)
            obj.R = value;
        end
        
        function set.R(obj, value)
            value = MCIR.Device.eval_value(value);
            [value,tf] = MCIR.Device.eval_value(value);
            if ~tf || value<0.0
                throw(MCIR.port.ME_InvalidValue);
            else
                obj.Rval = value;
            end
        end
        
        function ptype = get.Port(obj)
            switch obj.port_type
                case 0
                    ptype = 'OUTPORT';
                case 1
                    ptype = 'INPORT';
                case 2
                    ptype = 'OPEN';
                case 3
                    ptype = 'SHORT';
            end
        end
        
        function set.Port(obj,port)
            if regexpi(port, '^(?:OUT|OUTPUT|OUTPORT)$')
                obj.port_type = 0;
            elseif regexpi(port, '^(?:IN|INPUT|INPORT)$')
                obj.port_type = 1;
            elseif regexpi(port, '^OPEN$')
                obj.port_type = 2;
            elseif regexpi(port, '^SHORT$')
                obj.port_type = 3;
            else
                throw(MCIR.port.ME_InvalidportType)
            end
        end

        function card = get.card(obj)
            card = obj.list;
        end
        
    end % set/get methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'port';
        end
        
        function stuff_params(obj, P, default)
            if default
                obj.Rval = 0.0;
                obj.port_type = 2; % open port
            end
            % use the set.__ methods to do proper conversion and checking
            if isfield(P,'R')
                obj.R = P.R;
            elseif isfield(P,'Z')
                obj.R = P.Z;
            elseif isfield(P,'Z0')
                obj.R = P.Z0;
            elseif isfield(P,'VALUE')
                obj.R = P.VALUE;
            end
            if isfield(P,'PORT')
                obj.Port = P.PORT;
            elseif isfield(P,'TYPE')
                obj.Port = P.TYPE;
            elseif isfield(P,'IN')||isfield(P,'INPORT')||isfield(P,'INPUT')
                obj.Port = 'IN';
            elseif isfield(P,'OUT')||isfield(P,'OUTPORT')||isfield(P,'OUTPUT')
                obj.Port = 'OUT';
            elseif isfield(P,'OPEN')
                obj.Port = 'OPEN';
            elseif isfield(P,'SHORT')
                obj.Port = 'SHORT';
            end
        end
        
        function eqns = generate_equations(obj)
            name = obj.name;
            [vp,ip,vpe,ipe] = get_outputs(obj);
            y = struct('name', {}, 'expr', {});
            y(1).name = ip;
            y(1).expr = ipe;
            y(2).name = vp;
            y(2).expr = vpe;
            v(1).name = MCIR.Device.V(obj.nodes{1});
            v(2).name = MCIR.Device.V(obj.nodes{2});
            v(3).name = MCIR.Device.I(name);
            u = struct('name', 'AC', 'type', 'AC', 'params', [], 'DC', []);
            Pn = [0 0 1 0;0 0 -1 0];
            Py = [0 0 -1 0;1 -1 0 0];
            switch obj.port_type
                case 0 % output
                    % output port is open if R==0 or R if R~=0
                    if obj.Rval==0
                        Pi = [0 0 1 0];
                    else
                        Pi = [1 -1 -obj.Rval 0];
                    end
                case 1 % input
                    Pi = [1 -1 -obj.Rval -1];
                case 2 % open
                    Pi = [0 0 1 0];
                case 3 % short
                    Pi = [1 -1 0 0];
            end
            P = vertcat(Pn, Pi, Py);
            eqns = MCIR.Device.pack_equations(P,v,u,y);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidValue
            me = MException('port:InvalidValue','Invalid resistance');
        end
        function me = ME_InvalidportType
            me = MException('port:InvalidportType','Invalid port type - only in and out possible');
        end
    end
    
    methods (Static, Access=public)
        function [PORT,tf] = SPICE(card)
            [name, nodes, params, ~] = MCIR.Device.SPICE_card(card, 'PORT', 2);
            if ~isempty(name)
                tf = true;
                PORT = MCIR.port(nodes{1}, nodes{2}, params);
                PORT.name = name;
            else
                tf = false;
                PORT = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net