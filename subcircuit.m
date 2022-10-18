% SUBCIRCUIT   instantation of a Subcircuit object
%
% Description:
%   SUBCIRCUIT is multi-pin collection of connected devices
%
% Interface:
%   X = subcircuit(name, sub-name, n1, .., n_n, "p1=v1", ...)
%   X.equations                - generate equations for the subcircuit
%   X.list                     - list the subcircuit
%
% See also:
%   SUBCIRCUIT DEVICE CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef subcircuit < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        params % write-only
    end
    
    properties (Access=protected)
        nodes
        sub
    end
    
    methods % interface methods
        function obj = subcircuit(sub, varargin)
            % get the Subcircuit from its Library
            if nargin<1 || isempty(sub)
                throw(MCIR.subcircuit.ME_InvalidSubcircuitName(sub))
            end
            S = MCIR.Subcircuit.Get(sub);
            if isempty(S)
                throw(MCIR.subcircuit.ME_UnknownSubcircuit(sub))  %ME_UnknownSubcircuit(name)
            end

            % validate the number of input arguments now that we know how many the Subcircuit requires
            n_pins = length(S.pins);
            if iscell(varargin{1})
                args = varargin{1}; % it was probably passed through MCIR.subcircuit.copy
            elseif isstring(varargin{1})
                args = varargin{1}; % it was probably passed through MCIR.Device.SPICE_card
            else
                args = varargin;
            end
            if length(args)<n_pins
                throw(MCIR.subcircuit.ME_PinMismatch(S.name, n_pins))
            end
            
            % generate the base object
            name = 'X@'; % auto-generated
            obj@MCIR.Device(name);

            % attach the Subcircuit object
            obj.sub = S;

            % attach the nodes - nodes are attached to pins in given order
            obj.nodes = cell(1,n_pins);
            for i=1:n_pins
                [~,n] = MCIR.Device.V(args{i});
                obj.nodes{i} = n;
            end

            % TODO: more here - parse params
        end
        
        function new = copy(obj)
            new = MCIR.subcircuit(obj.sub.name, deal(obj.nodes));
        end
        
        function str = list(obj)
            str = sprintf("%s", obj.name);
            for i=1:length(obj.nodes)
                str = str + sprintf(" %s", obj.nodes{i});
            end
            str = str + sprintf(" %s", obj.sub.name);
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin) %#ok<INUSD>
            % alter must be defined because it de-abstracts the object
            throw(MCIR.subcircuit.ME_InvalidSubcircuitOperation('alter'))
        end
        
    end % interface methods
    
    methods % get/set methods

        function card = get.card(obj)
            card = obj.list;
        end
        
    end % set/get methods
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'subcircuit';
        end
        
        function eqns = generate_equations(obj)
            eqns = obj.sub.generate_equations;

            % prepend name for all internal variables I.*(x) and V.+(x)
            % skip all V(x) for now
            eqns = MCIR.Device.set_owner(eqns, obj.name);

            % prepend name for all internal nodes - skip those connected to a pin
            v = eqns.v;
            for i=1:length(v)
                is_match = false;
                tok = regexp(v(i).name, '^V\((.+)\)$', 'tokens');
                if ~isempty(tok) && ~strcmp(tok{1}{1}, '0')
                    n = tok{1}{1};
                    for j=1:length(obj.sub.pins)
                        p = obj.sub.pins{j};
                        if strcmp(p, n)
                            is_match = true;
                            break
                        end
                    end
                    if ~is_match
                        eqns = MCIR.Device.set_owner(eqns, obj.name, n);
                    end
                end
            end

            % unmark equations that were marked as changed
            eqns = MCIR.Device.set_owner(eqns);

            % remap any nodes - mark them if changed to prevent second change
            for i=1:length(obj.nodes)
                eqns = MCIR.Device.remap_node(eqns, obj.sub.pins{i}, obj.nodes{i});
            end

            % unmark any that were marked
            eqns = MCIR.Device.remap_node(eqns);
        end
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidSubcircuitName(name)
            if isempty(name)
                me = MException('subcircuit:InvalidSubcircuitName','Subcircuit name cannot be empty');
            else
                me = MException('subcircuit:InvalidSubcircuitName','Invalid Subcircuit name ''%s''', name);
            end
        end
        function me = ME_UnknownSubcircuit(name)
            me = MException('subcircuit:UnknownSubcircuit','Unknown Subcircuit ''%s''', name);
        end
        function me = ME_InvalidSubcircuitOperation(op)
            me = MException('subcircuit:InvalidSubcircuitOperation','Invalid operation ''%s'' on subcircuit', op);
        end
        function me = ME_PinMismatch(name, n_pins)
            me = MException('subcircuit:PinMismatch','Invalid number of pins for Subcircuit ''%s'' which requires %u pins', name, n_pins);
        end
    end
    
    methods (Static, Access=public)
        function [X,tf] = SPICE(card)
            % TODO: implement card for subcircuit will need to modify
            % SPICE_card to accept new syntax   Xref pins SUBNAME params
            % params will override Circuit.params if present, or pull the
            % default form Circuit.params if not.
            % need to override Device.get_params to implement this behavior
            [name, nodes, params, subname] = MCIR.Device.SPICE_card(card, 'X');
            if ~isempty(name)
                tf = true;
                X = MCIR.subcircuit(subname, nodes);
                X.name = name;
            else
                tf = false;
                X = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net