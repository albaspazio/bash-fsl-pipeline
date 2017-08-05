template_name=controls

TEMPLATE_MELODIC_IC=/homer/home/dati/Resting_Melodic_SLA_PLS/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/homer/home/dati/Resting_Melodic_SLA_PLS/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/homer/home/dati/Resting_Melodic_SLA_PLS/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/homer/home/dati/Resting_Melodic_SLA_PLS/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/homer/home/dati/Resting_Melodic_SLA_PLS/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	

str_pruning_ic_id="1,3,5,9,12,13,14,16,19,30,35"
str_arr_IC_labels="L_FP,R_FP,EXE,AUD,SM,SAL,VI,ATT,DMN,VI2,VI_II"
declare -a arr_IC_labels=(L_FP R_FP EXE AUD SM SAL VI ATT DMN VI2 VI_II)