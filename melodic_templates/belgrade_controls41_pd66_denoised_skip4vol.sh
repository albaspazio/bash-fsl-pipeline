template_name=belgrade_controls41_pd66_denoised_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/dr/templ_$template_name/controls41_pd66_skip4vol/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/dr/templ_$template_name/controls41_pd66_skip4vol/mask	
fi

str_pruning_ic_id="0,1,3,4,7,8,9"
str_arr_IC_labels="L_FP,DMN,X,R_FP,VISUAL,ANTI_DORSAL,DORSAL"
declare -a arr_IC_labels=(L_FP DMN X R_FP VISUAL ANTI_DORSAL DORSAL)

