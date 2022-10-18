function [DEV,isvalid,isblank] = SPICE(card)
% SPICE   generate device from SPICE-like card syntax
%
% See also:
%   RESISTOR INDUCTOR CAPACITOR VSOURCE ISOURCE VCVS CCVS VCCS CCCS PROBE

if ~isstring(card) && ~ischar(card)
    % mark it as invalid
    isvalid = false;
    DEV = [];
    isblank = false;
else
    card = string(card);
    card = regexprep(card, '^[*].+$', '');  % remove full line comments *
    card = regexprep(card, ';.+$', '');     % remove inline comments ;
    card = deblank(card);                   % remove trailing space
    if strlength(card)>0
        isblank = false;
        prefix = upper(card{1}(1));
        switch prefix
            case 'R'
                [DEV,isvalid] = MCIR.resistor.SPICE(card);
            case 'C'
                [DEV,isvalid] = MCIR.capacitor.SPICE(card);
            case 'L'
                [DEV,isvalid] = MCIR.inductor.SPICE(card);
            case 'K'
                [DEV,isvalid] = MCIR.coupling.SPICE(card);
            case 'V'
                [DEV,isvalid] = MCIR.voltage.SPICE(card);
            case 'I'
                [DEV,isvalid] = MCIR.current.SPICE(card);
            case 'E'
                [DEV,isvalid] = MCIR.vcvs.SPICE(card);
            case 'F'
                [DEV,isvalid] = MCIR.cccs.SPICE(card);
            case 'G'
                [DEV,isvalid] = MCIR.vccs.SPICE(card);
            case 'H'
                [DEV,isvalid] = MCIR.ccvs.SPICE(card);
            case 'N'
                [DEV,isvalid] = MCIR.nullor.SPICE(card);
            case 'P'
                [DEV,isvalid] = MCIR.port.SPICE(card);
            case 'O'
                [DEV,isvalid] = MCIR.probe.SPICE(card);
            case 'X'
                [DEV,isvalid] = MCIR.subcircuit.SPICE(card);
            otherwise
                % mark it as invalid
                isvalid = false;
                DEV = [];
        end
    else
        % mark it as a blank line (after comments removed)
        isblank = true;
        isvalid = true;
        DEV = [];
    end
end