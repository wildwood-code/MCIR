function varargout = gen_stim(obj,varargin)
% GEN_STIM generate stimulus vector for given analysis
%  u = GEN_STIM('dc')
%  u = GEN_STIM('ac')
%  [u,t] = GEN_STIM('tr',tend,N)          default N=1001
narginchk(2,5) % including obj

% first element may be an eqns structure
if isstruct(varargin{1})
    % eqns,type,tend,npoints
    eqns = varargin{1};
    args = varargin(2:end);
else
    % type,tend,npoints
    args = varargin;
    if ~isempty(obj.cir_ss)
        % use the existing equations
        eqns = obj.cir_eqns;
    else
        % warning: do not call obj.ss (this will cause a circular reference)
        % get the u structure
        eqns = obj.generate_equations;
    end
end

type = args{1};
if length(args)>1
    tend = args{2};
end
if length(args)>2
    npoints = args{3};
else
    npoints = 1001;
end

if nargin==2
    % only 'dc' or 'ac' is accepted here
    if strcmpi(type,'dc')
        % AC stimulus is 0, DC stimulus is 1, all other calculated time t=0-
        stims = eqns.u;
        nu = length(stims);
        u = zeros(nu,1);
        for i=1:nu
            u(i,1) = tran_eval(stims(i), -1); % calculator for t=0-
        end
    elseif strcmpi(type,'ac')
        % AC stimulus is 1, all others are 0
        stims = eqns.u;
        nu = length(stims);
        u = zeros(nu,1);
        for i=1:nu
            uname = stims(i).name;
            if strcmpi(uname,'ac')
                u(i,1) = 1;
            end  
        end
    else
        error('Only ''ac'' or ''dc'' accepted for given number of parameters')
    end
    varargout{1} = u;
else
    if strcmpi(type,'dc') || strcmpi(type,'ac')
        error('Types ''ac'' or ''dc'' does not accept additional parameters')
    elseif strcmpi(type,'tr')
        % AC stimulus is 0, DC stimulus is 1, all other calculated
        stims = eqns.u;
        nu = length(stims);
        if tend>0
            if npoints<10
                error('Must have at least 10 points for simulation')
            end
            T = linspace(0,tend,npoints);
            u = zeros(npoints,nu);
            for i=1:nu
                u(:,nu) = tran_eval(stims(i), T);
            end
        else
            T = -1;
            u = zeros(nu,1); % column vector for initial u(0)
            for i=1:nu
                u(i,1) = tran_eval(stims(i), T);
            end
        end
        
    else
        error('Unknown analysis type specified')
    end
    varargout{1} = u;
    varargout{2} = T;
end
end


%% ======= TRANSIENT STIMULI =======

function U = tran_eval(stim, T)
uname = stim.name;
N = length(T);
U = zeros(N,1);
if strcmpi(uname,'ac')
    U(:,1) = 0;
elseif strcmpi(uname,'dc')
    U(:,1) = 1;
else
    % TODO: implement PWLFILE
    utype = stim.type;
    if strcmpi(utype,'PULSE')
        U(:,1) = tran_pulse(T,stim);
    elseif strcmpi(utype,'SINE')
        U(:,1) = tran_sine(T,stim);
    elseif strcmpi(utype,'EXP')
        U(:,1) = tran_exp(T,stim);
    elseif strcmpi(utype,'PWL')
        U(:,1) = tran_pwl(T,stim);
    elseif strcmpi(utype,'RAND')
        U(:,1) = tran_rand(T,stim);
    elseif strcmpi(utype,'RANDN')
        U(:,1) = tran_randn(T,stim);
    elseif strcmpi(utype,'ARB')
        U(:,1) = tran_arb(T,stim);
    else
        error('type ''%s'' is not implemented at this time', utype)
    end
end
end

