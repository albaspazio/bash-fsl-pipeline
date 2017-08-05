template_name=24childs
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19/mask	
																	
str_pruning_ic_id="3,5,7,10,14,16,17,21,25"
str_arr_IC_labels="DMN2,R_ATN,DMN,MOTOR,PREC,V1,L_ATN,AUDIO,EXEC" 
declare -a arr_IC_labels=(DMN2 R_ATN DMN MOTOR PREC V1 L_ATN AUDIO EXEC)

