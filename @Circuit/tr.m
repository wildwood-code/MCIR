function [y,t] = tr(obj,varargin)
% TR Transient Response
%  [y,t] = obj.TR(Tend,Npoints)
%  [y,t] = obj.TR(Tend)
%  [y,t] = obj.TR(tvec)
%    Tend    = end simulation time (Tend>0), Tend is a scalar
%    Npoints = number of simulation points (Npoints>=10, default=101)
%    tvec    = vector of simulation points
%    y       = output vector
%    t       = time vector
%
%  When tvec is passed, it is generally a time vector generated from a
%  previous call to tr (when comparing responses). All elements must be
%  positive and the first element must be 0.

narginchk(2,3)
Tend = varargin{1};
if isscalar(Tend)||ischar(Tend)||isstring(Tend)
    Tend = MCIR.Device.eval_value(Tend);
    if nargin<3
        Npoints = 101;
    else
        Npoints = MCIR.Device.eval_value(varargin{2});
    end
end

[SYS,x0] = obj.ss;
if isscalar(Tend)||ischar(Tend)||isstring(Tend)
    [u,t] = obj.gen_stim('tr',Tend,Npoints);
else
    [u,t] = obj.gen_stim('tr', Tend);  % Tend is time vector
end
y = lsim(SYS,u,t,x0);

if nargout==0
    plot(t,y)
    xlabel('sec')
    ylabel('output')
    title(sprintf('%s - Transient Response', obj.name))
    clear y t
end

end