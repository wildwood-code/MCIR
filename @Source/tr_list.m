function list = tr_list(str, len)
% len=-1 denotes unlimited number, unconstrained
% len=-2 denotes unlimited number, pairs

re = regexp(str, '([^ ,]+)', 'tokens');

if ~isempty(re)
    if len>0
        list = zeros(1,len);
        N = min(len,length(re));
        for i=1:N
            list(1,i) = MCIR.Device.eval_value(re{i}{1});
        end
    elseif isinf(len) % infinite list, non-paired
        N = length(re);
        list = zeros(1,N);
        for i=1:N
            list(1,i) = MCIR.Device.eval_value(re{i}{1});
        end
    elseif len==0 % infinite list of pairs
        % ignores last one if not in a complete pair
        N = 2*floor(length(re)/2);
        list = zeros(1,N);
        for i=1:2:N-1
            list(1,i) = MCIR.Device.eval_value(re{i}{1});
            list(1,i+1) = MCIR.Device.eval_value(re{i+1}{1});
        end
    else
        list = [];
    end
end