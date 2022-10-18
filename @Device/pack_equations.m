function eqns = pack_equations(P,v,u,y,x)
% v,u,y,x are struct arrays
%  v.name
%  u.name, u.type, u.params
%  y.name, y.expr
%  x.name, x.ic

eqns = struct;
narginchk(0,5)
if nargin>=1
    assert(ismatrix(P))
    eqns.P = P;
else
    eqns.P = [];
end
if nargin>=2 && ~isempty(v)
    assert(isstruct(v))
    eqns.v = v;
else
    eqns.v = struct('name', {});
end
if nargin>=3 && ~isempty(u)
    assert(isstruct(u))
    eqns.u = u;
else
    eqns.u = struct('name', {}, 'type', {}, 'params', {}, 'DC', {});
end
if nargin>=4 && ~isempty(y)
    assert(isstruct(y))
    eqns.y = y;
else
    eqns.y = struct('name', {}, 'expr', {});
end
if nargin>=5 && ~isempty(x)
    assert(isstruct(x))
    eqns.x = x;
else
    eqns.x = struct('name', {}, 'ic', {});
end

end
