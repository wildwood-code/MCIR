function [name, nodes, params, refs] = SPICE_card(card, prefix, varargin)
% SPICE_CARD(card)               REF n1 n2 value/params
% SPICE_CARD(card, n)            REF n1 ... nn value/params
% SPICE_CARD(card, n, 'p')       REF n1 ... nn pref   value/params
% SPICE_CARD(card, n, 'p', m)    REF n1 ... nn pref1 prefn value/params
% SPICE_CARD(card, 'X')          REF n1 ... n? xname value/params
%  for X/subcircuit, output is [name, nodes, params, subname]

narginchk(2,5)
if nargin==2
    if ischar(prefix) && strcmp(prefix, 'X')
        % subcircuit
        n = 0;
        m = 0;
    else
        n = 2;
        m = 0;
    end
elseif nargin==3 && ischar(varargin{1})
    n = 0;
    m = 0;
elseif nargin==3
    n = varargin{1};
    m = 0;
elseif nargin==4
    n = varargin{1};
    m = 1;
    p = varargin{2};
elseif nargin==5
    n = varargin{1};
    m = varargin{3};
    p = varargin{2};
else
    error("Invalid arguments")
end

name = [];
nodes = cell(1,n);
params = struct;
if isinf(m)
    refs = cell(1,0);
else
    refs = cell(m>0,m);
end
is_error = false;

while true % executes once (allows break after is_error)
    if n>0 || m>0
        % get ref/name
        match = regexp(card, ['^\s*([' lower(prefix) upper(prefix) '][A-Za-z0-9_@]+)\s+(.*)$'], 'tokens');
        if ~isempty(match)
            name = match{1}{1};
            card = match{1}{2};
        else
            is_error = true;
            break
        end
        
        % get nodes
        for i=1:n
            match = regexp(card, '^\s*(\S+)\s*(.*)$', 'tokens');
            if ~isempty(match)
                nodes{i} = match{1}{1};
                card = match{1}{2};
            else
                is_error = true;
                break
            end
        end
        
        % get refs to other devices
        i=1;
        while i<=m
            match = regexp(card, ['^\s*([' lower(p) upper(p) ']\S+)\s*(.*)$'], 'tokens');
            if ~isempty(match)
                refs{i} = match{1}{1};
                card = match{1}{2};
            else
                % no error here - this is how we handle an unknownn number
                % of refs (for mutual inductance L's)
                break
            end
            i = i + 1;
        end
        
        % get parameters
        try
            params = MCIR.Device.parse_input(card);
        catch
            is_error = true;
            break
        end
        
    else
        % Xref n1 ... nn subname params

        % strategy:
        % 1 grab Xref, confirm it starts with X
        % 2 from the end, match params: name=value
        % 3 pull off the subname
        % 4 the rest are nodes

        tok = split(card, ' ');

        if length(tok)>=3   % at least Xref one-node and subname
            name = upper(tok{1});
            if ~isempty(name) && name(1)=='X'
                subname = upper(tok{2});
                n_pins = length(tok)-2; % -2 for name and subname
                nodes = tok(3:n_pins+2);
                % TODO: parameters
                refs = subname; % return subname in refs output
            else
                is_error = true;
            end
        end

    end
    
    break % forces single execution of loop
end

if is_error
    name = [];
    nodes = {};
    params = struct;
    refs = {};
end