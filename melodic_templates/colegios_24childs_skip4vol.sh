template_name=24childs_skip4vol
		
TEMPLATE_MELODIC_IC=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/melodic_IC.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
TEMPLATE_MASK_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/group_templates/$template_name/stats
TEMPLATE_MASK_FOLDER=/media/data/MRI/projects/colegios/group_analysis/melodic/dr/templ_$template_name/child19_skip4vol/mask	
																	
str_pruning_ic_id="0,2,3,8,13,16,19,27,33,38,39,47,51,52"
str_arr_IC_labels="B_FP,LAT_VIS,R_FP,V1,R_FP2,A_DMN,DMN,X,LAT_OCCIP,A_DMN2,X,SM,L_FP,B_FP2" 
declare -a arr_IC_labels=(B_FP LAT_VIS R_FP V1 R_FP2 A_DMN DMN X LAT_OCCIP A_DMN2 X SM L_FP B_FP2)

