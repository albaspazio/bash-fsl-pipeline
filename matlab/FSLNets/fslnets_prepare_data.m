%% function fslnets_prepare_data(group_maps, tr_value, variance_norm)
% FSLNets - simple network matrix estimation and applications
% FMRIB Analysis Group
% Copyright (C) 2012-2014 University of Oxford
% See documentation at  www.fmrib.ox.ac.uk/fsl
%
% group_maps    : setup the names of the directories containing your group-ICA and dualreg outputs:     your-group-ICA.ica/melodic_IC';     % spatial maps 4D NIFTI file, e.g. from group-ICA
% ts_dir        : dual regression output directory, containing all subjects' timeseries                 'groupICA.dr';                           
% tr_value      : is the TR (in seconds)
% variance_norm : controls variance normalisation: 0=none, 1=normalise whole subject stddev, 2=normalise each separate timeseries from each subject
% good_nodes    : list the good nodes in your group-ICA output (counting starts at 1, not 0)            [1 2 3 5 7 9 10 12 13 15 ...]
%%  
function ts = fslnets_prepare_data(group_maps, ts_dir, tr_value, variance_norm, good_nodes, show_graphs)

    %%% load timeseries data from the dual regression output directory
    ts          = nets_load(ts_dir,tr_value,variance_norm);
    if show_graphs
        ts_spectra  = nets_spectra(ts);   % have a look at mean timeseries spectra
    end


    % cleanup and remove bad nodes' timeseries (whichever is not listed in ts.DD is *BAD*).
    ts.DD       = good_nodes;  % 
    % ts.UNK=[10];  optionally setup a list of unknown components (where you're unsure of good vs bad)
    ts          = nets_tsclean(ts,1);   % regress the bad nodes out of the good, and then remove the bad nodes' timeseries (1=aggressive, 0=unaggressive (just delete bad)).
                                        % For partial-correlation netmats, if you are going to do nets_tsclean, then it *probably* makes sense to:
                                        %    a) do the cleanup aggressively,
                                        %    b) denote any "unknown" nodes as bad nodes - i.e. list them in ts.DD and not in ts.UNK
                                        %    (for discussion on this, see Griffanti NeuroImage 2014.)
    if show_graphs
        nets_nodepics(ts,group_maps);       % quick views of the good and bad components
        ts_spectra  = nets_spectra(ts);     % have a look at mean spectra after this cleanup
    end

end
