function [MAG,PHASE,W] = bode(obj,varargin)
nargoutchk(0,3)
SYS = obj.ss;
if ~isempty(SYS)
    Uac = obj.gen_stim('ac');
    SYSac = series(Uac,SYS);
    if nargout==0
        bode(SYSac, varargin{:})
        title(sprintf('%s - Bode Diagram',obj.name))
    else
        [MAG,PHASE,W] = bode(SYSac, varargin{:});
    end
else
    throw(MCIR.Circuit.ME_EmptySystem)
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net