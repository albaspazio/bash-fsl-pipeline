template_name=19childs_denoised_skip4vol
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19_denoised_skip4vol/mask	
																	
str_pruning_ic_id="1,6,7,15,16,17,18,19,20,22,23"
str_arr_IC_labels="FR_STR_THAL,R_FP,SALIENCE,DMN,L_FP,SM,B_FP,V1,B_FP2,A_DMN,LAT_VIS" 
declare -a arr_IC_labels=(R_FP SALIENCE DMN L_FP SM B_FP V1 B_FP2 A_DMN LAT_VIS)
declare -a arr_pruning_ic_id=(1 6 7 15 16 17 18 19 20 22 23)
