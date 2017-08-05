% FSLNets - simple network matrix estimation and applications
% Example script


% !!!! first run ". use_fsl 5" into the bash shell before opening this matlab
% the randomize used by fslnets must be of FSL 5.0.9

% change the following paths according to your local setup
matlab_code_path = '/media/data/MRI/scripts/matlab';
addpath(fullfile(matlab_code_path, 'FSLNets', 'package'));      % wherever you've put this package
addpath(fullfile(matlab_code_path, 'L1precision'));             % L1 precision toolbox
addpath(fullfile(matlab_code_path, 'pwling'));                  % pairwise causality toolbox
addpath('/media/data/MRI/scripts/matlab/FSLNets');              % path to fslnets common scripts

addpath(sprintf('%s/etc/matlab', getenv('FSLDIR')))             % you don't need to edit this if FSL is setup already


template_4mm    = '/media/data/MRI/scripts/data_templates/gray_matter/MNI152_T1_4mm_brain';

% setup the names of the directories containing your group-ICA and dualreg outputs
group_maps      = '/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects77_baseline_aroma/melodic_IC';              % spatial maps 4D NIFTI file, e.g. from group-ICA
ts_dir          = '/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/dr/templ_subjects80_baseline_aroma/subjects77_baseline_aroma';      % dual regression output directory, containing all subjects' timeseries

% output folder root for netweb output
netweb_root_path = fullfile(ts_dir, 'results' , 'fslnets_netweb');
% cleanup and remove bad nodes' timeseries (whichever is not listed in ts.DD is *BAD*).
rsn_labels      = {'V1' 'DMN' 'L_ATN' 'L_VIS' 'aDMN' 'R_ATN' 'X_BFP' 'aDMN2' 'X_SM' 'DORSAL' 'pDMN3' 'X_pDMN2' 'EXEC' 'VTP' 'EXEC2' 'X_BFP2'};  
good_nodes      = [1 2 3 4 5 6 7 8 9 10 13 15 22];  % list the good nodes in your group-ICA output (counting starts at 1, not 0)
% ts.UNK=[10];  optionally setup a list of unknown components (where you're unsure of good vs bad)

glm_folder      = '/media/dados/MRI/projects/temperamento_murcia/group_analysis/glm_models/77ctrl';
glm_designs     = {'mult_cov_age', 'mult_cov_gender_x_age'};
% glm_designs     = {'mult_cov_PT_matrices_kbit_x_age', 'mult_cov_PT_vocab_kbit_x_age', 'mult_cov_PT_CI_kbit_x_age'};
% glm_designs     = {'mult_cov_brevesmate_WM_x_age', 'mult_cov_ampliasmate_WM_x_age'};
% glm_designs     = {'mult_cov_razonmate_WM_x_age'};
% glm_designs     = {'mult_cov_EmoCtrl_EF_x_age', 'mult_cov_Smonit_EF_x_age', 'mult_cov_Shift_EF_x_age', 'mult_cov_MetaCogId_EF_x_age', 'mult_cov_WM_EF_x_age'};
len_ds          = length(glm_designs);

con_names       = {'pos corr', 'neg corr'};
tr_value        = 1.888;
variance_norm   = 1;
method          = 'pcorr';
show_graphs     = 0;
p_threshold     = 0.05;   ... if 0, don't show significant edges

% you must have already run the following (outside MATLAB), to create summary pictures of the maps in the NIFTI file:
if not(exist([group_maps '.sum'], 'file'))
    system(['slices_summary ' group_maps ' 4 ' template_4mm ' ' group_maps '.sum']);
end

%========================================================================================================================================================================================
prepare_data    = 1;
check_data      = 1;
do_stats        = 1;
%========================================================================================================================================================================================
%========================================================================================================================================================================================
%========================================================================================================================================================================================
%========================================================================================================================================================================================
if prepare_data
    ts = fslnets_prepare_data(group_maps, ts_dir, tr_value, variance_norm, good_nodes, show_graphs);
end

if check_data
    [netmat_full, znet_full, netmat, znet] = fslnets_create_netmat(ts, method, group_maps, rsn_labels, show_graphs, fullfile(netweb_root_path, method));
end

if do_stats
    
    p_uncorrected   = cell(1, len_ds);
    p_corrected     = cell(1, len_ds);
    for ds=1:len_ds
        design_glm                              = fullfile(glm_folder, glm_designs{ds});
        [p_uncorrected{ds}, p_corrected{ds}]    = fslnets_test_glm(netmat, design_glm);
        
        if p_threshold
            ncon=size(p_corrected{ds},1);
            for con=1:ncon
                nets_edgepics_overthreshold(ts, group_maps, znet_full, reshape(p_corrected{ds}(con,:),ts.Nnodes,ts.Nnodes), p_threshold);
            end
        end          
    end
		signif_res = fslnets_get_overthreshold_pairs(p_corrected, p_threshold,'glm_designs', glm_designs, 'con_names', con_names);    
end



