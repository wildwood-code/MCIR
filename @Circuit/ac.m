function [H,F] = ac(obj,varargin)
% AC Frequency Response
%  [H,F] = obj.AC(Fstart,Fend,Npoints)
%  [H,F] = obj.AC('lin',Fstart,Fend,Npoints)
%  [H,F] = obj.AC('dec',Fstart,Fend,Npointsperdecade)
%  [H,F] = obj.AC(Fvec)
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
%
% See also:
%   FR

if nargout==0
    obj.fr(varargin{:})
else
    [H,F] = obj.fr(varargin{:});
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net