%% function [netmat] = nets_edgepics_overthreshold(ts,group_maps,meannetmat,net,threshold,varargin)
% show the netmat elements whose pvalue is below the requested threshold
%
% ts:           is the node timeseries structure
% group_maps:   is a string pointing to the thumbnail images folder
% meannetmat:   is typically the group-mean or group-mean-Z netmat, used just to generate the coloured bars connecting the two nodes in each edge
% net:          is the connecitivy matrix
% threshold     is the statistical threshold (usually 0.05)
%%
function [netmat] = nets_edgepics_overthreshold(ts,group_maps,meannetmat,net,threshold,varargin)    %%%% show a snapshot of the kept and rejected components

    max_images      = 5;
    decimalplaces   = -1;
    design_label    = '??';
    
    options_num=size(varargin,2);
    for opt=1:2:options_num
        switch varargin{opt}
            case 'decimalplaces'
                decimalplaces = varargin{opt+1};
            case 'design_label'
                design_label = varargin{opt+1};
        end
    end
    
    netORIG         = net;
    net             = abs(net);
    net(tril(ones(size(net,1)))==1)=0;   % get info on upper tri only
    meannetmat      = max(min(meannetmat/prctile(abs(meannetmat(:)),90),1),-1);
    grott           = sprintf('%s.png',tempname);


    [grotA,grotB,grotC] = fileparts(group_maps); if size(grotA,1)==0, grotA='.'; end; group_maps=sprintf('%s/%s.sum',grotA,grotB);

    [yy,ii]             = sort(net(:),'descend');   % find strongest showN edges
    num_elem            = length(yy);
    xf                  = ceil(1.15*sqrt(max_images)); yf=ceil(max_images/xf);   % dimensions of display tiling

    XX=1200; YY= 500; % total image size

    bd=15; bdx=bd/XX; bdy=bd/YY; % borders size
    el=10/XX; % edge lengths
    th=20/YY; % title height
    isx=(1-(xf+1)*bdx-xf*el)/(2*xf);  isy=(1-(yf+1)*bdy-yf*th)/yf;

    gap=0;
    if exist('octave_config_info')~=0  % because octave has a stupid subplot bug
      gap=0.0001;
    end;

    YY=(109/91) * (isx*XX) / isy;

    
    if max(yy) > (1-threshold)
        figure('Position',[10 10 XX YY]); 
        
        for iii=1:num_elem
            if yy(iii) > (1-threshold)

                xxx=ceil(ii(iii)/size(net,1));  yyy=ii(iii)-((xxx-1)*size(net,1));
                yfi=ceil(iii/xf); xfi=iii-((yfi-1)*xf); yfi=1+yf-yfi;   [xxx yyy xfi yfi];

                call_fsl(sprintf('slices_summary %s %s %s',group_maps,grott,num2str(ts.DD([xxx])-1)));  picgood=imread(grott);
                subplot('position',[xfi*bdx+(xfi-1)*(2*isx+el) yfi*bdy+(yfi-1)*(isy+th) isx-gap isy-gap]);
                imagesc(picgood); axis off; axis equal;

                call_fsl(sprintf('slices_summary %s %s %s',group_maps,grott,num2str(ts.DD([yyy])-1)));  picgood=imread(grott);
                subplot('position',[xfi*bdx+(xfi-1)*(2*isx+el)+isx+el yfi*bdy+(yfi-1)*(isy+th) isx-gap isy-gap]);
                imagesc(picgood); axis off; axis equal;

                grot=meannetmat(yyy,xxx); eh=abs(grot)*0.5*isy; [grot eh];
                subplot('position',[xfi*bdx+(xfi-1)*(2*isx+el)+isx yfi*bdy+(yfi-1)*(isy+th)+isy/2-eh/2 el-gap eh]);
                imagesc(sign(grot)-0.5,[-.8 .8]); axis off; daspect('auto');

                subplot('position',[xfi*bdx+(xfi-1)*(2*isx+el) yfi*bdy+(yfi-1)*(isy+th)+isy 2*isx+el th]); axis off;
                if netORIG(yyy,xxx)>0
                  grot='red';
                else
                  grot='blue';
                end

                if decimalplaces<0
                    title({sprintf('design: %s       sorted edge #%d   nodes=%d,%d',design_label,iii,xxx,yyy),sprintf('\\fontsize{12}\\color{%s}value=%f',grot,netORIG(yyy,xxx))},'Position',[0.5 0.1]);
                else
                    title({sprintf('design: %s       sorted edge #%d   nodes=%d,%d',design_label,iii,xxx,yyy),sprintf('\\fontsize{12}\\color{%s}value=%.2f',grot,netORIG(yyy,xxx))},'Position',[0.5 0.1]);
                end
            end
        end
    end
    set(gcf,'PaperPositionMode','auto'); 
end

