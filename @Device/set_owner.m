function eqns = set_owner(eqns, owner, intnode)
% goes through all variable names in equations and replaces
% stuff like IV(V1) with IV(owner.V1), and VC (but not V - see below)
% call with intnode for V(internal)

if nargin==1
    % call to unmangle
    eqns.x = unmangle(eqns.x);
    eqns.v = unmangle(eqns.v);
    eqns.u = unmangle(eqns.u);
    eqns.y = unmangle(eqns.y);
elseif nargin<3
    % maps internal variables (other than node voltages) to the owner
    eqns.x = set_owner_vec(eqns.x, owner);
    eqns.v = set_owner_vec(eqns.v, owner);
    eqns.u = set_owner_vec(eqns.u, owner);
    eqns.y = set_owner_vec(eqns.y, owner);
else
    % called for internal node voltages of subcircuits
    % maps these to the owner
    %eqns.x = set_owner_vec_v(eqns.x, owner, intnode);
    eqns.v = set_owner_vec_v(eqns.v, owner, intnode);
    %eqns.u = set_owner_vec_v(eqns.u, owner, intnode);
    %eqns.y = set_owner_vec_v(eqns.y, owner, intnode);
end

end

function vec = set_owner_vec(vec, owner)
for i=1:length(vec)
    v = vec(i).name;
    match = regexp(v, '^(V[A-Z]+|I[A-Z]*)\((.+)\)$', 'tokens');
    if ~isempty(match) && ~isempty(match{1})
        vec(i).name = ['~' match{1}{1} '(' owner '.' match{1}{2} ')'];
    end
end
end

function vec = set_owner_vec_v(vec, owner, intnode)
for i=1:length(vec)
    v = vec(i).name;
    match = regexp(v, '^V\((.+)\)$', 'tokens');
    if ~isempty(match) && ~isempty(match{1})
        m = match{1}{1};
        if strcmp(m, intnode)
            vec(i).name = ['~V(' owner '.' m ')'];
        end
    end
end
end

function vec = unmangle(vec)
for i=1:length(vec)
    v = vec(i).name;
    match = regexp(v, ['^~(.*)$' ], 'tokens');
    if ~isempty(match)
        vec(i).name = match{1}{1};
    end
end
end

