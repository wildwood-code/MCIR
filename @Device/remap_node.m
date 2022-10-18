function eqns = remap_node(eqns, from, to)
% goes through all variables in equations and replaces
%    V(from) with V(to)
%    will not replace V(0) - generate error or just ignore
%    called multiple times once for each mapping
%    how to prevent later iterations from replacing something?
%      can mangle the name to preven it... prepend a '*' or something
%      then a final call will removing the mangling, perhaps call without
%      from and to arguments to remove mangling

% search through eqns.x,v,u,y - probably u is not necessary

narginchk(1,3)

if nargin<3
    from = [];
    to = [];
    is_unmangle = true;
else
    is_unmangle = false;
end

mangle_char = '~';  % character used to mangle modified terms, prepended

if is_unmangle
    % unmangle each vector - remove the mangle char from the head
    eqns.x = unmangle_vector(eqns.x, mangle_char);
    eqns.v = unmangle_vector(eqns.v, mangle_char);
    eqns.u = unmangle_vector(eqns.u, mangle_char);
    eqns.y = unmangle_vector(eqns.y, mangle_char);
else
    % remap each vector - if any entry is changed, mangle it
    eqns.x = remap_vector(eqns.x, from, to, mangle_char);
    eqns.v = remap_vector(eqns.v, from, to, mangle_char);
    eqns.u = remap_vector(eqns.u, from, to, mangle_char);
    eqns.y = remap_vector(eqns.y, from, to, mangle_char);
end


end

function vec = remap_vector(vec, from, to, mangle_char)
if ~strcmp(from, '0') % do not remap node 0 ever
    for i=1:length(vec)
        v = vec(i).name;
        mod = 0;
        match = regexp(v, '^V\((.+)\)$', 'tokens');
        
        if ~isempty(match)
            if strcmp(from, match{1})
                mod = 1;
                v = [ mangle_char 'V(' to ')'];
            end
        end
    
        if mod
            vec(i).name = v;
        end
    end
end
end

function vec = unmangle_vector(vec, mangle_char)
for i=1:length(vec)
    v = vec(i).name;
    match = regexp(v, ['^' mangle_char '(.*)$' ], 'tokens');
    if ~isempty(match)
        vec(i).name = match{1}{1};
    end
end
end