#!/bin/bash

# ======================================================================================
#				 S T E P  2a : T E M P L A T E    I N F O R M A T I O N    D E F I N I T I O N  
# ======================================================================================

template_name=belgrade_controls26_denoised_skip4vol

TEMPLATE_MELODIC_IC=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
TEMPLATE_MASK_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/templ_$template_name/mask #"folder created by meaning process"	

str_pruning_ic_id="1,2,4,5,6,8,10,12,13,14,15,16"  # network BUONI: vanno inseriti 0-based rispetto a cio che vedete nell'html !!!!!!
str_arr_IC_labels="DMN,L_FP,EXEC,X,SM,R_FP,LAT_VIS,SALIENCE,DORSAL,XX,V1,AUDIO"
declare -a arr_IC_labels=(DMN L_FP EXEC X SM R_FP LAT_VIS SALIENCE DORSAL XX V1 AUDIO)
declare -a arr_pruning_ic_id=(1 2 4 5 6 8 10 12 13 14 15 16)
