% CIRCUIT   linear, lumped, time-invariant (LLTI) electronic circuit
%
% Description:
%   CIRCUIT implements a set of connected Devices. The Circuit is built by
%   adding devices described with SPICE-like cards (a subset of LLTI SPICE
%   devices are implemented).
%
% Circuit construction:
%   X = Circuit(name)        - constructor
%   X.name                   - name
%   X.add(card)              - adding a device to the circuit
%   X+card                   - alternate to add(.)
%   X<card                   - alternate to add(.)
%   X<=card                  - alternate to add(.)
%   X.remove(name)           - removing a device from the circuit
%   X-name                   - alternate to remove(name)
%   X.alter(card)            - replace a device (full alter)
%   X>card                   - alternate to alter(card)
%   X>=card                  - alternate to alter(card)
%   X~=card                  - alternate to alter(card)
%   X.alter(name, params...) - alter parameters/value of a device
%   X.list                   - list all devices in the circuit
%   X.clear                  - clear the circuit
%   X.copy                   - generate a separate copy of the circuit
%   X(ref)                   - copy of ref
%   X{ref}                   - handle to ref (allows direct mods)
%
% Analysis:
%   X.equations              - generate equations for the circuit
%   X.ss                     - generate a state-space system for the circuit
%   X.op                     - operating point solution
%   X.dc                     - alternative to op
%   X.fr                     - frequency response
%   X.ac                     - alternative to fr
%   X.tr                     - transient response
%   X.bode                   - bode response/plot
%   X.bodemag                - bode magnitude plot
%   X.freqresp               - frequency response
%   X.gen_stim               - generate stimulus vector for 'dc', 'ac', or 'tr'
%
% See also:
%   DEVICE PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef Circuit < MCIR.Device
    
    properties (Dependent) % visible read-only properties
        circuit_name
        components
        params
    end
    
    properties (Hidden, Dependent)
        x
        v
        u
        y
    end
    
    properties (Access=private)
        devices      % cell array of devices in the circuit
        genref       % struct with next num in auto-referencing
        cir_ss       % empty when not valid
        cir_x0       % empty when not valid
        cir_eqns     % empty when not valid
        cir_params   % cell array of parameter pairs struct('PARAM', [], 'VALUE', [])
    end
    
    methods % interface methods
        % models and analyses
        [SYS,x0] = ss(obj)
        [dBY,argY,f] = bode(obj,varargin)
        bodemag(obj,varargin)
        [H,W] = freqresp(obj,varargin)
        varargout = gen_stim(obj,varargin)
        [y,t] = tr(obj,varargin)
        [H,F] = fr(obj,varargin)
        [H,F] = ac(obj,varargin) % alternate syntax for fr()
        P = net(obj,varargin)
        Y = op(obj)
        Y = dc(obj) % alternate syntax for op()
        new = copy(obj)
        
        function obj = Circuit(name)
            % CIRCUIT        construct empty circuit
            % CIRCUIT(name)  construct empty circuit with given name
            if nargin<1
                name = "X@";
            end
            obj@MCIR.Device(name);
            obj.devices = {};
            obj.clear_params
            obj.genref = struct;
            obj.invalidate_ss
        end
        
        function clear(obj, confirm)
            % CLEAR   clear the circuit object
            %   obj.CLEAR('Y')     clear without prompting
            %   obj.CLEAR('YES')   clear without prompting
            %   obj.CLEAR          prompt to confirm before clearing
            if nargin>1
                if ischar(confirm) || isstring(confirm)
                    if regexpi(confirm, '^y(?:es)?$')
                        confirm = true;
                    else
                        confirm = false;
                    end
                else
                    confirm = false;
                end
            else
                % confirm by prompt
                reply = input('Clear the circuit? Y/N [N]:', 's');
                if regexpi(reply, '^y(?:es)?$')
                    confirm = true;
                else
                    confirm = false;
                end
            end
            if confirm
                % clear all devices
                obj.devices = {};
                obj.genref = struct;
                obj.invalidate_ss
                obj.clear_params
                
                % if a Subcircuit, clear its pins as well
                if strcmp(obj.type, 'Subcircuit')
                    obj.clear_pins
                end
            end
        end
        
        function ref = add(obj, card)
            % ADD  Add a card to the circuit
            %   ref = obj.ADD(card)
            %
            %   ref is a reference to the device added, not the circuit
            %   to which it was added, allowing the device to be modified
            %   later
            %
            %   ADD may be done using operators: + < <=
            %   when using operators to add components, a reference to the
            %   circuit is returned (not the device that was added),
            %   allowing syntax such as:
            %     cir = cir + card
            %   if the device reference is needed, call ADD directly
            %
            %   SPICE comments are ignored:
            %     lines starting with * are full-line comments
            %     anything after ; is a comment
            if MCIR.Device.is_charstr(card)
                if obj.process_params(card)
                    ref = [];
                else
                    % it was not a PARAMs card, so pass it on to see if it
                    % is a Device card
                    [dev,isvalid,isblank] = MCIR.Device.SPICE(card);
                    if isblank
                        ref = [];
                    elseif isvalid
                        % generate auto-number if name has '@'
                        if contains(dev.name,'@')
                            dev.name = obj.generate_autoref(dev.name);
                        end
                        idx = obj.find_ref(dev.name);
                        if isempty(idx)
                            obj.devices{end+1} = dev;
                            obj.invalidate_ss
                        else
                            throw(MCIR.Circuit.ME_RefExists(dev.name))
                        end
                        
                        % attach Coupling devices to Circuit object
                        if isa(dev, 'MCIR.coupling')
                            dev.attach_circuit(obj)
                        end
                        
                        ref = dev.name;
                    else
                        throw(MCIR.Circuit.ME_InvalidCard)
                    end
                end
            elseif isa(card,'MCIR.Device')
                str = card.list;
                ref = obj.add(str);
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

        function remove(obj, name)
            % REMOVE   removes device with given name
            %   obj.REMOVE(name)   removes device with given name
            %
            %   REMOVE may be done using operator: -
            %   example:
            %     cir - "R1"      % remove R1
            if MCIR.Device.is_charstr(name)
                idx = obj.find_ref(name);
                if ~isempty(idx)
                    % delete it
                    obj.devices(idx) = [];
                    obj.invalidate_ss
                else
                    throw(MCIR.Circuit.ME_RefMissing(name))
                end
            else
                throw(MCIR.Circuit.ME_InvalidName)
            end
        end
        
        function objout = minus(obj, name)
            % -   alternative syntax for remove
            % See also: REMOVE
            obj.remove(name)
            if nargout>0
                objout = obj;
            end
        end
        
        function alter(obj, varargin)
            % ALTER   alter a component, replacing it with a new card or changing value(s)
            %   obj.ALTER(card)             replace with a new card
            %   obj.ALTER(name, params...)  alter parameters of the named device
            %
            %   ALTER may be done using operators: > >= ~=
            %   example:
            %     cir > "R1 1 0 20k"   % replaces device R1 with the new card
            narginchk(2,Inf)
            if nargin==2
                if MCIR.Device.is_charstr(varargin{1})
                    [dev,tf] = MCIR.Device.SPICE(varargin{1});
                    if tf
                        name = dev.name;
                        idx = obj.find_ref(name);
                        if ~isempty(idx)
                            obj.devices{idx} = dev;
                            obj.invalidate_ss
                        else
                            throw(MCIR.Circuit.ME_RefMissing(name))
                        end
                    else
                        throw(MCIR.Circuit.ME_InvalidCard)
                    end
                else
                    throw(MCIR.Circuit.ME_InvalidName)
                end
            else
                name = varargin{1};
                if MCIR.Device.is_charstr(name)
                    idx = obj.find_ref(name);
                    if ~isempty(idx)
                        obj.devices{idx}.alter(varargin{2:end});
                        obj.invalidate_ss
                    else
                        throw(MCIR.Circuit.ME_RefMissing(name))
                    end
                else
                    throw(MCIR.Circuit.ME_InvalidName)
                end
            end
        end

        function objout = gt(obj, item)
            obj.alter(item)
            if nargout>0
                objout = obj;
            end
        end
        
        function objout = ne(obj, item)
            obj.alter(item)
            if nargout>0
                objout = obj;
            end
        end
        
        function objout = ge(obj, item)
            obj.alter(item)
            if nargout>0
                objout = obj;
            end
        end

        function str = list(obj, omit_name)
            % LIST   list the circuit to the output or a string
            %   obj.LIST         list the circuit to the output
            %   str = obj.LIST   list the circuit to a string
            if nargin<2
                omit_name = false;
            end
            if ~omit_name
                str = sprintf("* %s\n", obj.name);
            else
                str = "";
            end
            if ~isempty(obj.cir_params)
                str = str + "PARAMS";
                for i=1:length(obj.cir_params)
                    p = obj.cir_params(i);
                    str = str + sprintf(" %s=%s", p.PARAM, MCIR.Device.encode_value(p.VALUE));
                end
                str = str + newline;
            end
