#!/bin/bash

if [ $# -lt 2 -o $# -gt 3 ]
then
	echo "usage: do_registration subj_name proj_dir std_image rs/fmri rs.ica/fmri.feat "
	exit
fi

SUBJ_NAME=$1
PROJ_DIR=$2
STD_IMAGE=$3

main()
{
	if [ ! -f $T1_BRAIN_DATA ]; then return 0; fi
	
	if [ -z $STD_IMAGE ]; then 
		STD_IMAGE=$FSL_STANDARD_MNI_2mm
	else
		if [ ! -f $STD_IMAGE ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi
	fi

	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	echo "$SUBJ_NAME:						STARTED : nonlin dti-t1-standard coregistration"
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	if [ ! -f $ROI_DIR/reg_dti/nodif_brain.nii.gz ]; then
		if [ ! -f $DTI_DIR/nodif_brain.nii.gz ]; then
			$FSLDIR/bin/fslroi $DTI_DATA $DTI_DIR/nodif 0 1
			$FSLDIR/bin/bet $DTI_DIR/nodif $DTI_DIR/nodif_brain -m -f 0.3
		fi
		cp $DTI_DIR/nodif_brain.nii.gz $ROI_DIR/reg_dti
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	# dti -> highres 
	[ ! -f $ROI_DIR/reg_t1/dti2highres.mat ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_dti/nodif_brain -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/dti2highres -omat $ROI_DIR/reg_t1/dti2highres.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 7 -interp trilinear
	# highres -> dti
	[ ! -f $ROI_DIR/reg_dti/highres2dti.mat ] && $FSLDIR/bin/convert_xfm -omat $ROI_DIR/reg_dti/highres2dti.mat -inverse $ROI_DIR/reg_t1/dti2highres.mat

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# dti -> highres -> standard
	[ ! -f $ROI_DIR/reg_standard/dti2standard_warp.nii.gz ] && $FSLDIR/bin/convertwarp --ref=$STD_IMAGE --premat=$ROI_DIR/reg_t1/dti2highres.mat --warp1=$ROI_DIR/reg_standard/highres2standard_warp --out=$ROI_DIR/reg_standard/dti2standard_warp
	# standard -> highres -> dti
	[ ! -f $ROI_DIR/reg_dti/standard2dti_warp.nii.gz ] && $FSLDIR/bin/invwarp -r $ROI_DIR/reg_dti/nodif_brain -w $ROI_DIR/reg_standard/dti2standard_warp -o $ROI_DIR/reg_dti/standard2dti_warp

	#2: concat: standard -> highres -> dti
	#$FSLDIR/bin/convertwarp --ref=$ROI_DIR/reg_dti/nodif_brain --warp1=$ROI_DIR/reg_t1/standard2highres_warp --postmat=$ROI_DIR/reg_dti/highres2dti --out=$ROI_DIR/reg_dti/standard2dti_warp
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	echo "$SUBJ_NAME:						TERMINATED : nonlin dti-t1-standard coregistration"
}
main
