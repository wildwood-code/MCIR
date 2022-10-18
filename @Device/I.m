function [ivar,cn] = I(n,pr)
if nargin<2
    pr = 'I';
end
[tf,cn] = MCIR.Device.is_charstr(n);
if tf
    cn = upper(cn);
    ivar = [pr '(' cn ')'];
else
    throw(MCIR.Device.ME_InvalidName)
end
end