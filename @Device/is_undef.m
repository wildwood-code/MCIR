function tf = is_undef(val)
if isempty(val)
    tf = true;
elseif ischar(val) || isstring(val)
    val = convertStringsToChars(val);
    if strcmpi(val, 'undef') || strcmp(val, '[]')
        tf = true;
    else
        tf = false;
    end
elseif isscalar(val) && isnan(val)
    tf = true;
else
    tf = false;
end