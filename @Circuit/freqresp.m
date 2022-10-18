function [H,W] = freqresp(obj,varargin)
nargoutchk(0,3)
SYS = obj.ss;
if ~isempty(SYS)
    Uac = obj.gen_stim('ac');
    SYSac = series(Uac,SYS);
    [H,W] = freqresp(SYSac, varargin{:});
else
    throw(MCIR.Circuit.ME_EmptySystem)
end
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net