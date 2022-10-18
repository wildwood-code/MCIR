function bodemag(obj,varargin)
SYS = obj.ss;
if ~isempty(SYS)
    Uac = obj.gen_stim('ac');
    SYSac = series(Uac,SYS);
    bodemag(SYSac, varargin{:})
    title(sprintf('%s - Bode Diagram', obj.name))
else
    throw(MCIR.Circuit.ME_EmptySystem)
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net