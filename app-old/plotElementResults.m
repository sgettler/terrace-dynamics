function plotElementResults( nodedefs, elemdefs, xlim, ylim, z, zlim, fname )
%plotMTVVResponse plots MTVV values to an enhanced metafile
%
%   date modified: 2013-08-23 - SG
%
% plotElementResults(nodedefs,elemdefs,z,xlim,ylim,zlim,fname) 
%
%   nodedefs = node definitions, n*4 (num, x, y, z)
%   elemdefs = element definitions, e*4 (num1 num2 num3 num4)
%   xlim, ylim = x and y limits
%   z = result to plot, n*1
%   zlim = color bar limits
%   fname = filename to which to save the figure

    
    % plot figure
    figure();
    axes('DataAspectRatio',[1 1 4]);
    hold(gca,'all');
    
    for e=1:size(elemdefs,1)
        idx = zeros(4,1);
        for n=1:4
            idx(n) = find(nodedefs(:,1)==elemdefs(e,n));
        end
        if(idx(3)==idx(4))
            idx = idx(1:3);
        end
        
        if(det([nodedefs(idx(2:3),2)-nodedefs(idx(1:2),2) nodedefs(idx(2:3),3)-nodedefs(idx(1:2),3)])~=0)
            tri = delaunay(nodedefs(idx,2),nodedefs(idx,3));
            trisurf(tri,nodedefs(idx,2),nodedefs(idx,3),z(idx),'EdgeColor','k','LineWidth',0.1,'FaceColor','interp');
        end
    end
    view(0,90);
    
    set(gcf,'PaperPositionMode','auto','Units','inches','Position',[0 0 6.5 6]);
    set(gcf,'Color','w');
        
    set(gca,'Units','inches','Position',[0 0 6 6]);
    set(gca,'Box','on','Visible','off','XLim',xlim,'YLim',ylim,'ZLim',zlim,'CLim',zlim);

    hcbr = colorbar();
    set(hcbr,'YLim',zlim);
    
    print(gcf,'-r1200','-dpng',fname);
    close(gcf);
    
end

