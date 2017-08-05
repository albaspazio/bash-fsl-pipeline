template_name=controls_belgrade46_cab45


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
fi

str_pruning_ic_id="3,4,7,8,19,34,38,41"
str_arr_IC_labels="L_FP,B_FP,B_FP2,DMN,SM,A_DMN,VISUAL,R_FP"
declare -a arr_IC_labels=(L_FP B_FP B_FP2 DMN SM A_DMN VISUAL R_FP)

