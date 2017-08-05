template_name=19childs
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19/mask	
																	
str_pruning_ic_id="0,2,4,6,7,11,15,18,25,42,56"
str_arr_IC_labels="DMN_X,X,XX,EXEC,DMN_XX,LAT_VIS,DMN_XXX,R_FP,V1,LAT_VIS_2,SM" 
declare -a arr_IC_labels=(DMN_X X XX EXEC DMN_XX LAT_VIS DMN_XXX R_FP V1 LAT_VIS_2 SM)

