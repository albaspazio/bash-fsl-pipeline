template_name=belgrade_controls36_dyt50_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/FSL_RESTING_DYT/group_analysis/melodic/dr/templ_$template_name/controls_dyt_b_skip4vol/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/FSL_RESTING_DYT/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/FSL_RESTING_DYT/group_analysis/melodic/dr/templ_$template_name/controls_dyt_b_skip4vol/mask	
fi

str_pruning_ic_id="1,2,4,6,8,14,23,28"
str_arr_IC_labels="AUDIO_VENTRAL,FRONTAL,SM,B_FP,X,DORSAL,DMN,R_FP"
declare -a arr_IC_labels=(AUDIO_VENTRAL FRONTAL SM B_FP X DORSAL DMN R_FP)
declare -a arr_pruning_ic_id=(1 2 4 6 8 14 23 28)
