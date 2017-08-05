template_name=belgrade_controls_md_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/dr/templ_$template_name/controls_md_skip4vol/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/dr/templ_$template_name/controls_md_skip4vol/mask	
fi

str_pruning_ic_id="1,3,5,10,13,15"
str_arr_IC_labels="B_FP,L_FP,EXEC,DMN,X,VIS"
declare -a arr_IC_labels=(B_FP L_FP EXEC DMN X VIS)

declare -a arr_pruning_ic_id=(1 3 5 10 13 15)






