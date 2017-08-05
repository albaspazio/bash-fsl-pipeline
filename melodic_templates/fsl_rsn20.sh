template_name=fsl_rsn20
		
if [ $WORK_IN_CAB -eq 0 ]
then
	TEMPLATE_MELODIC_IC=/media/data/MRI/scripts/data_templates/rsn/fsl_20/rsn20_444.nii.gz	# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	MASK_IMAGE=/media/data/MRI/scripts/data_templates/rsn/fsl_20/mask.nii.gz
	BG_IMAGE=/media/data/MRI/scripts/data_templates/rsn/fsl_20/bg_image.nii.gz
	TEMPLATE_MASK_FOLDER=/media/data/MRI/scripts/data_templates/rsn/fsl_20/mask
else
	TEMPLATE_MELODIC_IC=/media/Iomega_HDD/MRI/scripts/data_templates/rsn/fsl_20/rsn20_444.nii.gz
	MASK_IMAGE=/media/Iomega_HDD/MRI/scripts/data_templates/rsn/fsl_20/mask.nii.gz
	BG_IMAGE=/media/Iomega_HDD/MRI/scripts/data_templates/rsn/fsl_20/bg_image.nii.gz
	TEMPLATE_MASK_FOLDER=/media/Iomega_HDD/MRI/scripts/data_templates/rsn/fsl_20/mask
fi		
																	
str_pruning_ic_id="0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19"
str_arr_IC_labels="X,SM,AUDIO,BSTEM_thalam,BRAINSTEM,PRIM_VIS,DMN,EXEC,CEREB,LAT_VIS,LANG,L_FP,R_FP,ORBITOFR,B_FP_CING,VIS_TALAM,DAN,V2,XX,XXX" 
declare -a arr_IC_labels=(X SM AUDIO BSTEM_thalam BRAINSTEM PRIM_VIS DMN EXEC CEREB LAT_VIS LANG L_FP R_FP ORBITOFR B_FP_CING VIS_TALAM DAN V2 XX XXX)



