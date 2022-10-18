% SUBCIRCUIT   linear, lumped, time-invariant (LLTI) electronic sub-circuit
%
% Description:
%   SUBCIRCUIT implements a set of connected Devices which may itself be
%   connected within a Circuit or another Subcircuit. The Subcircuit is
%   built by adding devices described with SPICE-like cards (a subset
%   of LLTI SPICE devices are implemented).
%
%   A SUBCIRCUIT is derived form Circuit, and thus inherits all of its
%   methods and properties, but adds some new methods, properties, and
%   cards. In particular, building the SUBCIRCUIT follows the same syntax
%   as for building a Circuit. However, Circuit analysis functions will
%   probably fail for a SUBCIRCUIT.
%
% Subcircuit construction:
%   X = SUBCIRCUIT(name)     - constructor - name must be a valid circuit name
%
% Properties:
%   pins      - pins for the subcircuit. Pins connect it to another Circuit
%
% Static Methods:
%   Library   - show a list of defined subcircuits and number of pins for each
%   Get       - get a defined subcircuit from the library
%
% Building the Subcircuit:
%   SCname = Subcircuit('FOO');
%   SCname < "PINS in out com"
%   SCname < "R1 in x 10k"
%   SCname < "R2 x out 1k"
%   SCname < "R3 x com 100k"
%   SCname < "C1 x com 100p"
%
% Attaching a Subcircuit within a Circuit or another Subcircuit:
%   Subcircuits are referenced from a static library by name. Subcircuits
%   are instantiated into a parent using a card beginning with 'X'. The
%   nodes list follows the reference designator and must match the declared
%   pins in number and order. The name defined when the Subcircuit was
%   created is used to reference the Subcircuit from the library.
%
%   circuit < "X1 1 2 0 FOO"
%   circuit < "X2 2 3 0 FOO"
%
% Circuit name:
%   must start with a letter and contain only letters, numbers, and underscore
%   case-insensitive
%
% See also:
%   CIRCUIT   DEVICE

