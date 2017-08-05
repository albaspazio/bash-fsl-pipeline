
%% function create_netmat(ts, method, spatial_maps, netweb_dir)
% create full correlation network matrix and one map at choice (optionally convert correlations to z-stats).
% the output has one row per subject; within each row, the net matrix is unwrapped into 1D.
% the r2z transformation estimates an empirical correction for autocorrelation in the data.
%%
function [netmat_full, Znet_full_full, netmat, Znet] = fslnets_create_netmat_longitudinal_difference(ts, method, spatial_maps, rsn_labels, show_graphs, netweb_dir)
    if (length(ts) > 2)    
        netmat_full=[]; Znet_full=[];netmat=[]; Znet=[];
        return;
    else    
        
        for s=1:length(ts)
            netmat_full{s}                  = nets_netmats(ts(s),1,'corr');                 % full correlation (normalised covariances)
            [Znet_full{s}, Mnet_full{s}]    = nets_groupmean(netmat_full{s}, show_graphs);  % get group full corr maps ; returns Z values from one-group t-test and group-mean netmat

            switch method
                case 'cov'
                    nm{s}     = nets_netmats(ts(s),0,'cov');        % covariance (with variances on diagonal)
                case 'amp'
                    nm{s}     = nets_netmats(ts(s),0,'amp');        % amplitudes only - no correlations (just the diagonal)
                case 'pcorr'     
                    nm{s}     = nets_netmats(ts(s),1,'icov');       % partial correlation
                case 'prcov'
                    nm{s}     = nets_netmats(ts(s),1,'icov',10);    % L1-regularised partial, with lambda=10
                case 'ridgepreg'
                    nm{s}     = nets_netmats(ts(s),1,'ridgep');     % Ridge Regression partial, with rho=0.1
                case 'hyv_pw_caus'
                    nm{s}     = nets_netmats(ts(s),0,'pwling');     % Hyvarinen's pairwise causality measure
            end
        end
        
        % concatenated timeseries
        full_ts                     = ts(1);
        full_ts.ts                  = [ts(1).ts; ts(2).ts];
        netmat_full                 = nets_netmats(full_ts, 1, 'corr'); 
        [Znet_full_full, Mnet_full] = nets_groupmean(netmat_full, show_graphs);        
        netmat                      = nm{2} - nm{1};

        % view of consistency of netmats across subjects; returns t-test Z values as a network matrix
        % second argument (0 or 1) determines whether to display the Z matrix and a consistency scatter plot
        % third argument (optional) groups runs together; e.g. setting this to 4 means each group of 4 runs were from the same subject
        %[Znet1, Mnet1]      = nets_groupmean(nm{1}, show_graphs);   % test whichever netmat you're interested in; returns Z values from one-group t-test and group-mean netmat
        %[Znet2, Mnet2]      = nets_groupmean(nm{2}, show_graphs);   % test whichever netmat you're interested in; returns Z values from one-group t-test and group-mean netmat
        [Znet, Mnet]        = nets_groupmean(netmat, show_graphs);   % test whichever netmat you're interested in; returns Z values from one-group t-test and group-mean netmat

%         % view hierarchical clustering of nodes
%         % arg1 is shown below the diagonal (and drives the clustering/hierarchy); arg2 is shown above diagonal
%         if show_graphs
%             %nets_hierarchy(Znet_full{1},    Znet1, ts(1).DD, spatial_maps, rsn_labels); 
%             %nets_hierarchy(Znet_full{2},    Znet2, ts(2).DD, spatial_maps, rsn_labels); 
%             nets_hierarchy(Znet_full_full,  Znet,  ts(1).DD, spatial_maps, rsn_labels); 
%         end

%         % view interactive netmat web-based display
%         nets_netweb(Znet_full_full, Znet, ts(1).DD, spatial_maps, netweb_dir);
    end
end


