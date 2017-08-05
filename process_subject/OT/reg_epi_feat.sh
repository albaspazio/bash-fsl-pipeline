#!/bin/bash

if [ $# -lt 5 -o $# -gt 5 ]
then
	echo "usage: do_registration subj_name proj_dir std_image rs/fmri rs.ica/fmri.feat "
	exit
fi

SUBJ_NAME=$1
PROJ_DIR=$2
STD_IMAGE=$3
EPI_DIR_NAME=$4
FEAT_DIR_NAME=$5

main()
{
	if [ ! -f $T1_BRAIN_DATA.nii.gz ]; then return 0; fi
	if [ ! -d $PROJ_DIR ]; then echo "project dir ($PROJ_DIR) not present....exiting"; exit; fi

	
	if [ -z $STD_IMAGE ]; then 
		STD_IMAGE=$FSLDIR/data/standard/MNI152_T1_2mm_brain
	else
		if [ ! -f $STD_IMAGE.nii.gz ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi
	fi

	FEAT_DIR=$SUBJECT_DIR/$EPI_DIR_NAME/$FEAT_DIR_NAME
	if [ ! -d $FEAT_DIR ]; then echo "feat dir ($FEAT_DIR) not present....exiting"; exit; fi
	#==============================================================================================

	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	

	echo "$SUBJ_NAME:						STARTED : nonlin epi-feat coregistration"
	
	cd $FEAT_DIR
	if [ -d $FEAT_DIR/reg ]; then mv $FEAT_DIR/reg $FEAT_DIR/reg_old; fi

	mkdir -p $FEAT_DIR/reg

	$FSLDIR/bin/fslmaths $T1_BRAIN_DATA $FEAT_DIR/reg/highres
	$FSLDIR/bin/fslmaths $STD_IMAGE $FEAT_DIR/reg/standard

	$FSLDIR/bin/fslmaths $T1_DATA $FEAT_DIR/reg/highres_head

	$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm $FEAT_DIR/reg/standard_head
	$FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil $FEAT_DIR/reg/standard_mask

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	input_rs_example=$ROI_DIR/reg_epi/example_func
	if [ ! -f $input_rs_example.nii.gz ]; then
		$FSLDIR/bin/fslmaths $RS_DATA $ROI_DIR/reg_epi/prefiltered_func_data -odt float
		$FSLDIR/bin/fslroi $ROI_DIR/reg_epi/prefiltered_func_data $input_rs_example 100 1
		$FSLDIR/bin/bet2 $input_rs_example $input_rs_example -f 0.3
		rm $ROI_DIR/reg_epi/prefiltered_func_data*	
	fi

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# HR <-> STD
	[ ! -f $FEAT_DIR/reg/highres2standard.mat ] && $FSLDIR/bin/flirt -ref $FEAT_DIR/reg/standard -in $FEAT_DIR/reg/highres -out $FEAT_DIR/reg/highres2standard -omat $FEAT_DIR/reg/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear  

	[ ! -f $FEAT_DIR/reg/highres2standard_warp ] && $FSLDIR/bin/fnirt --in=$FEAT_DIR/reg/highres_head --aff=$FEAT_DIR/reg/highres2standard.mat --cout=$FEAT_DIR/reg/highres2standard_warp --iout=$FEAT_DIR/reg/highres2standard --jout=$FEAT_DIR/reg/highres2standard_jac --config=T1_2_MNI152_2mm --ref=$FEAT_DIR/reg/standard_head --refmask=$FEAT_DIR/reg/standard_mask --warpres=10,10,10

	[ ! -f $FEAT_DIR/reg/standard2highres.mat ] && $FSLDIR/bin/convert_xfm -inverse -omat $FEAT_DIR/reg/standard2highres.mat $FEAT_DIR/reg/highres2standard.mat

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# EPI <-> STD
	[ ! -f $FEAT_DIR/reg/example_func2standard.mat ] && $FSLDIR/bin/convert_xfm -omat $FEAT_DIR/reg/example_func2standard.mat -concat $FEAT_DIR/reg/highres2standard.mat $FEAT_DIR/reg/example_func2highres.mat

	[ ! -f $FEAT_DIR/reg/standard2example_func.mat ] && $FSLDIR/bin/convert_xfm -inverse -omat $FEAT_DIR/reg/standard2example_func.mat $FEAT_DIR/reg/example_func2standard.mat

	if [ nlin -eq 1 ]; then
		[ ! -f $FEAT_DIR/reg/example_func2standard.nii.gz ] && $FSLDIR/bin/applywarp --ref=$FEAT_DIR/reg/standard --in=$FEAT_DIR/example_func --out=$FEAT_DIR/reg/example_func2standard --warp=$FEAT_DIR/reg/highres2standard_warp --premat=$FEAT_DIR/reg/epi2highres.mat
	else
		[ ! -f $FEAT_DIR/reg/example_func2standard.nii.gz ] && $FSLDIR/bin/flirt -ref $FEAT_DIR/reg/standard -in $FEAT_DIR/example_func -out $FEAT_DIR/reg/example_func2standard -applyxfm -init $FEAT_DIR/reg/example_func2standard.mat -interp trilinear
	fi

	if [ -d $FEAT_DIR/reg_standard ]; then mv $FEAT_DIR/reg_standard $FEAT_DIR/reg_standard_old; fi
	featregapply $FEAT_DIR


	#===================================================================================================================================
	# ROI DIRs

	cp $FEAT_DIR/reg/example_func2highres.mat $ROI_DIR/reg_t1/epi2highres.mat
	cp $FEAT_DIR/reg/standard2highres.mat $ROI_DIR/reg_t1/standard2highres.mat

	cp $FEAT_DIR/reg/highres2example_func.mat $ROI_DIR/reg_epi/highres2epi.mat
	cp $FEAT_DIR/reg/standard2example_func.mat $ROI_DIR/reg_epi/standard2epi.mat

	cp $FEAT_DIR/reg/highres2standard.mat $ROI_DIR/reg_standard/highres2standard.mat
	cp $FEAT_DIR/reg/example_func2standard.mat $ROI_DIR/reg_standard/epi2standard.mat

	cp $FEAT_DIR/reg/highres2standard_warp.nii.gz $ROI_DIR/reg_standard/highres2standard_warp.nii.gz
	[ ! -f $ROI/reg_t1/standard2highres_warp.nii.gz ] && $FSLDIR/bin/invwarp -w $ROI_DIR/reg_standard/highres2standard_warp.nii.gz -o $ROI/reg_t1/standard2highres_warp.nii.gz -r $T1_BRAIN_DATA

	# epi -> highres -> standard
	$FSLDIR/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm --premat=$ROI_DIR/reg_t1/epi2highres --warp1=$ROI_DIR/reg_standard/highres2standard_warp --out=$ROI_DIR/reg_standard/epi2standard_warp
	# invwarp: standard -> highres -> epi
	$FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard/epi2standard_warp -o $ROI_DIR/reg_epi/standard2epi_warp
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	echo "$SUBJ_NAME:						TERMINATED : nonlin epi-feat coregistration"
}
main	
