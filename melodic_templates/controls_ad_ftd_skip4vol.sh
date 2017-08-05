template_name=controls_ad_ftd_skip4vol


if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
else
	TEMPLATE_MELODIC_IC=/homer/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/homer/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/homer/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/homer/home/dati/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/homer/home/dati/STUDY_AD_FTD/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
fi

str_pruning_ic_id="2,4,7,8,10,14,18,27,29,32,37"
str_arr_IC_labels="EXEC_POSTPAR,L_FP,DORSAL,DMN,SM,V1,EXEC,B_FP,X,SM2,R_FP"
declare -a arr_IC_labels=(EXEC_POSTPAR L_FP DORSAL DMN SM V1 EXEC B_FP X SM2 R_FP)








