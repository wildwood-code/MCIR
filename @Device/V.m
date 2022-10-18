function [vvar,cn] = V(n,pr)
if nargin<2
    pr = 'V';
end
[tf,cn] = MCIR.Device.is_charstr(n);
if tf
    cn = upper(cn);
    vvar = [pr '(' cn ')'];
elseif isnumeric(n) && isscalar(n)
    cn = upper(convertStringsToChars(string(n)));
    vvar = [pr '(' cn ')'];
else
    throw(MCIR.Device.ME_InvalidNode)
end
