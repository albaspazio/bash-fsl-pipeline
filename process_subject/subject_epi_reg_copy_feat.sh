#!/bin/bash

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

if [ $# -lt 2 ]
then
	echo "usage: reg_copy_feat_epi subj_name proj_dir -idn input_epi_dir_name -idn2 input_feat_dir_name -idp feat_dir -stdimg standard_image"
	exit
fi

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

INPUT_EPI_DIR_NAME=resting
INPUT_FEAT_DIR_NAME=resting.feat
STANDARD_IMAGE=$FSL_STANDARD_2mm
FEAT_DIR=""

while [ ! -z "$1" ]
do
  case "$1" in
      -idn) 		INPUT_EPI_DIR_NAME=$2;shift;;
      -idn2) 		INPUT_FEAT_DIR_NAME=$2;shift;;
      -idp)			FEAT_DIR=$2;shift;;
 			-stdimg)	STANDARD_IMAGE=$2
					if [ ! -f $STANDARD_IMAGE.nii.gz ]; then echo "error: standard image ($STANDARD_IMAGE.nii.gz) do not exist......exiting"; exit; fi
					;; 
      *) break;;
  esac
  shift
done

if [ -z $FEAT_DIR ]; then
	FEAT_DIR=$SUBJECT_DIR/$INPUT_EPI_DIR_NAME/$INPUT_FEAT_DIR_NAME
fi

if [ ! -d $FEAT_DIR ]; then echo "feat dir ($FEAT_DIR) not present....exiting"; exit; fi
	#==============================================================================================

run $FSLDIR/bin/imcp $FEAT_DIR/reg/example_func $RS_EXAMPLEFUNC

run cp $FEAT_DIR/reg/example_func2highres.mat $ROI_DIR/reg_t1/epi2highres.mat
run cp $FEAT_DIR/reg/highres2example_func.mat $ROI_DIR/reg_epi/highres2epi.mat

run cp $FEAT_DIR/reg/standard2highres.mat $ROI_DIR/reg_t1/standard2highres.mat
run cp $FEAT_DIR/reg/highres2standard.mat $ROI_DIR/reg_standard/highres2standard.mat

run cp $FEAT_DIR/reg/standard2example_func.mat $ROI_DIR/reg_epi/standard2epi.mat
run cp $FEAT_DIR/reg/example_func2standard.mat $ROI_DIR/reg_standard/epi2standard.mat

run_notexisting_img $FEAT_DIR/reg/highres2standard_warp cp $FEAT_DIR/reg/highres2standard_warp.nii.gz $ROI_DIR/reg_standard/highres2standard_warp.nii.gz
run_notexisting_img $ROI/reg_t1/standard2highres_warp  $FSLDIR/bin/invwarp -w $ROI_DIR/reg_standard/highres2standard_warp.nii.gz -o $ROI_DIR/reg_t1/standard2highres_warp.nii.gz -r $T1_BRAIN_DATA

# epi -> highres -> standard
run_notexisting_img $ROI_DIR/reg_standard/epi2standard_warp $FSLDIR/bin/convertwarp --ref=$FSLDIR/data/standard/MNI152_T1_2mm --premat=$ROI_DIR/reg_t1/epi2highres.mat --warp1=$ROI_DIR/reg_standard/highres2standard_warp --out=$ROI_DIR/reg_standard/epi2standard_warp

# invwarp: standard -> highres -> epi
run_notexisting_img $ROI_DIR/reg_epi/standard2epi_warp $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_standard/epi2standard_warp -o $ROI_DIR/reg_epi/standard2epi_warp



