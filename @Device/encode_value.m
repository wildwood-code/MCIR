function valstr=encode_value(value)

if isempty(value) || isnan(value)
    valstr = "undef";
    return
end

if ischar(value)
    % perhaps it is already an encoded string... just return it
    valstr = value;
    return
end

if value==0
    % zero is a special case... just return a "0"
    valstr = "0";
    return
end

% determine the sign for a positive or negative number
if value<0
    sign = "-";
    value = -value;
else
    sign = "";
end

% +1 or -1 are also special cases... just return the whole number
if value==1
    valstr = sign + "1";
    return
end

% get engineering notation exponent
eng = 3*floor(log10(value)/3);
switch eng
    case -15
        suffix = "f";
    case -12
        suffix = "p";
    case -9
        suffix = "n";
    case -6
        suffix = "u";
    case -3
        suffix = "m";
    case 0
        suffix = "";
    case 3
        suffix = "k";
    case 6
        suffix = "MEG";
    case 9
        suffix = "G";
    case 12
        suffix = "T";
    otherwise
        suffix = "E" + MCIR.Device.as_string(eng);
end

% get mantissa - value in range [1,1000)
mant=value/(10.^eng);

% estimate precision of mantissa
% KSM came up with this MAGIC ALGORITHM that seems to work
% 2/8/2017
MAX_SIG=10;
ROUND_SIG=4;
mant_exp = floor(log10(mant)); % 0, 1, or 2
xr = 10.^(mant_exp-ROUND_SIG);
for sig=1:MAX_SIG
  vr=round(mant,sig,"significant");
  if abs(vr-mant)<xr
      break;
  end
  xr = xr/10;
end

% generate the actual encoded string
mant=round(mant,sig,"significant");


valstr = sign + sprintf(strcat("%.",MCIR.Device.as_string(max(0,sig-mant_exp-1)),"f"),mant) + suffix;