% wave=tran_arb(T,stim)
%   Generates a waveform array from the given arbitrary waveform expression
%   T        time vector at which sine will be computed
%   arb      arbitrary expression as a function of t (eval'ed in 'base')
%   wave     waveform evaluated at each value of T
%
%   Note: DC value (call with T=-1) will always be 0 for ARB
function wave=tran_arb(T,stim)
arb = stim.params;
if ~ischar(arb)
    error('arb must be a character expression')
end
Np = numel(T);
wave = zeros(Np,1);
for i=1:Np
    t = T(i);
    if t<0
        if ~MCIR.Device.is_undef(stim.DC)
            v = stim.DC;
        else
            v = 0;
        end
    else
        assignin('base','t',t);
        v = evalin('base', arb);
    end
    wave(i) = v;
end
end

% wave=tran_exp(T,stim)
%   Generates a waveform array from the given exponential waveform
%   T        time vector at which sine will be computed
%   V1
%   V2
%   Td1      rise time delay
%   tau1     rise time constant
%   Td2      fall time delay
%   tau2     fall time constant
%   wave     waveform evaluated at each value of T
%
%   Note: either rise or fall can come first
function wave=tran_exp(T,stim)
params = stim.params;
V1 = params(1);
V2 = params(2);
Td1 = params(3);
tau1 = params(4);
Td2 = params(5);
tau2 = params(6);
if Td1<0 || Td2<0
    error('rise/fall delays must be >= 0')
end
if tau1<0 || tau2<0
    error('rise/fall taus must be >= 0')
end
VR = V2-V1;
VF = V1-V2;
Np = numel(T);
wave = zeros(Np,1);
for i=1:Np
    t = T(i);
    if t<0
        if ~MCIR.Device.is_undef(stim.DC)
            vr = stim.DC;
        else
            vr = V1; % TODO: check this
        end        
    elseif t<Td1
        vr = 0; % TODO: check this
    else
        if tau1==0
            vr = VR;
        else
            vr = VR*(1-exp(-(t-Td1)/tau1));
        end
    end
    if t<Td2
        vf = 0;
    else
        if tau2==0
            vf = VF;
        else
            vf = VF*(1-exp(-(t-Td2)/tau2));
        end
    end
    wave(i) = vr + vf + V1;
end
end

% wave=tran_pulse(T,stim)
%   Generates a waveform array from the given pulse waveform
%   T        time vector at which sine will be computed
%   V1
%   V2
%   Tdelay
%   Trise
%   Tfall
%   Ton
%   Tperiod
%   Ncycles
%
%   Note: To calculate the DC equivalent, call with a value of T<0
%
function wave=tran_pulse(T,stim)
params = stim.params;
V1 = params(1);
V2 = params(2);
Tdelay = params(3);
Trise = params(4);
Tfall = params(5);
Ton = params(6);
Tperiod = params(7);
Ncycles = params(8);
if Tperiod<0
    error('Tperiod must be >= 0')
elseif Tperiod==0
    Tperiod = Inf;
end
if Ton<0
    error('Ton must be >= 0')
elseif Ton==0
    Ton = Inf;
end
if Trise<0 || Tfall<0
    error('Trise and Tfall must be >=0')
end
if Tdelay<0
    error('Tdelay must be >= 0')
end
if Ncycles<0 || mod(Ncycles,1)>1e-6
    error('Ncycles must be an integer >=0')
end
Ncycles = round(Ncycles);
T1 = Tdelay;
if Ncycles>0
    if Tperiod==0 || isinf(Tperiod)
        T2 = Inf;
    else
        T2 = T1 + Ncycles*Tperiod;
    end
else
    T2 = Inf;
end
Np = numel(T);
wave = zeros(Np,1);
for i=1:Np
    t = T(i);
    if t<0
        if ~MCIR.Device.is_undef(stim.DC)
            v = stim.DC;
        else
            v = V1;
        end
    elseif t<T1
        v = V1;
    elseif t>T2
        v = V1;
    else
        if Tperiod==0 || isinf(Tperiod)
            tt = t-T1;
        else
            tt = mod(t-T1,Tperiod);
        end
        if tt<Trise
            if Trise>0
                v = V1+(V2-V1)*(tt)/Trise;
            else
                v = V1;
            end
        elseif tt<Trise+Ton
            v = V2;
        elseif tt<Trise+Ton+Tfall
            if Tfall>0
                v = V2+(V1-V2)*(tt-Trise-Ton)/Tfall;
            else
                v = V2;
            end
        else
            v = V1;
        end
    end
    wave(i) = v;
end
end

% wave=tran_pwl(T,stim)
%   Generates a waveform array from the given piecewise-linear waveform
%   T        time vector at which sine will be computed
%   PWL      [t;v] time/value pairs
%   Tperiod  TO BE IMPLEMENTED (TODO:)
%
%   Note: To calculate the DC equivalent, call with a value of T<0
%   Note: DC value (call with T=-1) will always be 0 for ARB
%
function wave=tran_pwl(T,stim)
PWL = stim.params;
Np = numel(T);
X = PWL(1,:);
Y = PWL(2,:);
minX=min(X);
maxX=max(X);
if length(T)==1 && T==-1
    if ~MCIR.Device.is_undef(stim.DC)
        wave = stim.DC;
    else
        wave = Y(1); % first value
    end
else
    for i=1:Np
        if T(i)<minX
            T(i)=minX;
        elseif T(i)>maxX
            T(i)=maxX;
        end
    end
    wave = linterpcir(X,Y,T);
end
end

% wave=tran_rand(T,stim)
%   Generates a waveform array from the given random waveform
%   (uniform distribution)
%   T        time vector at which sine will be computed
%   Ts       random sample time
%   maxv     maximum value
%   minv     minimum value
%
%   Note: To calculate the DC equivalent, call with a value of T<0
function wave=tran_rand(T,stim)
params = stim.params;
Ts = params(1);
maxv = params(2);
minv = params(3);
if Ts<=0
    error('Ts must be > 0')
end
Np = numel(T);
wave = zeros(Np,1);
t0 = T(1);
if t0<0
    if ~MCIR.Device.is_undef(stim.DC)
        vx = stim.DC;
    else
        vx = 0.5*(maxv+minv);
    end
else
    vx = minv+(maxv-minv)*rand();
end
tx = max(t0,0);
for i=1:Np
    t = T(i);
    if t<0
        vx = minv;
    elseif t>=tx+Ts
        vx = minv+(maxv-minv)*rand();
        tx=Ts*floor(t/Ts);
    end
    v = vx;
    wave(i) = v;
end
end

% wave=tran_randn(T,stim)
%   Generates a waveform array from the given random waveform
%   (normal distribution)
%   T        time vector at which sine will be computed
%   Ts       random sample time
%   sigma    standard deviation
%   mu       mean value
%
%   Note: To calculate the DC equivalent, call with a value of T<0
function wave=tran_randn(T,stim)
params = stim.params;
Ts = params(1);
sigma = params(2);
mu = params(3);
if Ts<=0
    error('Ts must be > 0')
end
if sigma<=0
    error('sigma must be > 0')
end
Np = numel(T);
wave = zeros(Np,1);
t0 = T(1);
if t0<0
    if ~MCIR.Device.is_undef(stim.DC)
        vx = stim.DC;
    else
        vx = mu;
    end
else
    vx = sigma*randn()+mu;
end
tx = max(t0,0);
for i=1:Np
    t = T(i);
    
    if t<0
        vx = mu;
    elseif t>=tx+Ts
        vx = sigma*randn()+mu;
        tx=Ts*floor(t/Ts);
    end
    v = vx;

    wave(i) = v;
end
end

% wave=tran_sine(T,stim)
%   Generates a waveform array from the given sinusoidal waveform
%   T        time vector at which sine will be computed
%   offset   DC offset
%   ampl     peak amplitude
%   freq     frequency (Hz)
%   delay    initial delay (sec)
%   theta    damping (in 1/sec)
%   phi      angle (in degrees)
%   Ncycles  number of cycles
%
%   Note: To calculate the DC equivalent, call with a value of T<0
function wave=tran_sine(T,stim)
params = stim.params;
offset = params(1);
ampl = params(2);
freq = params(3);
delay = params(4);
theta = params(5);
phi = params(6);
Ncycles = params(7);
if delay<0
    error('delay must be >= 0')
end
if freq<=0
    error('frequenncy must be > 0')
end
if Ncycles<0 || mod(Ncycles,1)>1e-6
    error('Ncycles must be an integer >=0')
end
Ncycles = round(Ncycles);
Tp = 1.0/freq;
phi = phi*pi/180.0;
T1 = delay;
V1 = offset+ampl*sin(phi);
if Ncycles==0 || isinf(Ncycles)
    T2 = Inf;
    V2 = offset;
else % Ncycles>0
    T2 = T1 + Ncycles*Tp;
    V2 = offset+ampl*sin(2*pi*freq*(T2-T1)+phi)*exp(-(T2-T1)*theta);
end
Np = numel(T);
wave = zeros(Np,1);
for i=1:Np
    t = T(i);
    if t<T1
        if ~MCIR.Device.is_undef(stim.DC)
            v = stim.DC;
        else
            v = V1;
        end
    elseif t>T2
        v = V2;
    else
        v = offset+ampl*sin(2*pi*freq*(t-T1)+phi)*exp(-(t-T1)*theta);
    end
    wave(i) = v;
end
end

% Copyright © 2022, Kerry S Martin, martin@wild-wood.net