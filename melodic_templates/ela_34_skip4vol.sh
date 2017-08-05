template_name=ela_34_skip4vol
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/ela_34_skip4vol/mask	
																	
str_pruning_ic_id="5,16,25,26,35,36,39,52"
str_arr_IC_labels="A_DMN,SM,V1,LAT_VIS,DMN,L_FP,AUDIO,DMN2" 
declare -a arr_IC_labels=()

