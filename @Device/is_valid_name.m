function [tf,name] = is_valid_name(name)

% A valid name starts with a letter, contains at least two characters, and
% contains only letters, numbers, and underscore.
% passes names of the form [A-Z]+@ as valid (auto-gen)
% returns true if it is a valid name, false if it is not
% returned name:
%   if tf=true, returns original name with all caps
%   if tf=false, attempts to make a valid name out of it using the rules:
%     removes leading and trailing space
%     capitalizes all letters
%     changes all non-name chars to underscore _
%     if first character is not a letter, prepends X
%     if the final tweaked name does not have at least 2 characters, it
%     will return X@ (auto-gen symbol)
%   if the name is not a

[tf,name] = MCIR.Device.is_charstr(name);

if tf
    name = upper(name);
    while true % exactly one exectution
        if regexp(name, '^[A-Z]+@$')
            % auto-gen format
            tf = true;
            break
        end
        
        if regexp(name, '^[A-Z][A-Z0-9_]+$')
            % normal, valid name
            tf = true;
            break
        end
        
        % from this point forward, it must have originally been invalid
        tf = false;
        
        % tweak it as much as possible
        name = regexprep(name, '(^\s+|\s+$)', ''); % remove leading/trailing space
        name = regexprep(name, '[^A-Z0-9_]', '_'); % replace non-valid chars with _
        
        % check to see if it is valid now
        if regexp(name, '^[A-Z][A-Z0-9_]+$')
            % normal, valid name
            break
        end
        
        % check to see if it begins with a letter
        m = regexp(name, '^([A-Z]+)', 'tokens');
        if ~isempty(m)
            % return the name prefix followed by auto-gen @ character
            name = [ m{1}{1} '@' ];
        else
            % return the default auto-gen name
            name = 'X@';
        end

        break
    end
else
    tf = false;
    name = [];
end