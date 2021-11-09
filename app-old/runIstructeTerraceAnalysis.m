function runIstructeTerraceAnalysis()%slim)
%runIstructeTerraceAnalysis runs analysis comptations for terrace vibration
%
%   date modified: 2016-07-20 SG
%
% runTerraceAnalysis() runs analysis computations for terrace
% vibration based on ANSYS output data. Predicted response is computed
% using the iStructE method.
%
%   slim = vector of iStructE scenario numbers (2-4) to run
%
% This function outputs a series of figures and results to file, echoes a log to
% the command window/console, and saves the log to file.

    slim = [2 3 4]; % build version runs all scenarios

    % log output to file
    diary(['log' datestr(now,30) '.txt']);
    fprintf('\n');
    fprintf('  SPS Terraces IStructE Dynamic Analysis v1.0\n');
    fprintf('  -------------------------------------------\n');
    fprintf('\n');
    fprintf(['    ' datestr(now,0) '\n']);
    if(length(slim)==1)
        fprintf(['    Scenario ' num2str(min(slim)) '\n']);
    else
        fprintf(['    Scenarios ' num2str(min(slim)) '-' num2str(max(slim)) '\n']);
    end
    fprintf('\n');
    tic;


    % import FEA results
    %[fnin,pnin,~] = uigetfile({'*.mdb;*.ans','All FEA Results (*.mdb,*.ans)';'*.mdb','SAP2000 Results (*.mdb)';'*.ans','ANSYS Results (*.ans)';'*.*','All Files (*.*)'});
    [fnin,pnin,~] = uigetfile({'*.mdb;*.xml;*.ans','All FEA Results (*.mdb,*.xml,*.ans)';'*.mdb','SAP2000 Results (*.mdb)';'*.xml','SAP2000 XML Results (*.xml)';'*.ans','ANSYS Results (*.ans)';'*.*','All Files (*.*)'});
    fprintf(['    ' fnin '\n']);
    fprintf('\n');
    
    fnext = strsplit(fnin,'.');
    if(strcmp(cell2mat(fnext(end)),'ans')) % assume ANSYS
        [fm,phi,nodedefs,elemdefs] = importANSYS([pnin fnin]);
    elseif(strcmp(cell2mat(fnext(end)),'xml')) % assume SAP2000 XML
        [fm,phi,nodedefs,elemdefs] = importSAP2000XML([pnin fnin]);
    elseif(strcmp(cell2mat(fnext(end)),'mdb')) % assume SAP2000
        [fm,phi,nodedefs,elemdefs] = importSAP2000([pnin fnin]);
    end
    mm = ones(1,size(phi,2));


    % compute node areas
    nodearea = zeros(size(nodedefs,1),1);
    for e=1:size(elemdefs,1)
        idx = zeros(4,1);
        for n=1:4
            idx(n) = find(nodedefs(:,1)==elemdefs(e,n));
        end
        nodearea(idx([1 2 3])) = nodearea(idx([1 2 3])) + 0.5*det([nodedefs(idx([1 2 3]),2:3) ones(3,1)])/3;
        nodearea(idx([1 3 4])) = nodearea(idx([1 3 4])) + 0.5*det([nodedefs(idx([1 3 4]),2:3) ones(3,1)])/3;
    end
    fprintf(['    total terrace area = ' num2str(sum(nodearea)) ' m2\n']);


    % compute crowd mass
    m_people = 80; % assumed mass of individual person (kg)
    dens_people = 0.4; % assumed density of crowd (people/m2)
    n_people = round(sum(nodearea)/dens_people);
    fprintf(['    estimated capacity = ' num2str(n_people) ' people\n']);
    nodemass = n_people*m_people*nodearea/sum(nodearea);


    % compute acceleration response
    fe = 1:0.05:3; % excitation frequency range (Hz)
    scrit = [0 3 7.5 20]; % rms criteria by scenario (%g)

    armsscenario = zeros(4,length(fe));
    for s=slim
        fprintf('\n');
        fprintf(['    Computing Scenario ' num2str(s) ' acceleration response...\n']);

        arms = getScenarioResponse(fm,mm,phi,nodemass,fe,s);

        fprintf('    done.\n');

        % display results
        armsmaxfreq = max(arms,[],1)/9.81*100;
        armsmaxnode = max(arms,[],2)/9.81*100;

        %armsmax = max(armsmaxfreq);
        armsscenario(s,:) = armsmaxfreq;

        fprintf(['    max RMS acceleration = ' num2str(max(armsmaxfreq)) ' %%g\n']);
        if(max(armsmaxfreq)>scrit(s))
            fprintf(['    exceeds criterion for scenario ' num2str(s) '!\n']);
        end

        % output results to file
        fprintf('\n');
        fprintf(['    Writing Scenario ' num2str(s) ' results to file... ']);
        if(~exist([pnin 'rms/s' num2str(s)],'dir'))
            mkdir([pnin 'rms/s' num2str(s)]);
        end
        for g=1:length(fe)
            armsout = arms(:,g); %#ok<NASGU>
            save([pnin 'rms/s' num2str(s) '/rms' num2str(g) '.txt'],'armsout','-ascii');
        end
        save([pnin 'scenario' num2str(s) '_rms.txt'],'armsmaxfreq','-ascii');
        fprintf('done.\n');

        % output figures
        fprintf('\n');
        fprintf(['    Writing Scenario ' num2str(s) ' images to file... ']);
        plotMTVVResponse(fe,armsmaxfreq,cellstr(['Scenario ' num2str(s)]),[pnin 'scenario' num2str(s) '_rms.emf']);
        xext = max(nodedefs(:,2))-min(nodedefs(:,2));
        yext = max(nodedefs(:,3))-min(nodedefs(:,3));
        xlim = (min(nodedefs(:,2))+max(nodedefs(:,2)))/2+max(xext,yext)*[-0.5 0.5]*1.05;
        ylim = (min(nodedefs(:,3))+max(nodedefs(:,3)))/2+max(xext,yext)*[-0.5 0.5]*1.05;
        plotElementResults(nodedefs,elemdefs,xlim,ylim,armsmaxnode,[0 max(max(armsmaxnode),scrit(s))],[pnin 'scenario' num2str(s) '_rms_map.png']);
        %plotElementResults(nodedefs,elemdefs,[-60 60],[-60 60],armsmaxnode,[0 scrit(s)],[pnin 'scenario' num2str(s) '_rms_map.png']);
        fprintf('done.\n');
    end

    % output composite figure
    if(length(slim)>1)
        fprintf('\n');
        fprintf('    Writing composite image to file... ');
        plotMTVVResponse(fe,armsscenario(slim,:),cellstr([ones(length(slim),1)*'Scenario ' num2str(slim')]),[pnin 'scenario_composite_rms.emf']);
        fprintf('done.\n');
    end


    % finish logging
    fprintf('\n');
    fprintf(['    Analysis complete! Elapsed time ' num2str(floor(toc/60)) ' min ' num2str(round(mod(toc,60))) ' sec.\n\n']);
    diary off

end
