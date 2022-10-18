function ref = generate_autoref(obj, prefix)
prefix = upper(prefix);
m = regexp(prefix,'^([A-Z]+)', 'tokens');
prefix = m{1}{1};
if ~isfield(obj.genref,prefix)
    % prefix is not tracked yet, start it at 1
    obj.genref.(prefix) = 1;
end

nextref = obj.genref.(prefix);

% search for first non-existing reference (skip those that exist)
while true
    ref = sprintf('%s%i', prefix, nextref);
    idx = obj.find_ref(ref);
    if isempty(idx)
        break
    end
    nextref = nextref + 1;
end

obj.genref.(prefix) = nextref+1;

