function Y = dc(obj)
% DC Operating Point
%  Y = obj.DC
%    Y  = output vector

if nargout==0
    obj.op
else
    Y = obj.op;
end

end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net