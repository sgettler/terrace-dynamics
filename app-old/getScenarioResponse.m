function [arms] = getScenarioResponse(fm,mm,phi,mt,fe,s)
%getScenarioResponse returns respose to scenario loading
%
%   date modified: 2016-01-21 - SG
%
% getScenarioResponse() returns the maximum calculated RMS accelerations for the
% provided n-degree of freedom system subject to crowd-structure dynamic
% interaction as specified by IStructE (2008) for the provided excitation
% frequencies.
%
% The acceleration response time series is computed based on a generated force
% time series, and a root-mean-square average of the acceleration response is
% returned.
%
% Inputs:
%   fm = modal frequencies, 1*m (Hz)
%   mm = modal masses, 1*m (kg)
%   phi = mode shapes, n*m (-)
%   fe = excitation frequencies, 1*f (Hz)
%   s = scenario number (-)
%
% Outputs:
%   arms = RMS acceleration, n*f (m/s2)
%
% The returned maximum RMS accelerations correspond to the input excitation
% frequencies.
%
% References:
%   IStructE (2008). "Dynamic performance requirements for permanent grandstands
%       subject to crowd action: Recommendations for management, design and
%       assessment." The Institution of Structural Engineers: London, UK.


    % generated force parameters
    GLF1 = [0 0.12  0.188 0.375]; % excitation GLFs by scenario
    GLF2 = [0 0.015 0.047 0.095];
    GLF3 = [0 0     0.013 0.026];
    GLF = [GLF1; GLF2; GLF3]';

    act = [0 1 1 1]; % fraction of people active by scenario


    % compute response for excitation frequencies
    arms = zeros(size(phi,1),length(fe));
    toc0 = toc;
    for g=1:length(fe)

        % output computation time estimate
        if(g==1)
            fprintf(['      computing frequency 1 of ' num2str(length(fe)) '\n']);
        elseif(g~=1 && mod(g-1,min(floor(length(fe)/5),10))==0)
            fprintf(['      computing frequency ' num2str(g) ' of ' num2str(length(fe)) ' (est. ' num2str((length(fe)/(g-1)-1)*(toc-toc0)/60) ' min remaining)\n']);
        end

        % find required timestep
        fmax = max(max(fm),3*fe(g));
        tres = 4;
        dt = 10^floor(log10(1/(fmax*tres)));

        % generate force time series of length 10s
        t = 0:dt:10;
        rho = exp(-2*(fe(g)-1.8)^2);
        if(s==4)
            rho = sech(fe(g)-2);
        end
        p = rho * 9.81 * GLF(s,:)*cos((1:3)'*2*pi*fe(g)*t);

        % get system response
        arms(:,g) = getCrowdStructureResponse(fm,mm,phi,mt,act(s),p,dt);
    end

end
