template_name=belgrade_c27_pd71_denoised_swapped_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd/group_analysis/melodic/dr/templ_$template_name/controls27_pd71_interleaved_denoised_swapped/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/fsl_belgrade_early_pd/group_analysis/melodic/dr/templ_$template_name/controls28_pd66_denoised_skip4vol/mask	
fi

str_pruning_ic_id="0,1,4,5,7,8,9"
str_arr_IC_labels="R_FP,SM,DMN,L_FP,B_FP,LAT_VIS,DORSAL"
declare -a arr_IC_labels=(R_FP SM DMN L_FP B_FP LAT_VIS DORSAL)

