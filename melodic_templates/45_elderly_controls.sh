template_name=allcontrols_corrected
		
if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/projects/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/data/MRI/projects/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/CAB/controls_cab/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
else
	TEMPLATE_MELODIC_IC=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz
	TEMPLATE_MASK_IMAGE=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
	TEMPLATE_BG_IMAGE=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
	TEMPLATE_STATS_FOLDER=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/group_templates/$template_name/stats
	TEMPLATE_MASK_FOLDER=/media/Iomega_HDD/CAB/controls_cab/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
fi		
																	
str_pruning_ic_id="1,2,3,4,7,16,24,28,30,33,34"
str_arr_IC_labels="DMN,X,L_FP,A_DMN,XX,SM,LAT_VIS,R_FP,B_FP,ANT_SAL,PRIM_VIS" 
declare -a arr_IC_labels=(DMN X L_FP A_DMN XX SM LAT_VIS R_FP B_FP ANT_SAL PRIM_VIS)

