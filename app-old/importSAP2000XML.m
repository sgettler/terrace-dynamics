function [fm,phi,nodedefs,elemdefs] = importSAP2000XML(fnin)
%importSAP2000 returns FEA results from SAP2000 XML output files
%
%   date modified: 2016-07-20 SG
%
% importSAP2000XML() returns the frequencies, mode shapes, and node and
% element definitions from SAP output files.
%
% Inputs:
%   fnin = filename for XML results file (must be full path)
%
% Outputs:
%   fm = modal frequencies, 1*m (Hz)
%   phi = mode shapes, n*m (-)
%   nodedefs = node definitions, n*4 [num, x, y, z] (m)
%   elemdefs = element definitions, e*4 [num1, num2, num3, num4] (-)
%
% Data file is not checked for a complete data set!


    % use Java XML parsing
    import javax.xml.parsers.*;
    import javax.xml.xpath.*;
    
    domFactory = DocumentBuilderFactory.newInstance();
    domBuilder = domFactory.newDocumentBuilder();
    doc = domBuilder.parse(fnin);
    
    xpathFactory = XPathFactory.newInstance();
    xpath = xpathFactory.newXPath();
    
    
    % import program info and units
    xlist = xpath.compile('NewDataSet/Program_x0020_Control').evaluate(doc,XPathConstants.NODESET);
    progname = char(xlist.item(0).getElementsByTagName('ProgramName').item(0).getFirstChild().getData());
    progver = char(xlist.item(0).getElementsByTagName('Version').item(0).getFirstChild().getData());
    fprintf(['    Importing results from ' progname ' ' progver '...\n']);
    
    progunits = strsplit(char(xlist.item(0).getElementsByTagName('CurrUnits').item(0).getFirstChild().getData()),', ');
    unit = {'in' 'ft' 'mm' 'cm' 'm'};
    conv = [0.0254 0.3048 0.001 0.01 1.0];
    unitconv = conv(strcmp(progunits(2),unit));
    

    % import frequencies
    fprintf('      importing modal frequencies\n');
    
    xlist = xpath.compile('NewDataSet/Modal_x0020_Periods_x0020_And_x0020_Frequencies').evaluate(doc,XPathConstants.NODESET);
    fm = zeros(1,xlist.getLength());
    fnum = zeros(1,xlist.getLength());
    for i=1:xlist.getLength()
        fm(i) = str2double(char(xlist.item(i-1).getElementsByTagName('Frequency').item(0).getFirstChild().getData()));
        fnum(i) = str2double(char(xlist.item(i-1).getElementsByTagName('StepNum').item(0).getFirstChild().getData()));
    end

    
    % import joints; correct for auto-meshed joints numbered "~1" etc
    fprintf('      importing node definitions\n');
    
    xlist = xpath.compile('NewDataSet/Objects_x0020_And_x0020_Elements_x0020_-_x0020_Joints').evaluate(doc,XPathConstants.NODESET);    
    nodeoffset = 1;
    for i=1:xlist.getLength()
        nodestr = char(xlist.item(i-1).getElementsByTagName('JointElem').item(0).getFirstChild().getData());
        if(isempty(strfind(nodestr,'~')))
            nodeoffset = max(nodeoffset,str2double(nodestr));
        end
    end

    nodedefs = zeros(xlist.getLength(),4);
    for i=1:xlist.getLength()
        nodestr = char(xlist.item(i-1).getElementsByTagName('JointElem').item(0).getFirstChild().getData());
        if(isempty(strfind(nodestr,'~')))
            nodedefs(i,1) = str2double(nodestr);
        else
            nodedefs(i,1) = nodeoffset+str2double(nodestr(2:end));
        end
        
        nodedefs(i,2) = unitconv*str2double(char(xlist.item(i-1).getElementsByTagName('GlobalX').item(0).getFirstChild().getData()));
        nodedefs(i,3) = unitconv*str2double(char(xlist.item(i-1).getElementsByTagName('GlobalY').item(0).getFirstChild().getData()));
        nodedefs(i,4) = unitconv*str2double(char(xlist.item(i-1).getElementsByTagName('GlobalZ').item(0).getFirstChild().getData()));
    end

    
    % import areas
    fprintf('      importing element definitions\n');
    
    xlist = xpath.compile('NewDataSet/Objects_x0020_And_x0020_Elements_x0020_-_x0020_Areas').evaluate(doc,XPathConstants.NODESET);    
    elemdefs = zeros(xlist.getLength(),4);
    areanum = zeros(xlist.getLength(),1);
    for i=1:xlist.getLength()
        
        for j=1:4
            if(xlist.item(i-1).getElementsByTagName(['ElemJt' num2str(j)]).getLength()~=0)
                nodestr = char(xlist.item(i-1).getElementsByTagName(['ElemJt' num2str(j)]).item(0).getFirstChild().getData());
                if(isempty(strfind(nodestr,'~')))
                    elemdefs(i,j) = str2double(nodestr);
                else
                    elemdefs(i,j) = nodeoffset+str2double(nodestr(2:end));
                end
            else
                elemdefs(i,j) = elemdefs(i,j-1);
            end
        end
        areanum(i,1) = str2double(char(xlist.item(i-1).getElementsByTagName('AreaObject').item(0).getFirstChild().getData()));
    end
    
    
    % filter for tread area group SPS_TREAD if it exists
    xlist = xpath.compile('NewDataSet/Groups_x0020_2_x0020_-_x0020_Assignments').evaluate(doc,XPathConstants.NODESET);
    treadareas = zeros(xlist.getLength(),1);
    for i=1:xlist.getLength()
        if(strcmp('SPS_TREAD',char(xlist.item(i-1).getElementsByTagName('GroupName').item(0).getFirstChild().getData())))
            treadareas(i) = str2double(char(xlist.item(i-1).getElementsByTagName('ObjectLabel').item(0).getFirstChild().getData()));
        end
    end
    treadareas = treadareas(treadareas~=0,:);

    elemmask = ones(size(elemdefs,1),1);
    if(~isempty(treadareas))
        elemmask = zeros(size(elemdefs,1),1);
        for i=1:length(treadareas)
            elemmask = elemmask+1*(areanum==treadareas(i));
        end        
        fprintf(['        ' num2str(sum(elemmask)) ' areas included (of ' num2str(length(elemmask)) ' total)\n']);
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
    
    xlist = xpath.compile('NewDataSet/Joint_x0020_Displacements').evaluate(doc,XPathConstants.NODESET);
    phi = zeros(size(nodedefs,1),size(fm,2));
    toc0 = toc;
    for i=1:xlist.getLength()
        if(i==1)
            fprintf(['        record 1 of ' num2str(xlist.getLength()) '\n']);
        elseif(i~=1 && mod(i-1,floor(xlist.getLength()/10))==0)
            fprintf(['        record ' num2str(i) ' of ' num2str(xlist.getLength()) ' (estimated ' num2str((xlist.getLength()/(i-1)-1)*(toc-toc0)/60) ' min remaining)\n']);
        end

        nodestr = char(xlist.item(i-1).getElementsByTagName('Joint').item(0).getFirstChild().getData());
        nodenum = 0;
        if(isempty(strfind(nodestr,'~')))
            nodenum = str2double(nodestr);
        else
            nodenum = nodeoffset+str2double(nodestr(2:end));
        end
        stepnum = str2double(char(xlist.item(i-1).getElementsByTagName('StepNum').item(0).getFirstChild().getData()));
        
        phi(nodedefs(:,1)==nodenum,fnum==stepnum) = unitconv*str2double(char(xlist.item(i-1).getElementsByTagName('U3').item(0).getFirstChild().getData()));
    end

    nodedefs = nodedefs(nodemask==1,:);
    phi = phi(nodemask==1,:);
    
    
    fprintf('    done.\n');

end
