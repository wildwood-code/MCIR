% DEVICE   linear, lumped, time-invariant (LLTI) electronic device
%
% Description:
%   DEVICE implements an electronic device. The device has a name, nodes,
%   and parameters. A DEVICE is represented by a set of linear differential
%   equations relating the voltage across the device to the current
%   entering the pins of the device.
%
%   DEVICE itself is an abstract class. Classes derived from DEVICE will
%   implement specific electronic components such as resistors, capacitors,
%   or sources.
%
%   A device implements the set of differential and static equations:
%        0 = P11 x' + P12 v + P13 u       P = [ P11 P12 P13
%        0 = P21 x  + P22 v + P22 u             P21 P22 P23
%        y = P31 x  + P32 v + P32 u             P31 P32 P33 ]
%     x(0) = x0
%
% SPICE cards:
%   Devices are describe with SPICE-like cards. The general format is:
%     Pref n1 ... nn value param1=val param2(val) ...
%       Pref is the reference designator
%       P is the prefix and denotes the type of Device (R,L,C,V,I,etc)
%       ref is the rest of the reference designator formed from A-Z0-9_
%       all references are case-insensitive
%     values are standard exponential-form real numbers and may take a
%     suffix to denote engineering magnitudes (see below) but no text may
%     follow the unit (this differs from SPICE)
%     examples:
%       0 -1.5 +0.001 1m 10k 1.0MEG 1e6 -31.4e-1
%     value=undef is a special, undefined value (useful for IC on L and C)
%   Not all SPICE devices are implemented. The subset is the LLTI SPICE
%   prefixes including: RLCVIEFGHK
%   There are a couple of devices not found in SPICE:
%     N    : nullor = nullator-norator pair
%     PORT : port (for multi-port analysis)
%     P    : probe (for probing the circuit)
%   Suffixes on values represent a multipler. Suffixes are
%   case-insensitive, except for m which represents milli (10^-3) or
%   M which represents mega (10^6)
%     suf    exp    mult
%      f     -15     0.000,000,000,000,001
%      p     -12     0.000,000,000,001
%      n     -9      0.000,000,001
%      u     -6      0.000,001
%      m     -3      0.001
%      k      3      1,000
%      meg    6      1,000,000
%      M      6      1,000,000,000
%      g      9      1,000,000,000,000
%      t      12     1,000,000,000,000,000 
%    
% Interface:
%   D = (constructor for some device derived from DEVICE)
%   D.equations                - generate equations for the device
%   D.list                     - list the device
%   D.copy                     - make a copy of the device (separate from the original*)
%
%   Device.SPICE               - (static) generate device from SPICE-like card
%   Device.undef               - (static) constant for undefined value
%
% Notes:
%   * Devices are handle classes. Using a simple assignment (=) will only
%     assign a new handle to the same object. Changes to one affects the
%     other. Use the Device copy() method to make a new, separate copy.
%
% See also:
%   CIRCUIT PROBE PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

% TODO: add copyright notice giving rights to distrubute, modify, with
% acknowledgement/attribution

% Interface for a class derived from device
%   MUST implement:
%     list                as public
%     get_type            as protected
%     generate_equations  as protected
%     SPICE               as static, protected

classdef Device < handle

    properties (Hidden)
        name
    end
    
    properties (Hidden, Dependent)
        type
    end
    
    methods (Access=protected)  % abstract constructor (protected)
        function obj = Device(name)
            narginchk(0,1)
            if nargin<1
                name = '';
            end
            [~,name] = MCIR.Device.is_charstr(name);
            obj.name = name;
        end
    end % abstract constructor (Protected)
    
    methods (Abstract)
        % new = COPY(obj)
        %
        %  Devices are handle classes, as are all classes Derived from Device.
        %  Using a simple assignment just makes a copy of the handle to the object.
        %  Changes made through one handle affects the other.
        %  The COPY method makes a separate copy, allowing the copy to be modified
        %  without affecting the source.
        new = copy(obj)
        
        str = list(obj);
        alter(obj, varargin);
    end
    
    methods % interface methods

        function set.name(obj, n)
            % only Circuit is allowed to set non-standard names
            if ~strcmp(obj.get_type, 'Circuit')
                [tf,n] = MCIR.Device.is_valid_name(n);
                if ~tf
                    throw(MCIR.Device.ME_InvalidName)
                end
            end
            obj.name = n;
        end
        
        function EQN = equations(obj)
            % EQN = obj.EQUATIONS   generate equations for the device
            eqns = obj.generate_equations();
            EQN.name = obj.name;
            EQN.P = eqns.P;
            EQN.x = eqns.x;
            EQN.v = eqns.v;
            EQN.u = eqns.u;
            EQN.y = eqns.y;
        end
        
    end % interface methods
    
    methods (Static, Access=public) % static interface methods
        % Public interface functions
        [DEV,isvalid,isblank] = SPICE(card);
        val = undef(); % undef constant
    end % static interface methods
    
    methods % get/set methods
        function type = get.type(obj)
            type = get_type(obj);
        end
    end % get/set methods
    
    methods (Static, Access=protected) % exceptions
        function me = ME_InvalidName
            me = MException('Device:InvalidName','Invalid device name');
        end
        function me = ME_InvalidNode
            me = MException('Device:InvalidNode','Invalid node name');
        end
        function me = ME_InvalidArgument
            me = MException('Device:InvalidArgument','Invalid argument');
        end
        function me = ME_UnknownError
            me = MException('Device:UnknownError','Unknown error');
        end
        function me = ME_InvalidValue
            me = MException('Device:InvalidValue','Invalid value');
        end
    end % exceptions

    methods (Abstract, Access=protected)
        type = get_type(obj);
        eqns = generate_equations(obj);
    end
    
    methods (Access=public)  % TODO: change this to protected
        function value = get_param(~, ~) % args: obj, name
            value = [];  % default if not overridden
        end
    end
    
    methods (Static, Access=protected)
        [value,tf] = eval_value(valuestr,spice)
        valstr = encode_value(value)
        s = as_string(v)
        args = parse_input(varargin)
        [name, nodes, params, refs] = SPICE_card(varargin)
        eqns = pack_equations(P,v,u,y,x);
        [tf,char] = is_charstr(cstr, convstring)
        [tf,name] = is_valid_name(name)
        tf = is_undef(val);
        [vvar,cn] = V(n,pr)
        [ivar,n] = I(n,pr)
        eqns = remap_node(eqns, from, to)
        eqns = set_owner(eqns, owner, intnode)
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net