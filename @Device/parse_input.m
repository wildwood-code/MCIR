function args = parse_input(varargin)
% PARSE_INPUT(card)
% PARSE_INPUT(cell_array_of_cards)
% PARSE_INPUT(item1, item2, ...)
%
%   args is a structure
%     args.param_name = param_value
%
%   card formats: (PARAM is converted to uppercase)
%     PARAM=value
%     PARAM
%     numeric_value
%     PARAM(value)
%     PARAM(value, value value)   comma or space separated

args=struct();

% step 1: take all varargin and create one cell array with all cards
%         each cell is either a char or a numeric scalar
%         traverse cell array up to one level deep
cards = {};
for v=varargin
    vi = v{1};
    if isstruct(vi)
        args = vi;
        continue
    end
    vi = convertContainedStringsToChars(vi);
    
    if ischar(vi)
        % separate any comma or space-separated cards into separate cells
        cards = horzcat(cards, process_chars(vi));
    elseif isnumeric(vi) && isscalar(vi)
        cards{1, end+1} = vi;
    elseif iscell(vi)
        for vj=vi
            if ischar(vj)
                cards = horzcat(cards, process_chars(vj));
            elseif isnumeric(vj) && isscalar(vj)
                cards{1, end+1} = vj;
            elseif iscell(vj)
                if isrow(vj)
                    cards = horzcat(cards, vj);
                else
                    cards = horzcat(cards, vj');
                end
            else
                throw(MCIR.Device.ME_UnknownError)
            end
        end
    else
        throw(MCIR.Device.ME_UnknownError)
    end
end

% step 2: take each card and process it
for v=cards
    vi = v{1};
    if isnumeric(vi)
        % numerics get stored as numeric field VALUE
        args.VALUE = vi;
        continue
    elseif ischar(vi)
        % character array is an encoded numeric, decode and store as VALUE
        args.VALUE = MCIR.Device.eval_value(vi);
        continue
    elseif isstruct(vi)
        % other forms are stored as a struct, merge its fields to args
        for f=fields(vi)
            args.(f{1}) = vi.(f{1});
        end
    else
        throw(MCIR.Device.ME_UnknownError)
    end
end

end

% process a character string argument, which may have space separated args
function cells = process_chars(str)
cells = {};
while ~isempty(str)
    
    re = '^\s*([a-zA-Z]{1,6})\(([^)]+)\)\s*(.*)$';
    m = regexp(str, re, 'tokens');
    if ~isempty(m)
        value = strrep(m{1}{2},',',' ');
        value = regexprep(value, '\s+', ' ');
        card = struct();
        card.(upper(m{1}{1})) = value;
        cells{1,end+1} = card;
        str = m{1}{3};
        continue
    end
    
    re = '^\s*([a-zA-Z]\w*)=(\S+)\s*(.*)$';
    m = regexp(str, re, 'tokens');
    if ~isempty(m)
        value = m{1}{2};
        card = struct();
        card.(upper(m{1}{1})) = value;
        cells{1,end+1} = card;
        str = m{1}{3};
        continue
    end
    
    re = '^\s*([-+]?\d*\.?\d+(?:e[-+]?\d{1,3})?(?:[fFpPnNuUµ]|MEG|meg|Meg|[mMkKgGtT])?)\s*(.*)$';
    m = regexp(str, re, 'tokens');
    if ~isempty(m)
        card = m{1}{1};
        cells{1,end+1} = card;
        str = m{1}{2};
        continue
    end
    
    re = '^\s*([-+!]?)([a-zA-Z]\w*)\s*(.*)$';
    m = regexp(str, re, 'tokens');
    if ~isempty(m)
        switch m{1}{1}
            case { '-', '!' }
                value = false;
            otherwise
                value = true;
        end
        card = struct();
        card.(upper(m{1}{2})) = value;
        cells{1,end+1} = card;
        str = m{1}{3};
        continue
    end
    
    % if we reach this, we have some error
    throw(MCIR.Device.ME_UnknownError)
    % break % use this if not throwing an error, comment out otherwise
end
end