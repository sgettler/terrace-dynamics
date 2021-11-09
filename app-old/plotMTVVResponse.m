function plotMTVVResponse( fe, mtvv, lbl, fname )
%plotMTVVResponse plots MTVV values to an enhanced metafile
%
%   date modified: 2013-08-23 - SG
%
% plotMTVVResponse(fe,mtvv,lbl,fname) plots one or more sets of MTVV values
% and a legend to an enhanced metafile. Figure dimensions are 5" by 2.5"
% and font is 9pt Arial Narrow for inclusion in IE reports.
%
%   fe = frequency of excitation, 1*f (Hz)
%   mtvv = mtvv values by scenario, n*f (%g)
%   lbl = cell array of labels, n*1
%   fname = filename to which to save the figure


    figure();
    axes();
    hold(gca,'all');
    
    plot(fe,mtvv,'LineWidth',1.2);
    
    set(gcf,'PaperPositionMode','auto','Units','inches','Position',[0 0 5 2.5]);
    set(gcf,'Color','w');
        
    set(gca,'Units','inches','Position',[0.5 0.5 4.25 1.75]);
    set(gca,'Box','on','XLim',[fe(1) fe(end)],'XGrid','on','YLim',[0 20],'YGrid','on','GridLineStyle',':');

    hxlb = xlabel('Frequency of Excitation (Hz)');
    hylb = ylabel('Acceleration Response (%g)');
    hleg = legend(lbl,'Location','NortheastOutside');
 
    set([gca hxlb hylb hleg],'FontUnits','points','FontName','Arial Narrow','FontSize',9);
    
    print(gcf,'-r600','-dmeta',fname);
    close(gcf);
end

