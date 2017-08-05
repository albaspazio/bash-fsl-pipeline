template_name=24childs_denoised
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19_denoised/mask	
																	
str_pruning_ic_id="3,4,5,6,8,11,12,13,14,15,16,18,19,20,21"
str_arr_IC_labels="R_FP,DORSAL,L_FP,DMN2,X,VENTRAL,LAT_OCCIP,DMN,FRONTO_CAUD,A_DMN,B_FP,V1,SM,XX,LAT_VIS" 
declare -a arr_IC_labels=(R_FP DORSAL L_FP DMN2 X VENTRAL LAT_OCCIP DMN FRONTO_STRIAT A_DMN B_FP V1 SM XX LAT_VIS)

