% PROBE   voltage or current probe
%
% Description:
%   PROBE is a voltage (single-ended or differential) or current probe
%   defining the outputs of the circuit being modeled. A probe may specify
%   one or more voltages or currents.
%
% SPICE card syntax:
%   Pref probe1 [probe2 probe3 ... proben]
%     probe => V(node)          single-ended probe, referenced to 0
%              V(node1,node2)   differential probe V(node1)-V(node2)
%              VL(Lref)         inductor voltage variable
%              VC(Cref)         capacitor voltage state variable
%              VP(PORTref)
%              I(Vref)          independent voltage source current variable
%              I(Lref)          inductor current state variable
%              I(Cref)          capacitor current variable
%              IP(PORTref)
%
% Interface:
%   P = probe(probe)
%   P.alter(probe)
%   P.probe = probe
%   P.params = probe           - alternate to alter
%   P.equations                - generate equations for the probe
%   P.list                     - list the probe
%
% See also:
%   DEVICE CIRCUIT PORT
%   RESISTOR CAPACITOR INDUCTOR COUPLING
%   VOLTAGE CURRENT VCVS VCCS CCVS CCCS NULLOR

classdef probe < MCIR.Device
    
    properties (Dependent)
        card
    end
    
    properties (Hidden, Dependent)
        Probe
        params % write-only
    end
    
    properties (Access=protected)
        p
    end
    
    methods % interface methods
        
        function obj = probe(probe)
            narginchk(1,1)
            name = 'P@'; % auto-generated
            obj@MCIR.Device(name);
            [tf,probes] = MCIR.probe.split_probes(probe);
            if ~tf
                throw(MCIR.probe.ME_Invalidprobe);
            end
            obj.p = probes;
        end
        
        function new = copy(obj)
            new = MCIR.probe(join(obj.p,' '));
            new.name = obj.name;
        end
        
        function str = list(obj)
            str = sprintf("%s %s", obj.name, join(obj.p,' '));
            if nargout<1
                fprintf("%s\n", str)
                clear str
            end
        end
        
        function alter(obj, varargin)
            narginchk(2,2)
            [tf,probes] = MCIR.probe.split_probes(varargin{1});
            if ~tf
                throw(MCIR.probe.ME_Invalidprobe);
            end
            obj.p = probes;
        end
        
    end % interface methods
    
    methods % get/set methods
        
        function set.params(obj, params)
            obj.alter(params)
        end
        
        function probe = get.Probe(obj)
            probe = join(obj.p, ' ');
        end
        
        function set.Probe(obj, probe)
            obj.alter(probe)
        end
        
        function card = get.card(obj)
            card = obj.list;
        end
        
    end % get/set methods
    
    methods (Static, Access=protected) % exceptions
        function me = ME_Invalidprobe
            me = MException('probe:Invalidprobe','Invalid probe specifier');
        end
    end
    
    methods (Access=protected)
        function type = get_type(obj) %#ok<MANU>
            type = 'probe';
        end
        
        function eqns = generate_equations(obj)
            y = struct('name', {}, 'expr', {});
            n = length(obj.p);
            P = [];
            v = struct('name', {});
            x = struct('name', {}, 'ic', {});
            for i=1:n
                name = obj.name;
                if n>1
                    name = sprintf('%s.%i', name, i);
                end
                y(i).name = name;
                [~,~,type,data] = MCIR.probe.is_probe_valid(obj.p(i));
                Pp = [];
                var = struct('name', {});
                switch type
                    case 2
                        y(i).expr = [data{1} '(' data{2} ',' data{3} ')'];
                        var(1).name = [data{1} '(' data{2} ')'];
                        var(2).name = [data{1} '(' data{3} ')'];
                        Pp = [1 -1];
                    case { 0, 1 }
                        y(i).expr = [data{1} '(' data{2} ')'];
                        var(1).name = [data{1} '(' data{2} ')'];
                        Pp = [1];
                end
                if regexpi(var(1).name, '^(?:VC\(C.+\)|I\(L.+\))$')
                    % state variable - prepend to x and P
                    var(1).ic = [];
                    x = [var,x]; %#ok<*AGROW>
                    [nr,nc] = size(P);
                    P = [zeros(nr,1) P;Pp zeros(1,nc)];
                else
                    % static variable - append to v and P
                    v = [v,var];
                    [nr,nc] = size(P);
                    [~,nv] = size(Pp);
                    P = [P zeros(nr,nv);zeros(1,nc) Pp];
                end
            end
            
            if ~isempty(P)
                [~,nc] = size(P);
                P = [zeros(nc,nc);P];
                eqns = MCIR.Device.pack_equations(P,v,[],y,x);
            else
                eqns = MCIR.Device.pack_equations();
            end
        end
    end
    
    methods (Static, Access=protected)
        function [tf,probes] = split_probes(probe)
            % TODO: Here, in is_probe_valid, and generate_equations...
            % generate the correct output if a port is specified
            % this may be unnecessary since probing is automatic with a
            % port
            % in this case, remove the ability to probe a port here
            % likely that is the case
            tf = true;
            probe = upper(probe);
            m = regexp(probe, '(V[LCP]?\(\s*\w+\s*\)|V\(\s*\w+\s*,\s*\w+\s*\s*\)|IP?\([A-Z]\w+\))', 'tokens');
            %m = regexp(probe, '\s*(V[LCP]?\([A-Z0-9_.]+)|V\([A-Z0-9_.]+\s*,\s*[A-Z0-9_.]+\)|IP?\([A-Z0-9_.]+\))', 'tokens');

            probes = strings(1,0);
            for i=1:length(m)
                probe = m{i}{1};
                if MCIR.probe.is_probe_valid(probe)
                    probes(end+1) = probe; %#ok<AGROW>
                else
                    tf = false;
                end
            end
            if isempty(probes)
                tf = false;
            end
        end
        
        function [tf,probe,type,data] = is_probe_valid(probe)
            tf = false;
            type = [];
            data = {};
            [~,probe] = MCIR.Device.is_charstr(probe);
            while ischar(probe) % will execute exactly once
                probe = upper(probe);
                m = regexp(probe, '^\s*(V)\(\s*(\w+)\s*,\s*(\w+)\s*\)\s*$', 'tokens');
                %m = regexp(probe, '^\s*(V)\(([A-Z0-9_.]+)\s*,\s*([A-Z0-9_.]+)\)\s*$', 'tokens');
                if ~isempty(m)
                    tf = true;
                    type = 2; % differential voltage probe
                    data = m{1};
                    break
                end
                m = regexp(probe, '^\s*(V[LCP]?)\(\s*(\w+)\s*\)\s*$', 'tokens');
                %m = regexp(probe, '^\s*(V[LCP]?)\(([A-Z0-9_.]+)\)\s*$', 'tokens');
                if ~isempty(m)
                    tf = true;
                    type = 1; % single-ended voltage probe
                    data = m{1};
                    break
                end
                m = regexp(probe, '^\s*(IP?)\(\s*([A-Z]\w+)\s*\)\s*$', 'tokens');
                %m = regexp(probe, '^\s*(IP?)\(([A-Z0-9_.]+)\)\s*$', 'tokens');
                if ~isempty(m)
                    tf = true;
                    type = 0; % current probe
                    data = m{1};
                    break
                end
                tf = false;
                probe = [];
                type = [];
                data = {};
                break % force single excecution of while loop
            end
            if tf
                % valid, delete all spaces and return
                probe = regexprep(probe, '\s+', '');
            end
        end
        
    end
    
    methods (Static, Access=public)
        function [P,tf] = SPICE(card)
            m = regexpi(card, '^\s*(O(?:@|\w+))\s+(.+)\s*$', 'tokens');
            if ~isempty(m)
                try
                    P = MCIR.probe(m{1}{2});
                    P.name = m{1}{1};
                    tf = true;
                catch
                    throw(MCIR.probe.ME_Invalidprobe)
                end
            else
                tf = false;
                P = MCIR.Device.undef;
            end
        end
    end
    
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net