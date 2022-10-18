% NET Multi-port network analysis
%  P = obj.NET(ptype,Fstart,Fend,Npoints)
%  P = obj.NET(ptype,'lin',Fstart,Fend,Npoints)
%  P = obj.NET(ptype,'dec',Fstart,Fend,Npointsperdecade)
%  P = obj.NET(ptype,Fvec)
%    ptype   = Parameter type ('Z','Y','H','G','S','T','ABCD' : default='Z')
%    Fstart  = start simulation frequency (*)
%    Fend    = end simulation frequency
%    Npoints = number of simulation points (Npoints>=2, default=*)
%    'lin'   = denotes linear sweep
%    'dec'   = denotes decade sweep (logarithmic) also accepts 'log'
%    Fvec    = frequency vector or scalar (all elements must be >= 0)
%    P       = RF_Param object of type specified by ptype
%
%    Note that ptype may be either the first or last argument. If omitted,
%    it will be assumed to be the default 'Z'
%
%    * Fstart must be > 0 for decade sweep (default), >=0 for linear or
%      vector sweep
%      Number of points may be specified (>=2) or left to default. For a
%      decade sweep, the default will be 10 points/decade, for a linear
%      sweep, the default will be 101 points
%
% See also:
%   FR

function P = net(obj,varargin)

% Determie the type parameter, if present - it may be first or last parameter
% remove it from the parameter list
[tf,type] = is_param_type(varargin{1});
if tf
    args = varargin(2:end);
else
    [tf,type] = is_param_type(varargin{end});
    if tf
        args = varargin(1:end-1);
    else
        args = varargin(1:end);
        type = 'Z';
    end
end

ports = struct('name', {}, 'idxy_vp', {}, 'idxy_ip', {}, 'was_port', {});
eqns = obj.generate_equations;
ny = length(eqns.y);

% determine the list of ports, setting each to output and finding indices
% for VP and IP outputs
Z0 = [];
for d=obj.devices
    dev = d{1};
    if isa(dev,'MCIR.port')
        ports(end+1).name = dev.name;  %#ok<AGROW>
        ports(end).was_port = dev.Port;
        if ~isempty(Z0)
            if dev.R~=Z0
                warning('Impedance should match for every source')
            end
        else
            Z0 = dev.R;
        end
        dev.Port = 'outport';
        [vp,ip,~,~] = dev.get_outputs;
        for i=1:ny
            if strcmpi(eqns.y(i).name,vp)
                ports(end).idxy_vp = i;
                break
            end
        end
        for i=1:ny
            if strcmpi(eqns.y(i).name,ip)
                ports(end).idxy_ip = i;
                break
            end
        end
    end
end

np = length(ports);
[~,F] = obj.ac(args{:}); % dummy run to obtain the frequency vector
nf = length(F);
V = zeros(np,np,nf);
I = zeros(np,np,nf);
Z = zeros(np,np,nf);

for i=1:np
    % set each port as an inport one at a time, and measure frequency response
    obj.alter(ports(i).name,'inport');
    [H,~] = obj.fr(F);
    for j=1:np
        % measure and store VP and IP for each port
        V(j,i,:) = H(ports(j).idxy_vp,:);
        I(j,i,:) = H(ports(j).idxy_ip,:);
    end
    obj.alter(ports(i).name,'outport');
end

% Return ports to their original, saved configuration
for i=1:np
    obj.alter(ports(i).name, ports(i).was_port);
end

% Z is easiest to computer: compute the Z-parameter matrix for each frequency
for i=1:nf
    Z(:,:,i) = V(:,:,i)/I(:,:,i);
end

% convert to a Z-parameter object
Z = EMC.Z_Param(F,Z);

% convert to the desired parameter type
switch type
    case 'Z'
        P = Z;
    case 'Y'
        P = Z.Convert('Y');
    case 'H'
        P = Z.Convert('H');
    case 'G'
        P = Z.Convert('G');
    case 'S'
        P = Z.Convert('S',Z0);
    case 'T'
        P = Z.Convert('T',Z0);
    otherwise
        error('Unrecognized parameter type')
end

if nargout==0
    P.Plot
    clear P
end

end % main function


%% Local functions
function [tf,type] = is_param_type(str)
if MCIR.Device.is_charstr(str)
    while true % will only execute exactly once
        if strcmpi(str,'Z')
            type = 'Z';
            break
        end
        if strcmpi(str,'Y')
            type = 'Y';
            break
        end
        if strcmpi(str,'G')
            type = 'G';
            break
        end
        if strcmpi(str,'H')
            type = 'H';
            break
        end
        if strcmpi(str,'S')
            type = 'S';
            break
        end
        if strcmpi(str,'T')
            type = 'T';
            break
        end
        if strcmpi(str,'ABCD')
            type = 'ABCD';
            break
        end
        type = [];
        break
    end
    if isempty(type)
        tf = false;
    else
        tf = true;
    end
else
    tf = false;
    type = [];
end
end


% Copyright © 2022, Kerry S Martin, martin@wild-wood.net