
%% function create_netmat(ts, method, spatial_maps, netweb_dir)
% create full correlation network matrix and one map at choice (optionally convert correlations to z-stats).
% the output has one row per subject; within each row, the net matrix is unwrapped into 1D.
% the r2z transformation estimates an empirical correction for autocorrelation in the data.
%%
function [netmat_full, Znet_full, netmat, Znet] = fslnets_create_netmat(ts, method, spatial_maps, rsn_labels, show_graphs, netweb_dir)

    netmat_full             = nets_netmats(ts,1,'corr');        % full correlation (normalised covariances)
    [Znet_full, Mnet_full]  = nets_groupmean(netmat_full, show_graphs);   % get group full corr maps ; returns Z values from one-group t-test and group-mean netmat
    
    
    switch method
        case 'cov'
            netmat     = nets_netmats(ts,0,'cov');        % covariance (with variances on diagonal)
        case 'amp'
            netmat     = nets_netmats(ts,0,'amp');        % amplitudes only - no correlations (just the diagonal)
        case 'pcorr'     
            netmat     = nets_netmats(ts,1,'icov');       % partial correlation
        case 'prcov'
            netmat     = nets_netmats(ts,1,'icov',10);    % L1-regularised partial, with lambda=10
        case 'ridgepreg'
            netmat     = nets_netmats(ts,1,'ridgep');     % Ridge Regression partial, with rho=0.1
        case 'hyv_pw_caus'
            netmat     = nets_netmats(ts,0,'pwling');     % Hyvarinen's pairwise causality measure
    end

    % view of consistency of netmats across subjects; returns t-test Z values as a network matrix
    % second argument (0 or 1) determines whether to display the Z matrix and a consistency scatter plot
    % third argument (optional) groups runs together; e.g. setting this to 4 means each group of 4 runs were from the same subject
    [Znet, Mnet]    = nets_groupmean(netmat, show_graphs);   % test whichever netmat you're interested in; returns Z values from one-group t-test and group-mean netmat

    % view hierarchical clustering of nodes
    % arg1 is shown below the diagonal (and drives the clustering/hierarchy); arg2 is shown above diagonal
    if show_graphs
        nets_hierarchy(Znet_full, Znet, ts.DD, spatial_maps, rsn_labels); 
    end

    % view interactive netmat web-based display
    nets_netweb(Znet_full, Znet, ts.DD, spatial_maps, netweb_dir);

end


