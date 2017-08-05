template_name=belgrade_controls26_skip4vol


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
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/dr/templ_$template_name/controls26_skip4vol/mask	
fi

str_pruning_ic_id="2,4,5,8,12,16,25,33,35"
str_arr_IC_labels="X,B_FP,LAT_VIS,SALIENCE,SM,R_FP,B_FP_EXEC_DORSAL,DMN,L_FP"
declare -a arr_IC_labels=(X B_FP LAT_VIS SALIENCE SM R_FP B_FP_EXEC_DORSAL DMN L_FP)
declare -a arr_pruning_ic_id=(2 4 5 8 12 16 25 33 35)
