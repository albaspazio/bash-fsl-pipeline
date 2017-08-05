template_name=19childs_denoised
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19_denoised/mask	
																	
str_pruning_ic_id="1,7,8,11,12,16,18,19,20,22,23"
str_arr_IC_labels="FR_STR_THAL,B_FP,R_FP,DMN,VENTRAL,V1,B_FP2,SM,L_FP,A_DMN,LAT_VIS" 
declare -a arr_IC_labels=(FR_STR_THAL B_FP R_FP DMN VENTRAL V1 B_FP2 SM L_FP A_DMN LAT_VIS)
declare -a arr_pruning_ic_id=(1 7 8 11 12 16 18 19 20 22 23)

