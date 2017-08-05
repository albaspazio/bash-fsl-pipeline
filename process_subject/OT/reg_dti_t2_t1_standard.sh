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

	echo "$SUBJ_NAME:						STARTED : nonlin dti-t2-t1-standard coregistration"
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	if [ ! -f $ROI_DIR/reg_dti/nodif_brain.nii.gz ]; then
		if [ ! -f $DTI_DIR/nodif_brain.nii.gz ]; then
			$FSLDIR/bin/fslroi $DTI_DATA $DTI_DIR/nodif 0 1
			$FSLDIR/bin/bet $DTI_DIR/nodif $DTI_DIR/nodif_brain -m -f 0.3
		fi
		cp $DTI_DIR/nodif_brain.nii.gz $ROI_DIR/reg_dti
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	# dti -> t2 lin
	[ ! -f $ROI_DIR/reg_t2/dti2t2.mat ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_dti/nodif_brain -ref $T2_BRAIN_DATA -out $ROI_DIR/reg_t2/dti2t2_l -omat $ROI_DIR/reg_t2/dti2t2.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6 -interp trilinear
	# t2 -> dti lin
	[ ! -f $ROI_DIR/reg_dti/t22dti.mat ] && $FSLDIR/bin/convert_xfm -omat $ROI_DIR/reg_dti/t22dti.mat -inverse $ROI_DIR/reg_t2/dti2t2.mat
	# dti -> t2 nlin
	[ ! -f $ROI_DIR/reg_t2/dti2t2_warp.nii.gz ] && $FSLDIR/bin/fnirt --in=$ROI_DIR/reg_dti/nodif_brain --ref=$T2_BRAIN_DATA --aff=$ROI_DIR/reg_t2/dti2t2.mat --cout=$ROI_DIR/reg_t2/dti2t2_warp --iout=$ROI_DIR/reg_t2/nodif_brain2t2_nl  -v &>$ROI_DIR/reg_t2/dti2t2_nl.txt
	# t2 -> dti nlin
	[ ! -f $ROI_DIR/reg_dti/t22dti_warp.nii.gz ] && $FSLDIR/bin/invwarp -r $ROI_DIR/reg_dti/nodif_brain -w $ROI_DIR/reg_t2/dti2t2_warp -o $ROI_DIR/reg_dti/t22dti_warp
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# t2 -> highres lin
	[ ! -f $ROI_DIR/reg_t1/t22highres.mat ] && $FSLDIR/bin/flirt -in $T2_BRAIN_DATA -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/t22highres -omat $ROI_DIR/reg_t1/t22highres.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 6  -interp trilinear
	# highres -> t2 lin
	[ ! -f $ROI_DIR/reg_t2/highres2t2.mat ] && $FSLDIR/bin/convert_xfm -omat $ROI_DIR/reg_t2/highres2t2.mat -inverse $ROI_DIR/reg_t1/t22highres.mat

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# dti ( -> t2 -> highres ) -> standard
	[ ! -f $ROI_DIR/reg_standard/dti2standard_warp.nii.gz ] && $FSLDIR/bin/convertwarp -r $STD_IMAGE --warp1=$ROI_DIR/reg_t2/dti2t2_warp --midmat=$ROI_DIR/reg_t1/t22highres.mat --warp2=$ROI_DIR/reg_standard/highres2standard_warp -o $ROI_DIR/reg_standard/dti2standard_warp
	# standard ( -> highres -> t2 ) -> dti
	[ ! -f $ROI_DIR/reg_dti/standard2dti_warp.nii.gz ] && $FSLDIR/bin/invwarp -r $ROI_DIR/reg_dti/nodif_brain -w $ROI_DIR/reg_standard/dti2standard_warp -o $ROI_DIR/reg_dti/standard2dti_warp

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# t2 -> highres -> standard
	[ ! -f $ROI_DIR/reg_standard/t22standard_warp.nii.gz ] && $FSLDIR/bin/convertwarp --ref=$STD_IMAGE --premat=$ROI_DIR/reg_t1/t22highres.mat --warp1=$ROI_DIR/reg_standard/highres2standard_warp --out=$ROI_DIR/reg_standard/t22standard_warp
	# standard -> highres -> t2
	[ ! -f $ROI_DIR/reg_t2/standard2t2_warp.nii.gz ] && $FSLDIR/bin/invwarp -r $T2_BRAIN_DATA -w $ROI_DIR/reg_standard/t22standard_warp -o $ROI_DIR/reg_t2/standard2t2_warp

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# dti -> t2 -> highres
	[ ! -f $ROI_DIR/reg_t1/dti2highres_warp.nii.gz ] && $FSLDIR/bin/convertwarp --ref=$T1_BRAIN_DATA --postmat=$ROI_DIR/reg_t1/t22highres.mat --warp1=$ROI_DIR/reg_t2/dti2t2_warp --out=$ROI_DIR/reg_t1/dti2highres_warp
	# highres -> t2 -> dti
	[ ! -f $ROI_DIR/reg_dti/highres2dti_warp.nii.gz ] && $FSLDIR/bin/invwarp -r $ROI_DIR/reg_dti/nodif_brain -w $ROI_DIR/reg_t1/dti2highres_warp -o $ROI_DIR/reg_dti/highres2dti_warp --force
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	echo "$SUBJ_NAME:						TERMINATED : nonlin dti-t2-t1-standard coregistration"
}
main
