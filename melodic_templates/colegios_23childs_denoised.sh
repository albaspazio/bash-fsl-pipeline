template_name=23childs_denoised
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
																	
str_pruning_ic_id="1,4,6,9,11,13,15,16,17,18,20"
str_arr_IC_labels="L_FP,DMN2,X,R_FP,DMN,EXEC,V2,SM,B_FP,V1,A_DMN" 
declare -a arr_IC_labels=(L_FP DMN2 X R_FP DMN EXEC V2 SM B_FP V1 A_DMN)

