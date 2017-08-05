template_name=study_ad_ftd
		
if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	MASK_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	BG_IMAGE=/media/data/MRI/projects/CAB/STUDY_AD_FTD<<<<<<<q																																														<HJ            /group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
else
	TEMPLATE_MELODIC_IC=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	MASK_IMAGE=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	BG_IMAGE=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
fi		
																	
str_pruning_ic_id=""
str_arr_IC_labels="" 
declare -a arr_IC_labels=()

