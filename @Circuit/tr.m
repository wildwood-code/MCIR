function [y,t] = tr(obj,varargin)
% TR Transient Response
%  [y,t] = obj.TR(Tend,Npoints)
%    Tend    = end simulation time (Tend>0)
%    Npoints = number of simulation points (Npoints>=10, default=101)
%    y       = output vector
%    t       = time vector

narginchk(2,3)
Tend = MCIR.Device.eval_value(varargin{1});
if nargin<3
    Npoints = 101;
else
    Npoints = MCIR.Device.eval_value(varargin{2});
end

[SYS,x0] = obj.ss;
[u,t] = obj.gen_stim('tr',Tend,Npoints);
y = lsim(SYS,u,t,x0);

if nargout==0
    plot(t,y)
    xlabel('sec')
    ylabel('output')
    title(sprintf('%s - Transient Response', obj.name))
    clear y t
end

end