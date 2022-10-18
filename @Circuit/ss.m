function [SYS,x0] = ss(obj)
% SS  generate state-space system for the circuit
%  SYS = obj.SS

%   A device implements the set of differential and static equations:
%        0 = P11 x' + P12 v + P13 u       P = [ P11 P12 P13
%        0 = P21 x  + P22 v + P22 u             P21 P22 P23
%        y = P31 x  + P32 v + P32 u             P31 P32 P33 ]
%     x(0) = x0
%
%   Matrix manipulations produces a state-space system of the form:
%       x' = A x + B u
%       y  = C x + D u
%
%        A = inv(P11)*P12*inv(P22)*P21
%        B = inv(P11)*(P12*inv(P22)*P23 - P13)
%        C = P31 - P32*inv(P22)*P21
%        D = P33 - P32*inv(P22)*P23

if ~isempty(obj.cir_ss)
    SYS = obj.cir_ss;
    x0 = obj.cir_x0;
else
    if isempty(obj.devices)
        SYS = ss;
        x0 = [];
        eqns = [];
    else
        eqns = obj.equations;
        P = eqns.P;
        [x{1:length(eqns.x)}] = eqns.x.name;
        [v{1:length(eqns.v)}] = eqns.v.name;
        [u{1:length(eqns.u)}] = eqns.u.name;
        [y{1:length(eqns.y)}] = eqns.y.expr;
        [ic{1:length(eqns.x)}] = eqns.x.ic;
        
        nx = length(x);
        nv = length(v);
        nu = length(u);
        ny = length(y);
        
        idx = find(ismember(v,'V(0)'),1);
        if isempty(idx)
            throw(MCIR.Circuit.ME_CircuitWithoutV0)
        end
        P(nx+idx,:) = zeros(1,nx+nv+nu);
        P(nx+idx,nx+idx) = 1;
        
        if nx>0
            P11 = P(1:nx,1:nx);
            P12 = P(1:nx,nx+1:nx+nv);
            P13 = P(1:nx,nx+nv+1:nx+nv+nu);
            P21 = P(nx+1:nx+nv,1:nx);
            P22 = P(nx+1:nx+nv,nx+1:nx+nv);
            P23 = P(nx+1:nx+nv,nx+nv+1:nx+nv+nu);
            P31 = P(nx+nv+1:nx+nv+ny,1:nx);
            P32 = P(nx+nv+1:nx+nv+ny,nx+1:nx+nv);
            P33 = P(nx+nv+1:nx+nv+ny,nx+nv+1:nx+nv+nu);
            
            % generate the ABCD matrices
            % warnings may be generated if P11 is singular, but the result
            % may still be valid. Save the warning state before suppressing
            % the warning, the restore it after calculating A and B
            % this has been a problem only for coupling with k=1.0
            w_save = warning('query', 'MATLAB:nearlySingularMatrix');
            warning('off','MATLAB:nearlySingularMatrix')
            A = (P11\P12)*(P22\P21);
            B = P11\(P12*(P22\P23)-P13);
            warning(w_save)
            C = P31-(P32/P22)*P21;
            D = P33-(P32/P22)*P23;


            u0 = obj.gen_stim(eqns, 'tr', -1); % calculate initial condition for t=0-
            x0 = calculate_x0(A,B,ic,u0);
            SYS = ss(A,B,C,D,'StateName',x, 'InputName',u, 'OutputName',y);
        else
            P22 = P(nx+1:nx+nv,nx+1:nx+nv);
            P23 = P(nx+1:nx+nv,nx+nv+1:nx+nv+nu);
            P32 = P(nx+nv+1:nx+nv+ny,nx+1:nx+nv);
            P33 = P(nx+nv+1:nx+nv+ny,nx+nv+1:nx+nv+nu);
            D = P33-(P32/P22)*P23;
            
            x0 = [];
            SYS = ss(D, 'InputName',u, 'OutputName',y);
        end
    end
    % store these until invalidated - any mod to circuit invalidates it
    obj.cir_ss = SYS;
    obj.cir_x0 = x0;
    obj.cir_eqns = eqns;
end
end

function x0 = calculate_x0(A,B,IC,u0)
% Calculate initial condition vector x0
% IC calculation is based on new ABCD based algorithm
% Get state initial conditions and modify equations if they are
% defined. Do not modify if they are not defined. The ones that are
% not defined will be calculated from the system.
[nx,nu] = size(B);
if nx>0
    Xi = zeros(nx,1);
    
    for i=1:nx
        ic = IC{i};
        
        if ~isempty(ic)
            % modify equation to: x(i) = IC
            A(i,:) = 0;
            A(i,i) = 1;
            
            if nu>0
                B(i,:) = 0;
            end
            
            Xi(i,1) = ic;
        else
            % modify equation to: x'(i) = 0
            Xi(i,1) = 0;
        end
        
    end
    
    if nu>0
        x0 = A\(Xi-B*u0);
    else
        x0 = A\Xi;
    end
    
else
    x0 = [];
end

end % calculate_x0