% [value,has_value]=eval_value(valuestr,spice)
function [value,tf] = eval_value(valuestr,spice)
narginchk(1,2)
if nargin<2
    spice = false;
end

value = 0;
tf = true;
err = false;

if ischar(valuestr)
    valuestr = string(valuestr);
end

if isempty(valuestr)
    value = MCIR.Device.undef;
    tf = false;
elseif isstring(valuestr) && isscalar(valuestr)
    if isempty(valuestr) || strcmpi(valuestr, "undef") || strcmp(valuestr, "[]")
        value = MCIR.Device.undef;
        tf = true;
    elseif strcmpi(valuestr, "Inf")
        value = Inf;
        tf = true;
    else
        re_num = "([-+]?[0-9]*(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?)";
        re_ic   = "(?i)"; % ignore case
        re_mult = "(MEG|K|G|T|M|U|µ|N|P|F)?";
        re_unit = "(?:[a-zA-Z_]*)";
        
        idx = regexp(valuestr, re_ic+"^"+re_num+re_mult+re_unit+"$", 'tokens');
        
        if ~isempty(idx)
            num = str2double(idx{1}{1});
            mult_str = idx{1}{2};
            if spice
                mult_str = upper(mult_str);
                if isempty(mult_str)
                    mult = 1;
                elseif regexp(mult_str, "^K$")
                    mult = 1e3;
                elseif regexp(mult_str, "^(?:U|µ)$")
                    mult = 1e-6;
                elseif regexp(mult_str, "^MEG$")
                    mult = 1e6;
                elseif regexp(mult_str, "^M$")
                    mult = 1e-3;
                elseif regexp(mult_str, "^N$")
                    mult = 1e-9;
                elseif regexp(mult_str, "^P$")
                    mult = 1e-12;
                elseif regexp(mult_str, "^G$")
                    mult = 1e9;
                elseif regexp(mult_str, "^T$")
                    mult = 1e12;
                elseif regexp(mult_str, "^F$")
                    mult = 1e-15;
                else
                    mult = 1;
                end
            else
                if isempty(mult_str)
                    mult = 1;
                elseif regexpi(mult_str, "^k$")
                    mult = 1e3;
                elseif regexpi(mult_str, "^(?:u|µ)$")
                    mult = 1e-6;
                elseif regexpi(mult_str, "^MEG$")
                    mult = 1e6;
                elseif regexp(mult_str,  "^M$")
                    mult = 1e6;
                elseif regexp(mult_str, "^m$")
                    mult = 1e-3;
                elseif regexpi(mult_str, "^n$")
                    mult = 1e-9;
                elseif regexpi(mult_str, "^p$")
                    mult = 1e-12;
                elseif regexpi(mult_str, "^G$")
                    mult = 1e9;
                elseif regexpi(mult_str, "^T$")
                    mult = 1e12;
                elseif regexpi(mult_str, "^F$")
                    mult = 1e-15;
                else
                    mult = 1;
                end
            end
            value = num*mult;
        else
            err = true;
        end
        
    end
    
elseif isscalar(valuestr) && isnumeric(valuestr)
    value = valuestr;
else
    err = true;
end

if err
    if nargout<2
        throw(MCIR.Device.ME_InvalidValue)
    else
        tf = false;
    end
end
