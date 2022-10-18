function varargout = subsref(obj, S)
switch S(1).type
    case { '{}', '()' }
        name = S(1).subs{1};
        if MCIR.Device.is_charstr(name)
            idx = obj.find_ref(name);
            if ~isempty(idx)
                d = obj.devices(idx);
                switch S(1).type
                    case '{}'
                        % return a handle - modifying will affect circuit
                        varargout{1} = d{1};
                        obj.invalidate_ss
                    case '()'
                        % return a copy - modifying will not affect circuit
                        varargout{1} = d{1}.copy;
                end
                
            else
                varargout{1} = [];
            end
        else
            throw(MCIR.Circuit.ME_InvalidName)
        end
        
    otherwise
        [varargout{1:nargout}] = builtin('subsref',obj, S);
end


end