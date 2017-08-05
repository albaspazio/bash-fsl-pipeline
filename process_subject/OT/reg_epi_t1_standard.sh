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
	if [ ! -f $T1_BRAIN_DATA.nii.gz ]; then return 0; fi
	if [ ! -d $PROJ_DIR ]; then echo "project dir ($PROJ_DIR) not present....exiting"; exit; fi

	
	if [ -z $STD_IMAGE ]; then 
		STD_IMAGE=$FSLDIR/data/standard/MNI152_T1_2mm_brain
	else
		if [ ! -f $STD_IMAGE.nii.gz ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi
	fi





	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	
	echo "$SUBJ_NAME:						STARTED : nonlin epi-t1-standard coregistration"
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	if [ ! -f $RS_EXAMPLEFUNC ]; then
		$FSLDIR/bin/fslmaths $RS_DATA $ROI_DIR/reg_epi/prefiltered_func_data -odt float
		$FSLDIR/bin/fslroi $ROI_DIR/reg_epi/prefiltered_func_data $RS_EXAMPLEFUNC 100 1
		$FSLDIR/bin/bet2 $RS_EXAMPLEFUNC $RS_EXAMPLEFUNC -f 0.3
		rm $ROI_DIR/reg_epi/prefiltered_func_data*	
	fi

	#epi -> highres 
	[ ! -f $ROI_DIR/reg_t1/epi2highres.mat ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_epi/example_func -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/epi2highres -omat $ROI_DIR/reg_t1/epi2highres.mat -bins 256 -cost normmi -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -dof 7 -interp trilinear
	# highres -> epi

	[ ! -f $ROI_DIR/reg_epi/highres2epi.mat ] && $FSLDIR/bin/convert_xfm -omat $ROI_DIR/reg_epi/highres2epi.mat -inverse $ROI_DIR/reg_t1/epi2highres.mat

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# epi -> highres -> standard
	[ ! -f $ROI_DIR/reg_standard/epi2standard_warp.nii.gz ] && $FSLDIR/bin/convertwarp --ref=$STD_IMAGE --premat=$ROI_DIR/reg_t1/epi2highres.mat --warp1=$ROI_DIR/reg_standard/highres2standard_warp --out=$ROI_DIR/reg_standard/epi2standard_warp

	# invwarp: standard -> highres -> epi
	if [ ! -f $ROI_DIR/reg_epi/standard2epi_warp.nii.gz ]; then
		echo $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard/epi2standard_warp -o $ROI_DIR/reg_epi/standard2epi_warp
	 $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard/epi2standard_warp -o $ROI_DIR/reg_epi/standard2epi_warp
	fi

	#2: concat: standard -> highres -> epi
	#$FSLDIR/bin/convertwarp --ref=$ROI_DIR/reg_epi/example_func --warp1=$ROI_DIR/reg_t1/standard2highres_warp --postmat=$ROI_DIR/reg_epi/highres2epi --out=$ROI_DIR/reg_dti/standard2epi_warp
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# standard 4mm
	
	# epi -> highres -> standard4
#	[ ! -f $ROI_DIR/reg_standard4/epi2standard_warp.nii.gz -a -f $ROI_DIR/reg_standard4/highres2standard_warp.nii.gz ] && $FSLDIR/bin/convertwarp --ref=$FSL_STANDARD_MNI_4mm --premat=$ROI_DIR/reg_t1/epi2highres.mat --warp1=$ROI_DIR/reg_standard4/highres2standard_warp --out=$ROI_DIR/reg_standard4/epi2standard_warp	
#	
#	# invwarp: standard4 -> highres -> epi
#	if [ ! -f $ROI_DIR/reg_epi/standard42epi_warp.nii.gz ]; then
##		echo $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard/epi2standard_warp -o $ROI_DIR/reg_epi/standard2epi_warp
#	 $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard4/epi2standard_warp -o $ROI_DIR/reg_epi/standard42epi_warp
#	fi
#	
#	
	
	echo "$SUBJ_NAME:						TERMINATED : nonlin epi-t1-standard coregistration"
}
main
