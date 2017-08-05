template_name=17childs_denoised
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/$template_name/mask	
																	
str_pruning_ic_id="5,6,9,13,16,18,20,21,23"
str_arr_IC_labels="B_FP,EXEC,R_FP,DMN,V1,SM,L_FP,B_FP2,V2" 
declare -a arr_IC_labels=(B_FP EXEC R_FP DMN V1 SM L_FP B_FP2 V2)

