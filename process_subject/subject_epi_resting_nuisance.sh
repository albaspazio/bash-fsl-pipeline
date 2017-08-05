#!/bin/bash

# ==================================================================================
# usage:	. ./path/execute_subject_resting_nuisance.sh 003 colegios -idn resting.feat
# ==================================================================================
# input:
#		$1			subject label  		:  	003
#	  $2			proj_dir					:  	/homer/home/..../fsl_belgrade	
#		-idn		INPUT_FEAT_NAME		:  	resting.feat
#
# output:	write a folder $RS_DIR/odn.ica
#
# task:		run single subject AROMA ICA, and apply registration to upsampled standard space

usage_string="Usage: $0 subj_label proj_dir"
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

HPF_SEC=100  
INPUT_IMAGE=$RS_DATA


while [ ! -z "$1" ]
do
  case "$1" in
      -hpfsec) 	HPF_SEC=$2;shift;;
      -ifn)			INPUT_IMAGE=$RS_DIR/$2;shift;;	
      -osn)			OUTPUT_SERIES_POSTFIX_NAME=$2; shift;;
      *) break;;
  esac
  shift
done

# get image TR and use it to calculate the HPF sigma
# calculated as : HPF_SEC(seconds) / 2*TR  with HP usually 100 seconds.....
# (e.g. TR = 2.0 s and I want HP filter of 100 sec., this means 50 TR (volume), and thus HP sigma is 25.0 TR (volumes))
TR=`$FSLDIR/bin/fslval $INPUT_IMAGE pixdim4`
HPF_SIGMA=$(echo "scale=3;$HPF_SEC/(2*$TR)" | bc)

wm_series=$RS_SERIES_DIR/wm_ts$OUTPUT_SERIES_POSTFIX_NAME.txt
csf_series=$RS_SERIES_DIR/csf_ts$OUTPUT_SERIES_POSTFIX_NAME.txt
output_series=$RS_SERIES_DIR/nuisance_timeseries$OUTPUT_SERIES_POSTFIX_NAME.txt

main()
{
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	# ===================================================================================
	run echo "---------------------------------------------------------------------------------------------"
	run echo "execute_subject_resting_nuisance of $SUBJ_NAME"

	run mkdir -p $SBFC_DIR
	run mkdir -p $RS_SERIES_DIR
			
	echo "===========>>>> $SUBJ_NAME: coregister fast-highres to epi"
	
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_epi/mask_t1_wmseg4Nuisance_epi` = 0 ] && run . $GLOBAL_SCRIPT_DIR/process_subject/subject_transforms_roi.sh $SUBJ_NAME $PROJ_DIR -thresh 0 -regtype hr2epi -pathtype abs $T1_SEGMENT_WM_ERO_PATH
	
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_epi/mask_t1_csfseg4Nuisance_epi` = 0 ] && run . $GLOBAL_SCRIPT_DIR/process_subject/subject_transforms_roi.sh $SUBJ_NAME $PROJ_DIR -thresh 0 -regtype hr2epi -pathtype abs $T1_SEGMENT_CSF_ERO_PATH
	
	run $FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o $wm_series  -m $ROI_DIR/reg_epi/mask_t1_wmseg4Nuisance_epi --no_bin 
	run $FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o $csf_series -m $ROI_DIR/reg_epi/mask_t1_csfseg4Nuisance_epi --no_bin 
	run paste $wm_series $csf_series > $output_series

	run $FSLDIR/bin/fslmaths $INPUT_IMAGE -Tmean $RS_DIR/tempMean
	run $FSLDIR/bin/fsl_glm -i $INPUT_IMAGE -d $output_series --demean --out_res=$RS_DIR/residual	
	
	run $FSLDIR/bin/fslcpgeom $INPUT_IMAGE.nii.gz $RS_DIR/residual.nii.gz # solves a bug in fsl_glm which writes TR=1 in residual.
	
	run $FSLDIR/bin/fslmaths $RS_DIR/residual -bptf $HPF_SIGMA -1 -add $RS_DIR/tempMean $INPUT_IMAGE"_nuisance"
	
	run $FSLDIR/bin/imrm $RS_DIR/tempMean
	run $FSLDIR/bin/imrm $RS_DIR/residual	
}
main $@
