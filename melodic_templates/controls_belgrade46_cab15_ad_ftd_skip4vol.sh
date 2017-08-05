template_name=controls_belgrade46_cab15_ad_ftd_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/STUDY_AD_FTD/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
fi

str_pruning_ic_id="1,5,14,22,24,43"
str_arr_IC_labels="DMN,L_FP,V1,SM,R_FP,X"
declare -a arr_IC_labels=(DMN L_FP V1 SM R_FP X)








