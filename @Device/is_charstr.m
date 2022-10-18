        function [tf,char] = is_charstr(cstr, convstring)
            % pass 2nd argument == true to convert to a string, otherwise
            % it is converted to a char array
            narginchk(1,2)
            if nargin<2
                convstring = false;
            end
            if ischar(cstr)
                tf = true;
                if convstring
                    char = string(cstr);
                else
                    char = cstr;
                end
            elseif isstring(cstr) && isscalar(cstr)
                tf = true;
                if convstring
                    char = cstr;
                else
                    char = convertStringsToChars(cstr);
                end
            else
                tf = false;
                char = [];
            end
            if nargout<2
                clear char
            end
        end
