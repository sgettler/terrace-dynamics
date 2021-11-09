function [fm,phi,nodedefs,elemdefs] = importSAP2000(fnin)
%importSAP2000 returns FEA results from SAP2000 output files
%
%   date modified: 2016-02-16 SG
%
% importSAP2000() returns the frequencies, mode shapes, and node and element
% definitions from SAP output files.
%
% Inputs:
%   fnin = filename for Microsoft Access mdb file (must be full path)
%
% Outputs:
%   fm = modal frequencies, 1*m (Hz)
%   phi = mode shapes, n*m (-)
%   nodedefs = node definitions, n*4 [num, x, y, z] (m)
%   elemdefs = element definitions, e*4 [num1, num2, num3, num4] (-)
%
% Data file is not checked for a complete data set!


    % open database connection
    dburl = ['jdbc:odbc:Driver={Microsoft Access Driver (*.mdb, *.accdb)};DSN=;DBQ=' fnin];
    db = database('','','','sun.jdbc.odbc.JdbcOdbcDriver',dburl);


    % import program info and units
    query = fetch(exec(db,'SELECT "ProgramName","Version","CurrUnits" FROM "Program Control"'));
    fprintf(['    Importing results from ' cell2mat(query.Data(1)) ' ' cell2mat(query.Data(2)) '...\n']);

    unitstr = strsplit(cell2mat(query.Data(3)),', ');
    unit = {'in' 'ft' 'mm' 'cm' 'm'};
    conv = [0.0254 0.3048 0.001 0.01 1.0];
    unitconv = conv(strcmp(unitstr(2),unit));


    % import frequencies
    fprintf('      importing modal frequencies\n');
    query = fetch(exec(db,'SELECT "Frequency" FROM "Modal Periods and Frequencies"'));

    fm = cell2mat(query.Data)';


    % import joints; correct for auto-meshed joints numbered "~1" etc
    fprintf('      importing node definitions\n');
    query = fetch(exec(db,'SELECT "JointElem","GlobalX","GlobalY","GlobalZ" FROM "Objects and Elements - Joints" ORDER BY "JointElem" ASC'));

    nodeoffset = 1;
    for i=1:size(query.Data,1)
        if(isempty(strfind(cell2mat(query.Data(i,1)),'~')))
            nodeoffset = max(nodeoffset,str2double(cell2mat(query.Data(i,1))));
        end
    end

    nodedefs = zeros(size(query.Data,1),4);
    for i=1:size(query.Data,1)
        if(isempty(strfind(cell2mat(query.Data(i,1)),'~')))
            nodedefs(i,1) = str2double(cell2mat(query.Data(i,1)));
        else
            autonode = cell2mat(query.Data(i,1));
            nodedefs(i,1) = nodeoffset+str2double(autonode(2:end));
        end
    end
    nodedefs(:,2:4) = cell2mat(query.Data(:,2:4))*unitconv;


    % import areas
    fprintf('      importing element definitions\n');
    query = fetch(exec(db,'SELECT "ElemJt1","ElemJt2","ElemJt3","ElemJt4","AreaObject" FROM "Objects and Elements - Areas"'));
    elemdefs = zeros(size(query.Data,1),4);
    areanum = cellfun(@str2double,query.Data(:,5));
    for h=1:size(query.Data,1)
        for i=1:4
            if(isempty(strfind(cell2mat(query.Data(h,i)),'~')))
                elemdefs(h,i) = str2double(cell2mat(query.Data(h,i)));
                if(isnan(elemdefs(h,i)))
                    elemdefs(h,i) = elemdefs(h,i-1);
                end
            else
                autonode = cell2mat(query.Data(h,i));
                elemdefs(h,i) = nodeoffset+str2double(autonode(2:end));
            end
        end
    end
    
    
    % filter for tread area group if it exists
    elemmask = ones(size(elemdefs,1),1);
    query = fetch(exec(db,'SELECT COUNT("ObjectLabel") FROM "Groups 2 - Assignments" WHERE "GroupName"=''SPS_TREAD'''));
    if(iscell(query.Data))
        numtreadareas = cell2mat(query.Data);
        if(numtreadareas~=0)
            query = fetch(exec(db,'SELECT "ObjectLabel" FROM "Groups 2 - Assignments" WHERE "GroupName"=''SPS_TREAD'''));
            treadareas = cellfun(@str2double,query.Data);

            elemmask = zeros(size(elemdefs,1),1);
            for i=1:length(treadareas)
                elemmask = elemmask+1*(areanum==treadareas(i));
            end        
            fprintf(['        ' num2str(sum(elemmask)) ' areas included (of ' num2str(length(elemmask)) ' total)\n']);
        end
    end
    elemdefs = elemdefs(elemmask==1,:);

    nodemask = zeros(size(nodedefs,1),1);
    for h=1:size(elemdefs,1)
        for i=1:4
            nodemask = nodemask+1*(nodedefs(:,1)==elemdefs(h,i));
        end
    end
    nodemask = 1*(nodemask>0);
    fprintf(['        ' num2str(sum(nodemask)) ' joints included (of ' num2str(length(nodemask)) ' total)\n']);

    
    % import mode shapes
    fprintf('      importing mode shapes\n');
    phi = zeros(size(nodedefs,1),size(fm,2));
    toc0 = toc;
    for j=1:size(fm,2)
        if(j==1)
            fprintf(['        mode 1 of ' num2str(size(fm,2)) '\n']);
        elseif(j~=1 && mod(j-1,min(floor(size(fm,2)/5),10))==0)
            fprintf(['        mode ' num2str(j) ' of ' num2str(size(fm,2)) ' (estimated ' num2str((size(fm,2)/(j-1)-1)*(toc-toc0)/60) ' min remaining)\n']);
        end

        query = fetch(exec(db,['SELECT "Joint","U3" FROM "Joint Displacements" WHERE "StepType"=''Mode'' AND "StepNum"=' num2str(j) ' ORDER BY "Joint" ASC']));

        phi(:,j) = cell2mat(query.Data(:,2))*unitconv;
    end

    nodedefs = nodedefs(nodemask==1,:);
    phi = phi(nodemask==1,:);
    
    
    % close database connection
    close(query);
    close(db);

    fprintf('    done.\n');

end
