template_name=24childs_denoised_skip4vol
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19_denoised_skip4vol/mask	
																	
str_pruning_ic_id="1,3,4,7,9,10,11,12,13,16,17,19,20,21"
str_arr_IC_labels="R_FP2,LAT_OCCIP,R_FP,L_FP,X,DMN2,B_FP,FRONTO_STRIAT,DMN,SM,V1,A_DMN,LAT_VIS,XX" 
declare -a arr_IC_labels=(R_FP2 LAT_OCCIP R_FP L_FP X DMN2 B_FP FRONTO_STRIAT DMN SM V1 A_DMN LAT_VIS XX)

