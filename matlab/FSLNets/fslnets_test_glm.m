function [p_uncorrected,p_corrected] = fslnets_test_glm(netmat, design_path, varargin)

    view_edge = 6;
    strongest = 0;
    
    options_num=size(varargin,2);
    for opt=1:2:options_num
        switch varargin{opt}
            case 'view_edge'
                view_edge = varargin{opt+1};
            case 'strongest'
                strongest = varargin{opt+1};
        end
    end    
    
    design_m = [design_path '.mat'];
    design_c = [design_path '.con'];
    
    % pre-masking that tests only the connections that are strong on average across all subjects.
    % change the "strongest" to a different tstat threshold to make this sparser or less sparse.
    if strongest
        [grotH,grotP,grotCI,grotSTATS]              = ttest(netmat);  
        netmat(:, abs(grotSTATS.tstat) < strongest) = 0;
    end
    
    %%% cross-subject GLM, with inference in randomise (assuming you already have the GLM design.mat and design.con files).
    %%% arg4 determines whether to view the corrected-p-values, with non-significant entries removed above the diagonal.
    [p_uncorrected,p_corrected] = nets_glm(netmat, design_m, design_c, 1);  % returns matrices of 1-p
    
end
% 

% 
%     %%% simple cross-subject multivariate discriminant analyses, for just two-group cases.
%     %%% arg1 is whichever netmats you want to test.
%     %%% arg2 is the size of first group of subjects; set to 0 if you have two groups with paired subjects.
%     %%% arg3 determines which LDA method to use (help nets_lda to see list of options)
%     [lda_percentages]=nets_lda(netmats3,36,1)
% 
% 
%     %%% create boxplots for the two groups for a network-matrix-element of interest (e.g., selected from GLM output)
%     %%% arg3 = matrix row number,    i.e. the first  component of interest (from the DD list)
%     %%% arg4 = matrix column number, i.e. the second component of interest (from the DD list)
%     %%% arg5 = size of the first group (set to -1 for paired groups)
%     nets_boxplots(ts,netmats3,1,7,36);
%     %print('-depsc',sprintf('boxplot-%d-%d.eps',IC1,IC2));  % example syntax for printing to file
% 
% 
% 
