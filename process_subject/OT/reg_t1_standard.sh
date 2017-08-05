#!/bin/bash

if [ $# -lt 2 -o $# -gt 3 ]
then
	echo "usage: reg_nonlin_t1_standard subj_name proj_dir std_image :  $1 $2"
	exit
fi

SUBJ_NAME=$1
PROJ_DIR=$2
STD_IMAGE=$3

main()
{

	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	if [ ! -f $T1_BRAIN_DATA.nii.gz ]; then
		echo "file T1_BRAIN_DATA: $T1_BRAIN_DATA.nii.gz is not present...skipping reg_nonlin_epi_t1_standard.sh"
		return 0; 
	fi
	
	if [ -z $STD_IMAGE ]; then 
		STD_IMAGE=$FSLDIR/data/standard/MNI152_T1_2mm_brain
	else
		if [ ! -f $STD_IMAGE ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi
	fi




	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	echo "$SUBJ_NAME:						STARTED : nonlin t1-standard coregistration"

		# highres <--> standard
	mkdir -p $ROI_DIR/reg_standard
	mkdir -p $ROI_DIR/reg_t1

	highres2standard_mat=$ROI_DIR/reg_standard/highres2standard.mat
	standard2highres_mat=$ROI_DIR/reg_t1/standard2highres.mat
	hr2std_warp=$ROI_DIR/reg_standard/highres2standard_warp.nii.gz
	std2hr_warp=$ROI_DIR/reg_t1/standard2highres_warp.nii.gz

	[ ! -f $highres2standard_mat ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA.nii.gz -ref $FSL_DATA_STANDARD/MNI152_T1_2mm_brain -omat $highres2standard_mat 
	[ ! -f $standard2highres_mat ] && $FSLDIR/bin/convert_xfm -omat $standard2highres_mat -inverse $highres2standard_mat 

	[ ! -f $hr2std_warp ] && $FSLDIR/bin/fnirt --in=$T1_DATA --aff=$highres2standard_mat --cout=$hr2std_warp --iout=$ROI_DIR/reg_standard/highres2standard --jout=$ROI_DIR/reg_standard/highres2standard_jac --config=T1_2_MNI152_2mm --ref=$FSL_DATA_STANDARD/MNI152_T1_2mm --refmask=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain_mask_dil --warpres=10,10,10
	[ ! -f $std2hr_warp ] && $FSLDIR/bin/invwarp -w $hr2std_warp -o $std2hr_warp -r $T1_BRAIN_DATA
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		

 	echo @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@2
	# highres <--> standard4
	mkdir -p $ROI_DIR/reg_standard4

	highres2standard4_mat=$ROI_DIR/reg_standard4/highres2standard.mat
	standard42highres_mat=$ROI_DIR/reg_t1/standard42highres.mat
	hr2std4_warp=$ROI_DIR/reg_standard4/highres2standard_warp.nii.gz
	std42hr_warp=$ROI_DIR/reg_t1/standard42highres_warp.nii.gz

	[ ! -f $highres2standard4_mat ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA.nii.gz -ref $FSL_STANDARD_MNI_4mm -omat $highres2standard4_mat 
	[ ! -f $standard42highres_mat ] && $FSLDIR/bin/convert_xfm -omat $standard42highres_mat -inverse $highres2standard4_mat 

#	[ ! -f $hr2std4_warp ] && $FSLDIR/bin/fnirt --in=$T1_DATA --aff=$highres2standard4_mat --cout=$hr2std4_warp --iout=$ROI_DIR/reg_standard4/highres2standard --jout=$ROI_DIR/reg_standard4/highres2standard_jac --config=$GLOBAL_DATA_TEMPLATES/gray_matter/T1_2_MNI152_4mm --ref=$FSL_STANDARD_MNI_4mm --refmask=$GLOBAL_DATA_TEMPLATES/gray_matter/MNI152_T1_4mm_brain_mask_dil --warpres=10,10,10
#	[ ! -f $std42hr_warp ] && $FSLDIR/bin/invwarp -w $hr2std4_warp -o $std42hr_warp -r $T1_BRAIN_DATA
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	

	echo "$SUBJ_NAME:						TERMINATED : nonlin t1-standard coregistration"
}

main	
