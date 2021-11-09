function [arms] = getCrowdStructureResponse(fm,mm,phi,mt,act,p,dt)
%getCrowdStructureResponse returns respose due to crowd-structure interaction
%
%   date modified: 2016-01-21 - SG
%
% getCrowdResponse() returns acceleration time series for the provided n-degree
% of freedom system subject to crowd-structure dynamic interaction. The
% idealised crowd/structure interaction is after Dougill et al. (2006) as
% implemented by Pavic and Reynolds (2008). The response of each mode is
% combined to calculate the overall response of the system.
%
% Instead of modelling individual bodies, the mass of the crowd is distributed
% on the degrees of freedom of the structure, and the 3DOF system corresponding
% to each structural mode computes the contribution of the crowd analogously to
% a mass participation factor.
%
% The method differs from Pavic and Reynolds in using a time-domain solution of
% the 3DOF system, which can easily be used to compute the RMS response.
%
% Inputs:
%   fm = modal frequencies, 1*m (Hz)
%   mm = modal masses, 1*m (kg)
%   phi = mode shapes, n*m (-)
%   mt = total mass of crowd at each degree of freedom, n*1 (kg)
%   act = fraction of crowd which is active (-)
%   p = force time series, 1*t (N)
%   dt = time step (s)
%
% Outputs:
%   arms = acceleration vector max rms response, n*1 (m/s2)
%
% References:
%   Dougill et al. (2006). "Human structure interaction during rhythmic
%       bobbing." The Structural Engineer, 84(22), 32-39.
%   Pavic and Reynolds (2008). "Experimental verification of novel 3DOF model of
%       grandstand crowd-structure dynamic interaction." 26th International
%       Modal Analysis Conference, Orlando, FL, 4-7 Feb, 2008.


    % interaction model parameters
    zetam = 0.01; % critical damping ratio of structure (assumed value)
    zetaa = 0.25; % critical damping ratio of active people
    zetap = 0.40; % critical damping ratio of passive people

    fa = 2.3; % natural frequency of active people (Hz)
    fp = 5.0; % natural frequency of passive people (Hz)


    % set up 3DOF systems for each mode
    cm = 2*zetam*mm.*(2*pi*fm);
    km = mm.*(2*pi*fm).^2;

    ma = act*mt'*phi.^2;
    ca = 2*zetaa*ma*(2*pi*fa);
    ka = ma*(2*pi*fa)^2;
    pa = act*mt'*phi;

    mp = (1-act)*mt'*phi.^2;
    cp = 2*zetap*mp*(2*pi*fp);
    kp = mp*(2*pi*fp)^2;


    % integrate modal responses
    am = zeros(size(phi,2),length(p));
    for j=1:size(phi,2)
        if(ma(j)>=1e-9) % ensure nonsingular matrix
            if(act~=1)
                msys = [mm(j) 0 0; 0 ma(j) 0; 0 0 mp(j)];
                csys = [cm(j)+ca(j)+cp(j) -ca(j) -cp(j); -ca(j) ca(j) 0; -cp(j) 0 cp(j)];
                ksys = [km(j)+ka(j)+kp(j) -ka(j) -kp(j); -ka(j) ka(j) 0; -kp(j) 0 kp(j)];
                psys = [-pa(j); pa(j); 0] * p;
            else
                msys = [mm(j) 0; 0 ma(j)];
                csys = [cm(j)+ca(j) -ca(j); -ca(j) ca(j)];
                ksys = [km(j)+ka(j) -ka(j); -ka(j) ka(j)];
                psys = [-pa(j); pa(j)] * p;
            end

            [~,~,asys] = getStructuralDynamicResponse(msys,csys,ksys,psys,dt);
            am(j,:) = asys(1,:);
        end
    end


    % compute max 1-second RMS with non-overlapping window
    arms = zeros(size(phi,1),1);

    rmslen = round(1.0/dt);
    rmsoff = round(1.0/dt);
    rmssteps = floor((length(p)-rmslen)/rmsoff);
    for i=1:size(phi,1)
        a = phi(i,:)*am;
        for w=1:rmssteps
            lower = (w-1)*rmsoff+1;
            upper = (w-1)*rmsoff+rmslen;
            arms(i) = max(arms(i), sqrt(sum(a(lower:upper).^2)/rmslen));
        end
    end

end