classdef Subcircuit < MCIR.Circuit
    
    properties (Constant, Hidden, Access=private)
        Subs = MCIR.SubcircuitPool
    end
    
    properties (Dependent)
        pins
    end
    
    properties (Access=private)
        sc_pins
    end
    
    methods (Static)
        
        function obj = Get(name)
            % GET  gets a Subcircuit from the static library
            %
            %   Subcircuit.Get('name')
            narginchk(1,1)
            obj = MCIR.Subcircuit.Library(name);
        end
        
        function obj = Library(name)
            % LIBRARY  gets a Subcircuit from the static library or display a list
            %          of Subcircuits in the static library
            %
            %   Subcircuit.Library           % list the library contents
            %   Subcircuit.Library('name')   % get the subcircuit from the library
            if nargin<1
                name = [];
            end
            name = upper(name);
            if isempty(name)
                % list all defined subcircuits
                str = "";
                
                for i=1:length(MCIR.Subcircuit.Subs.Subs)
                    sub = MCIR.Subcircuit.Subs.Subs{i};
                    npins = length(sub.pins);
                    if i==1
                        str = str + sprintf("%s(%u)", sub.name, npins);
                    else
                        str = str + sprintf(", %s(%u)", sub.name, npins);
                    end
                end

                if nargout>0
                    obj = str;
                else
                    fprintf("%s\n", str)
                end
            else
                % fetch a reference to the named subcircuit
                obj = [];
                for i=1:length(MCIR.Subcircuit.Subs.Subs)
                    sub = MCIR.Subcircuit.Subs.Subs{i};
                    if strcmp(name, sub.name)
                        obj = sub;
                        break
                    end
                end
            end
        end
        
    end
    
    methods
        
        function obj = Subcircuit(name)
            % SUBCIRCUIT  Constructs a Subcircuit and adds it to the static library
            %
            %   S = SUBCIRCUIT('name')
            %     name must begin with a letter and contain only letters, numbers, and underscore
            %     name is case-insensitive-
            
            % validate that the subcircuit name is valid
            name = upper(name);
            if ~regexp(name, '^[A-Z][A-Z0-9_]+$')
                throw(MCIR.Circuit.ME_InvalidName)
            end
            obj@MCIR.Circuit(name);

            % check for existing Subcircuit in pool
            exists_ref = [];
            for sub=obj.Subs.Subs
                if strcmp(name, sub{1}.name)
                    exists_ref = sub;
                    break
                end
            end
            if isempty(exists_ref)
                % create new reference at end of list
                obj.Subs.Subs{end+1} = obj;
            else
                % overwrite existing reference
                exists_ref = obj; %#ok<NASGU>
            end

            % empty pins
            obj.clear_pins
        end

        function ref = add(obj, card)
            % ADD   Adds a device to the subcircuit
            %
            %   obj.ADD(card)
            %   ref = obj.ADD(card).
            %
            %   Adds all of the cards normally available to a Circuit, but
            %   includes the following specific to a Subcircuit:
            %     PINref p1 ... pn
            %   
            %   Note: PINref is normally just 'PINS' and contains all pin
            %   definitions for the Subcircuit.
            %
            % See also:
            %   MCIR.CIRCUIT.ADD
            
            if MCIR.Device.is_charstr(card)
                match = regexpi(card, "^\s*PINs?\s+(.+?)\s*$", 'tokens');
                if ~isempty(match)
                    % add each pin to the list (unless it is already there)
                    plist = split(match{1}, ' ');
                    for j=1:length(plist)
                        p = upper(plist{j});
                        found = false;
                        for i=1:length(obj.sc_pins)
                            l = obj.sc_pins{i};
                            if strcmp(p, l)
                                found = true;
                                break
                            end
                        end
                        if ~found
                            obj.sc_pins{end+1} = p;
                        end
                    end
                else
                    % otherwise just pass it on to Circuit
                    ref = add@MCIR.Circuit(obj, card);
                end
            elseif isa(card,'MCIR.Device')
                str = card.list;
                ref = add@MCIR.Circuit(obj, str);
            else
                throw(MCIR.Circuit.ME_InvalidCard)
            end
            if nargout==0
                clear ref
            end
        end

        function objout = plus(obj, item)
            % PLUS +   alternative syntax for add
            % See also: ADD
            obj.add(item)
            if nargout>0
                objout = obj;
            end
        end

        function objout = le(obj, item)
            % LE <=   alternative syntax for add
            % See also: ADD
            obj.add(item)
            if nargout>0
                objout = obj;
            end
        end

        function objout = lt(obj, item)
            % LT <   alternative syntax for add
            % See also: ADD
            obj.add(item)
            if nargout>0
                objout = obj;
            end
        end
        
        % TODO: alter method for PINS and PARAMS, and the shorthands > etc

        function str = list(obj)
            % LIST   list the Subcircuit to the output or a string
            %
            %   obj.LIST         list the circuit to the output
            %   str = obj.LIST   list the circuit to a string
            str = sprintf("SUBCIRCUIT %s(", obj.name);
            for i=1:length(obj.sc_pins)
                p = obj.sc_pins{i};
                if i~=1
                    str = str + ", ";
                end
                str = str + sprintf("%s", p);
            end
            str = str + ")" + newline;
            str = str + list@MCIR.Circuit(obj, true); % print Circuit without header
            str = str + sprintf("\nEND SUBCIRCUIT %s", obj.name);
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end

    end
    
    methods (Access={?MCIR.Circuit})
        
        function clear_pins(obj)
            obj.sc_pins = {};
        end

    end

    methods (Access=protected)
        
        function eqns = generate_equations(obj)
            % generate the usual circuit equations, but skip any
            % autogenerated output variables
            eqns = obj.generate_equations_ex(true);
        end
        
    end

    methods % get/set methods
        
        function pins = get.pins(obj)
            pins = obj.sc_pins;
        end

    end
    
    methods (Access=protected)
        
        function type = get_type(~)
            type = 'Subcircuit';
        end
        
    end
    
end

% TODO:
% add params to all devices
% every device would have a parent device (except the top-level circuit
% which would have an empty parent [])
% the eval_value() function would work its way up through the parents to
% find a device with the value assigned
%   this may not be a bad idea...
%   Device could declare a function get_param which may be overridden (or
%   by default it returns []). Circuit could override, then Subcircuit.
%   The other Devices would override, but just return their normal
%   parameters (defined in the class) when reference by name:
%     examples:
%       get_param(r_object, 'R') would return the resistance
%       get_param(cir_object, 'param1') would return PARAM1 if defined
%       get_param(cir_object, 'R1.R') would return the resistance of R1 if R1 exists in the cir_object
%       get_param(sc_object, 'k') would return the value of K if defined
%       get_param(sc_object, 'R2.R') would return the resistance of R2 if R2 exists in the sc_object
%
%   eval_value() could do simple math and use params, if enclosed in {}
%       eval_value('{2*R2.R}')
%
% params can simply add an uppercase member to the object, but then it
% would be difficult to clear (a list of the params could be used)
% This approach would be consistent with the existing devices (e.g. R.R = resistance)
% rmfield would be used to remove the fields
% !!!! this won't work - cannot simply add fields to a class, only a struct

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net