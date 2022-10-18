function s = as_string(v)

switch class(v)
    case 'string'
        s = v;

    case { 'char', 'double' }
        s = string(v);
        
    otherwise
        error('Unable to convert type ''%s'' to string', class(v))
end