%            if ~isempty(obj.devices)
%                str = str + newline;
%            end
            if isempty(obj.devices) && isempty(obj.cir_params)
                str = str + "<EMPTY>";
            else
                n = length(obj.devices);
                for i=1:n
                    c = obj.devices{i};
                    str = str + c.list;
                    if i<n
                        str = str + newline;
                    end
                end
            end
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
    end % interface methods
    
    methods % get/set methods
        function count = get.components(obj)
            count = length(obj.devices);
        end
        
        function n = get.circuit_name(obj)
            n = obj.name;
        end
        
        function set.circuit_name(obj, n)
            obj.name = n;
        end
        
        function x = get.x(obj)
            eqns = obj.generate_equations;
            x = eqns.x;
        end
        
        function v = get.v(obj)
            eqns = obj.generate_equations;
            v = eqns.v;
        end
        
        function u = get.u(obj)
            eqns = obj.generate_equations;
            u = eqns.u;
        end
        
        function y = get.y(obj)
            eqns = obj.generate_equations;
            y = eqns.y;
        end
        
        function params = get.params(obj)
            params = obj.cir_params;
        end
        
    end % get/set methods
    
    methods (Access=?MCIR.Coupling)
        function dev = get_device(obj, ref)
            % for internal use only (needed for Coupling to get L values)
            % device should not be modified
            idx = obj.find_ref(ref);
            if ~isempty(idx)
                dev = obj.devices(idx);
            else
                dev = [];
            end
        end
    end
    
    methods (Access=public)  % TODO: change this to protected
        function value = get_param(obj, name)
            % check if it is a param from a ref-designator in this circuit
            % if not, see if it is a param defined for this circuit
            % otherwise, return []
            
            value = [];  % default = not found
            
            while true % one-pass
                match = regexpi(name, '^([A-Z][A-Z0-9_]+)\.[A-Z][A-Z0-9_]*$', 'tokens');
                if ~isempty(match)
                    % named component parameter, check for the component
                    idx = obj.find_ref(match{1}{1});
                    if ~isempty(idx)
                        value = obj.devices{idx}.get_param(name);
                    end
                    break
                end
                
                match = regexpi(name, '^([A-Z][A-Z0-9_]*)$', 'tokens');
                if ~isempty(match)
                    % circuit parameter, see if it is defined for this circuit
                    pname = match{1}{1};
                    for j=1:length(obj.cir_params)
                        p = obj.cir_params(j);
                        if strcmpi(pname, p.PARAM)
                            value = obj.cir_params(j).VALUE;
                            break
                        end
                    end
                    break
                end
                
                break
            end
        end
    end
    
    methods (Access=protected)
        function type = get_type(~)
            type = 'Circuit';
        end
        
        eqns = generate_equations_ex(obj, skip_auto_y);
        
        ref = generate_autoref(obj, prefix);
        
        function eqns = generate_equations(obj)
            eqns = obj.generate_equations_ex(false);
        end
        
    end
    
    methods (Access=private)
        
        function tf = process_params(obj, card)
            % card is known to be a string/char coming in
            tf = false; % = was not a PARAMs card
            card = strtrim(card);
            if regexpi(card, '^PARAMs?\s+')
                % PARAMs card, process it and add/modify in obj.cir_params
                match = regexpi(card, '^PARAMs?(\s+[A-Z][A-Z0-9_]*=\S+)+$', 'tokens');
                if isempty(match)
                    error('Invalid PARAM spec - TODO: throw exception here')
                    % TODO: throw exception if bad parameter card
                end
                tf = true;
                parspec = split(strtrim(match{1}{1}), ' ');
                for i=1:length(parspec)
                    % get the name and value 
                    p = parspec{i};
                    match = regexpi(p, '^([A-Z][A-Z0-9_]*)=(\S+)$', 'tokens');
                    pname = match{1}{1};
                    pval = MCIR.Device.eval_value(match{1}{2});
                    
                    % search for existing param, if it exists modify it
                    is_modified = false;
                    for j=1:length(obj.cir_params)
                        p = obj.cir_params(j);
                        if strcmpi(pname, p.PARAM)
                            obj.cir_params(j).VALUE = pval;
                            is_modified = true;
                            break
                        end
                    end
                    
                    if ~is_modified
                        p = struct('PARAM', upper(pname), 'VALUE', pval);
                        % start the structure array or append to it
                        if isempty(obj.cir_params)
                            obj.cir_params = p;
                        else
                            obj.cir_params(end+1) = p;
                        end
                    end
                end 
            end
        end
        
        function idx = find_ref(obj, name)
            idx = [];
            if ~isempty(obj.devices)
                for i=1:length(obj.devices)
                    c = obj.devices{i};
                    if strcmpi(c.name, name)
                        idx = i;
                        break
                    end
                end
            end
        end
        
        function invalidate_ss(obj)
            obj.cir_ss = [];
            obj.cir_x0 = [];
            obj.cir_eqns = [];
        end
        
        function clear_params(obj)
            obj.cir_params = {}; % struct('PARAM', [], 'VALUE', []);
        end
        
    end
    
    methods (Static, Access=protected) % exceptions
        function me = ME_EmptySystem
            me = MException('Circuit:EmptySystem', 'Unable to simulate empty system');
        end
        function me = ME_CircuitWithoutV0
            me = MException('Circuit:MissingV0','Unable to generate model for circuit without V(0)');
        end
        function me = ME_InvalidCard
            me = MException('Circuit:InvalidCard','Invalid circuit card');
        end
        function me = ME_InvalidName
            me = MException('Circuit:InvalidName','Invalid device name');
        end
        function me = ME_AlreadyDefinedIC
            me = MException('Circuit:AlreadyDefinedIC','Initial condition is already defined');
        end
        function me = ME_RefExists(ref)
            if nargin<1
                ref = '';
                sp = '';
            else
                sp = ' ';
            end
            me = MException('Circuit:RefExists','Reference %s%sexists', ref, sp);
        end
        function me = ME_RefMissing(ref)
            if nargin<1
                ref = '';
                sp = '';
            else
                sp = ' ';
            end
            me = MException('Circuit:RefMissing','Reference %s%smissing', ref, sp);
        end
    end % exceptions
    
end

% TODO: general cleanups for MCIR
%    common regex to match pin names
%    common regex to match param names/values
%    common regex to qualify ref-names
%    common regex to qualify valid subcircuit names (maybe this is not needed)

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net