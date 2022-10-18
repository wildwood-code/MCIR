function eqns = generate_equations_ex(obj, skip_auto_y)

if nargin<2
	skip_auto_y = false;
end
	
% start with an empty set of equations
eqns = MCIR.Device.pack_equations();

if ~isempty(obj.devices)
    % build equations for the circuit one component at a time
    for d=obj.devices
        eqns = add_equations(eqns, d{1}.equations);
    end
end

if ~skip_auto_y && isempty(eqns.y) && ~isempty(eqns.P)
    % no probes exist, add default probe
    % default probe is V(OUT) if it exists,
    % otherwise the last voltage node except for V(0)
    % otherwise the last variable except for V(0)
    % otherwise the last variable, which is probably V(0)
    nv = length(eqns.v);
    if nv>0
        is_probed = false;
        for i=nv:-1:1
            if strcmpi(eqns.v(i).name, 'V(OUT)')
                probe = MCIR.probe(eqns.v(i).name);
                eqns = add_equations(eqns, probe.equations);
                is_probed = true;
                break
            end
        end        
        if ~is_probed
            for i=nv:-1:1
                if ~strcmpi(eqns.v(i).name, 'V(0)') && ~isempty(regexpi(eqns.v(i).name, '^V\(.+\)$', 'once'))
                    probe = MCIR.probe(eqns.v(i).name);
                    eqns = add_equations(eqns, probe.equations);
                    is_probed = true;
                    break
                end
            end
        end
        if ~is_probed
            for i=nv:-1:1
                if ~strcmpi(eqns.v(i).name, 'V(0)')
                    probe = MCIR.probe(eqns.v(i).name);
                    eqns = add_equations(eqns, probe.equations);
                    is_probed = true;
                    break
                end
            end
        end
        if ~is_probed
            probe = MCIR.probe(eqns.v(nv).name);
            eqns = add_equations(eqns, probe.equations);
        end
    end
end

end


%% Local Functions

function eqns = add_equations(eqns, dev_eqns)
eqns = append_new_variables(eqns, dev_eqns);
nx = length(eqns.x);
nv = length(eqns.v);
nxd = length(dev_eqns.x);
nvd = length(dev_eqns.v);
nyd = length(dev_eqns.y);
for i=1:nxd
    % combine x equations
    x = dev_eqns.x(i);
    [~,id] = find_entry(eqns.x, x.name);
    eqns = combine_eqns_at_row(id, eqns, dev_eqns.P(i,:), dev_eqns.x, dev_eqns.v, dev_eqns.u);
end
for i=1:nvd
    v = dev_eqns.v(i);
    [~,id] = find_entry(eqns.v, v.name);
    eqns = combine_eqns_at_row(nx+id, eqns, dev_eqns.P(nxd+i,:), dev_eqns.x, dev_eqns.v, dev_eqns.u);
end
for i=1:nyd
    y = dev_eqns.y(i);
    [~,id] = find_entry(eqns.y, y.name);
    eqns = combine_eqns_at_row(nx+nv+id, eqns, dev_eqns.P(nxd+nvd+i,:), dev_eqns.x, dev_eqns.v, dev_eqns.u);
end
end


function P = insert_rc_zeros(P, r, c)
[nr,nc] = size(P);
P = vertcat(P(1:r-1,:), zeros(1,nc), P(r:end,:));
P = horzcat(P(:,1:c-1), zeros(nr+1,1), P(:,c:end));
end


function eqns = combine_eqns_at_row(r, eqns, eP, ex, ev, eu)
% r is row in eqns combined to
% eP is the row that will be combined
% ex, ev, eu are the variables of the equation that will be combined
nx = length(eqns.x);
nv = length(eqns.v);
c = 1;
for i=1:length(ex)
    [~,j] = find_entry(eqns.x,ex(i).name);
    eqns.P(r,j) = eqns.P(r,j)+eP(1,c);
    c = c + 1;
end
for i=1:length(ev)
    [~,j] = find_entry(eqns.v,ev(i).name);
    eqns.P(r,nx+j) = eqns.P(r,nx+j)+eP(1,c);
    c = c + 1;
end
for i=1:length(eu)
    [~,j] = find_entry(eqns.u,eu(i).name);
    eqns.P(r,nx+nv+j) = eqns.P(r,nx+nv+j)+eP(1,c);
    c = c + 1;
end
end


function eqns = append_new_variables(eqns, dev_eqns)
nx = length(eqns.x);
nv = length(eqns.v);
nu = length(eqns.u);
ny = length(eqns.y);
for i=1:length(dev_eqns.u)
    u = dev_eqns.u(i);
    if ~find_entry(eqns.u, u.name)
        % append new u at end of list & P matrix
        eqns.u(end+1) = u;
        nu = nu + 1;
        eqns.P = horzcat(eqns.P, zeros(nx+nv+ny,1));
    end
end
for i=1:length(dev_eqns.y)
    y = dev_eqns.y(i);
    if ~find_entry(eqns.y, y.name)
        % append new y at end of list & P matrix
        eqns.y(end+1) = y;
        ny = ny + 1;
        eqns.P = vertcat(eqns.P, zeros(1,nx+nv+nu));
    end
end
for i=1:length(dev_eqns.x)
    x = dev_eqns.x(i);
    [tf,idx] = find_entry(eqns.x, x.name);
    if ~tf
        % append new x at end of list, P matrix
        eqns.x(end+1) = x;
        nx = nx + 1;
        eqns.P = insert_rc_zeros(eqns.P, nx, nx);
    else
        % only overwrite ic if it is currently undefined and the new
        % value is defined
        if ~MCIR.Device.is_undef(x.ic)
            if MCIR.Device.is_undef(eqns.x(idx).ic)
                eqns.x(idx).ic = x.ic;
            else
                throw(MCIR.Circuit.ME_AlreadyDefinedIC)
            end
        end
    end
end
for i=1:length(dev_eqns.v)
    v = dev_eqns.v(i);
    if ~find_entry(eqns.v, v.name)
        % append new v at end of list, P matrix
        eqns.v(end+1) = v;
        nv = nv + 1;
        eqns.P = insert_rc_zeros(eqns.P,nx+nv, nx+nv);
    end
end
end


function [tf,idx] = find_entry(sa, name)
N = length(sa);
[names{1:N}] = sa.name;
fi = strcmpi(name,names);
if any(fi)
    tf = true;
    idx = find(fi,1);
else
    tf = false;
    idx = 0;
end
end

