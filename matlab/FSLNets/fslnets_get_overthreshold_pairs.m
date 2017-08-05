function results = fslnets_get_overthreshold_pairs(pmatrix, threshold, varargin)

    num_design  = length(pmatrix);
    num_con     = size(pmatrix{1},1);
    num_elem    = length(pmatrix{1}(1,:));
    num_nodes   = sqrt(num_elem);

    % init design & contrast labels
    glm_designs = {};
    for ds=1:num_design
        glm_designs = [glm_designs num2str(ds)];
    end
    
    con_names = {};
    for c=1:num_con
        con_names = [con_names num2str(c)];
    end    
    
    for par=1:2:length(varargin)
        switch varargin{par}
            case {'glm_designs', 'con_names'}

                if isempty(varargin{par+1})
                    continue;
                else
                    assign(varargin{par}, varargin{par+1});
                end
        end
    end    


    
    results     = cell(num_design,num_con); 
    for ds=1:num_design
        for c=1:num_con
            net             = reshape(pmatrix{ds}(c,:), num_nodes, num_nodes);
            net             = abs(net);
            net(tril(ones(size(net,1)))==1)=0;  % get info on upper tri only
            [yy,ii]         = sort(net(:),'descend');     % find strongest showN edges
            
            results{ds,c}   = {};
            for iii=1:num_elem
                if (yy(iii) >= (1-threshold))
                    xxx     = ceil(ii(iii)/size(net,1));  
                    yyy     = ii(iii)-((xxx-1)*size(net,1));
                    
                    results{ds,c} = [results{ds,c} ['des:' glm_designs{ds} ', contr:' con_names{c} ' edges:' num2str(xxx) '-' num2str(yyy) ', p = ' num2str(1-yy(iii))]];
                end
            end
        end
    end

end