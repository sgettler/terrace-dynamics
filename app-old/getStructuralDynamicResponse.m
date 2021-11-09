function [d,v,a] = getStructuralDynamicResponse(m,c,k,p,dt)
%getStructuralDynamicResponse returns response time series for n-DOF system
%
%   date modified: 2016-01-12 - SG
%
% getMDOFResponse() returns time series of displacement, velocity, and
% acceleration for the provided n-degree of freedom system subject to the
% provided force time series. The numerical integration uses Newmark (1959)
% and an assumed zero initial displacement and velocity.
%
% Inputs:
%   m = mass matrix, n*n (kg)
%   c = damping matrix, n*n (Ns/m)
%   k = stiffness matrix, n*n (N/m)
%   p = force vector time series, n*t (N)
%   dt = time step (s)
%
% Outputs:
%   d = displacement vector time series, n*t (m)
%   v = velocity vector time series, n*t (m/s)
%   a = acceleration vector time series, n*t (m/s2)
%
% The length of the returned response vector time series is the same as that for
% the provided force vector time series.
%
% References:
%   Newmark, N.M. (1959). "A method of computation for structural dynamics."
%       J. Eng. Mech. Div., ASCE, 85(3), 67-94.


    % Newmark's method constants
    newg = 1/2;
    newb = 1/6;

    intk = 1/newb/dt^2*m + newg/newb/dt*c + k;
    intc = 1/newb/dt*m + newg/newb*c;
    intm = 1/2/newb*m + (newg/2/newb-1)*dt*c;


    % integrate
    d = zeros(size(p,1),size(p,2));
    v = zeros(size(p,1),size(p,2));
    a = zeros(size(p,1),size(p,2));

    for i = 2:size(p,2)
        d(:,i) = d(:,i-1) + intk\((p(:,i)-p(:,i-1))+intc*v(:,i-1)+intm*a(:,i-1));
        v(:,i) = newg/newb/dt*(d(:,i)-d(:,i-1)) + (1-newg/newb)*v(:,i-1) + dt*(1-newg/2/newb)*a(:,i-1);
        a(:,i) = 1/newg/dt*(v(:,i)-v(:,i-1)) + (1-1/newg)*a(:,i-1);
    end

end
