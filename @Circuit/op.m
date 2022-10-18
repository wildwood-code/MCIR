function Y = op(obj)
% OP Operating Point
%  Y = obj.OP
%    Y  = output vector

[SYSdc,x0] = obj.ss;

if nargout==0
    % Print report header
    fprintf('%s - Operating Point report:\n', obj.name)
end

if isempty(SYSdc)
    if nargout==0
        fprintf('<Empty Circuit>\n')
    else
        Y = [];
    end
else
    Udc = obj.gen_stim('dc');
    [~,~,C,D] = ssdata(SYSdc);
    
    [ny,nx] = size(C);
    [~,nu] = size(D);
    
    if ny==0
        fprintf('<No Outputs>')
    else
        if nx==0 && nu==0
            Y = zeros(ny,1);
        elseif nx==0
            Y = D*Udc;
        elseif nu==0
            Y = C*x0;
        else
            Y = C*x0 + D*Udc;
        end
        
        if nargout==0
            % Print report results
            eqns = obj.cir_eqns;
            for i=1:length(Y)
                fprintf('%s\t%s\n', eqns.y(i).expr, MCIR.Device.encode_value(Y(i)))
            end
            clear Y
        end
    end
end
end