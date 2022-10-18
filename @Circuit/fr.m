function [H,F] = fr(obj,varargin)
% FR Frequency Response
%  [H,F] = obj.FR(Fstart,Fend,Npoints)
%  [H,F] = obj.FR('lin',Fstart,Fend,Npoints)
%  [H,F] = obj.FR('dec',Fstart,Fend,Npointsperdecade)
%  [H,F] = obj.FR(Fvec)
%    Fstart  = start simulation frequency (*)
%    Fend    = end simulation frequency
%    Npoints = number of simulation points (Npoints>=2, default=*)
%    'lin'   = denotes linear sweep
%    'dec'   = denotes decade sweep (logarithmic) also accepts 'log'
%    Fvec    = frequency vector or scalar (all elements must be >= 0)
%    H       = complex frequency response data
%    F       = frequency response frequency vector
%
%    * Fstart must be > 0 for decade sweep (default), >=0 for linear or
%      vector sweep
%      Number of points may be specified (>=2) or left to default. For a
%      decade sweep, the default will be 10 points/decade, for a linear
%      sweep, the default will be 101 points

narginchk(2,5)
if MCIR.Device.is_charstr(varargin{1}) && nargin>=4
    stype = varargin{1};
    if strcmpi(stype,'lin')
        stype = 0;
    elseif strcmpi(stype,'dec')||strcmpi(stype,'log')
        stype = 1;
    else
        error('Unknown sweep type ''%s''', stype)
    end
    fstart = varargin{2};
    fend = varargin{3};
    if nargin>4
        npoints = varargin{4};
    elseif stype==0
        npoints = 10;
    else
        npoints = 101;
    end
elseif isvector(varargin{1}) && nargin==2
    stype = -1;
    F = varargin{1};
elseif nargin>=3
    stype = 1;
    fstart = varargin{1};
    fend = varargin{2};
    if nargin>3
        npoints = varargin{3};
    else
        npoints = 10;
    end
else
    error('Unable to understand arguments')
end

% generate W vector
if stype==-1
    if min(F)<0
        error('Invalid frequency for vector sweep')
    end
elseif stype==1
    if fstart<=0 || fend<=fstart
        error('Invalid frequencies for dec sweep')
    end
    a1 = log10(fstart);
    a2 = log10(fend);
    F = logspace(a1,a2, ceil(npoints*(a2-a1))+1);
else
    if fstart<0 || fend<=fstart
        error('Invalid frequencies for lin sweep')
    end
    F = linspace(fstart, fend, npoints);
end

% generate ac model
SYS = obj.ss;
Uac = obj.gen_stim('ac');
SYSac = series(Uac,SYS);
    
if nargout==0 && stype==1
    figure
    p = bodeoptions;
    p.FreqUnits = 'Hz';
    bodeplot(SYSac,2*pi*F, p);
    title(sprintf('%s - Bode Diagram',obj.name))
else
    H = freqresp(SYSac,F,'Hz');
    if nargout==0 && length(F)>1
        figure
        Hmag = squeeze(abs(H));
        plot(F,Hmag)
        xlabel('Frequency (Hz)')
        ylabel('Magnitude')
        title(sprintf('%s - Frequency Response',obj.name))
        clear H F
    end 
end

end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net