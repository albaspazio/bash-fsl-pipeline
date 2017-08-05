template_name=controls_belgrade13_cab45_md_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/FSL_RESTING_MD/group_analysis/melodic/dr/templ_$template_name/controls_md_skip4vol/mask	
else
	TEMPLATE_MELODIC_IC=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/krusty/home/dati/fsl_resting_belgrade_controls/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/krusty/home/dati/FSL_RESTING_MD/group_analysis/melodic/dr/templ_$template_namecontrols_md_skip4vol/mask	
fi

str_pruning_ic_id="2,3,8,14,16,18,19,20,21,32,34,41,42,44,46"
str_arr_IC_labels="DMN,EXEC,DORSAL,LAT_VIS,VENTRAL,V2,L_FP,B_FP,R_FP,X,XX,SM,XXX,V1,FRONTO_STRIATAL"
declare -a arr_IC_labels=(DMN EXEC DORSAL LAT_VIS VENTRAL V2 L_FP B_FP R_FP X XX SM XXX V1 FRONTO_STRIATAL)

declare -a arr_pruning_ic_id=(2 3 8 14 16 18 19 20 21 32 34 41 42 44 46)






