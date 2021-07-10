template_name=subjects80_baseline
TEMPLATE_MELODIC_IC=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects80_baseline/melodic_IC.nii.gz
TEMPLATE_MASK_IMAGE=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects80_baseline/mask.nii.gz
TEMPLATE_BG_IMAGE=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects80_baseline/bg_image.nii.gz
TEMPLATE_STATS_FOLDER=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects80_baseline/stats
TEMPLATE_MASK_FOLDER=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/group_templates/subjects80_baseline/stats
str_pruning_ic_id="0,1,2,3,4,5,6,7,9,10,11,12,13,14,16" # valid RSN: you must set their id values removing 1: if in the html is the 6th RSN, you must write 5!!!!!!
str_arr_IC_labels="pDMN,V1,LAT_VIS,aDMN,L_ATN,DORSAL,R_ATN,XXX,aDMN2,STRIATAL,pDMN2,XXXX,EXEC,XXXXX,AUDIO_LANG"
declare -a arr_IC_labels=(pDMN V1 LAT_VIS aDMN L_ATN DORSAL R_ATN XXX aDMN2 STRIATAL pDMN2 XXXX EXEC XXXXX AUDIO_LANG)
declare -a arr_pruning_ic_id=(0,1 2 3 4 5 6 7 9 10 11 12 13 14 16)





