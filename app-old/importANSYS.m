function [fm,phi,nodedefs,elemdefs] = importANSYS(fnin)
%importANSYS returns FEA results from ANSYS output files
%
%   date modified: 2016-09-21 SG
%
% importANSYS() returns the frequencies, mode shapes, and node and element
% definitions from ANSYS output files.
%
% Inputs:
%   fnin = filename for control file listing output data files
%
% Outputs:
%   fm = modal frequencies, 1*m (Hz)
%   phi = mode shapes, n*m (-)
%   nodedefs = node definitions, n*4 [num, x, y, z] (m)
%   elemdefs = element definitions, e*4 [num1 num2 num3 num4] (-)
%
% Control file and data files are not checked for valid format!


    ctrlfile = importdata(fnin);

    fprintf(['    Importing results from ' strtrim(cell2mat(ctrlfile(1))) '...\n']);

    fprintf('        modal frequencies\n');
    fm = importdata(strtrim(cell2mat(ctrlfile(2))));

    fprintf('        node definitions\n');
    nodedefs = importdata(strtrim(cell2mat(ctrlfile(4))));

    fprintf('        element definitions\n');
    elemdefs = importdata(strtrim(cell2mat(ctrlfile(5))));

    fprintf('        mode shapes\n');
    phi = importdata(strtrim(cell2mat(ctrlfile(3))));

    fprintf('    done.\n');

end
