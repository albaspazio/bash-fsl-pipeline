#!/bin/bash

# (1) nuisance regression (WM, CSF)

flirt -in WM_mask_in_highres_space_eroded -applyxfm -init rest.feat/reg/highres2example_func.mat -ref  example_func.nii.gz -out  WM_in_func_space
fslmeants -i denoised_func_data.nii.gz -m WM_mask_in_func_space --no_bin -o WM_in_func_bin_timeseries

flirt -in CSF_mask_in_highres_space_eroded -applyxfm -init rest.feat/reg/highres2example_func.mat -ref  example_func.nii.gz -out  CSF_in_func_space
fslmeants -i denoised_func_data.nii.gz -m CSF_mask_in_func_space --no_bin -o CSF_in_func_bin_timeseries

# Note: 
# (i) The WM_mask_highres_space can be obtained in several ways (e.g.,
# FSL/fast, SPM12/segment). I use SPM12/segment here and I obtain a weighted WM_mask_in_highres_space. 
# This weighted information is actually good stuff because it allows more certainty for WM voxels (vs. non-WM voxels). 
# To use the information, I use --no_bin in fslmeants.  
# (ii) Also I want to erode the
# WM mask to begin with, in order to increase the certainty (e.g., reducing some boundaries with GM). 
# (iii) Finally, I use denoised_func_data (rather than filtered_func_data) as input for fslmeants because I want to add further denoising to it.

# 1-b). We can use similar procedure as above to obtain CSF_in_func_bin_timeseries


# 1-c). To regress out these two nuisance regressors:

paste WM_in_func_bin_timeseries CSF_in_func_bin_timeseries > nuisance_timeseries

fslmaths denoised_func_data –Tmean tempMean
fsl_glm -i denoised_func_data -d nuisance_timeseries --demean --out_res=residual


# Note: I use —demean to mean-center the nuisance timeseries so that the residual makes sense. 
# I don’t use —des_norm or —dat_norm because I am looking at the residual (but not the GLM betas) here. 
# I also want to add the mean back so that it is a firm data set (see step (3) below).

# (2) Linear detrending
# The standard procedure of linear detrending in FSL is done via high pass filtering (below).


# (3) highpass filtering

# Since my TR = 2.0 s and I want highpass filtering of 100 second, this means 50 TR (volume), and thus highpass sigma is 25.0 TR (volumes).

fslmaths residual -bptf 25.0 -1 –add tempMean denoised_func_data_2

# Note: Finally, I will use the denoised_func_data_2 as input for doing participant-level statistics (postprocessing).
