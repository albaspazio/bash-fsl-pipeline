#! /bin/bash

# usage : $GLOBAL_SCRIPT_DIR/process/execute_subject_ec_dtifit.sh sassi 003 1 1
# script to be used for data that:
# 	were already converted in nifti and in their correct directory
# 	calculate DTI
# ===== check parameters ==============================================================================
if [ ! $# == 2 ]; then
  echo "Usage: $0 proj_path subj_label"
  echo "calculate DTIFIT: $0 PROJ SUBJ"
  exit
fi
# ====== set init params =============================================================================
SUBJ_NAME=$1
PROJ_PATH=$2

# ======= static variables: do not edit !  ===========================================================================
if [ ! -d $PROJ_PATH ]; then
	echo "project folder ($PROJ_PATH) not defined ...... exiting"
fi

if [ -z "${INIT_VARS_DEFINED}" ]; then
  . $GLOBAL_SCRIPT_DIR/init_vars.sh
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
#==========================================================================================================================
#==========================================================================================================================
#==========================================================================================================================
#==========================================================================================================================


# taken from autoPtx_1_preproc, as used in De Groot et al., NeuroImage 2013.
# 2013, Marius de Groot    
run mkdir -p $ROI_DIR/reg_FA_1mm
echo "subj $SUBJ_NAME autoPtx_preproc : estimating registration to standard space"
run $FSLDIR/bin/fsl_reg $SUBJ_NAME-dtifit_FA $FSLDIR/data/standard/FMRIB58_FA_1mm $ROI_DIR/reg_FA_1mm/dti2std -e -FA
run $FSLDIR/bin/invwarp -r $SUBJ_NAME-dtifit_FA -w $ROI_DIR/reg_FA_1mm/dti2std_warp -o $ROI_DIR/reg_dti/std2dti_warp
echo "subj $SUBJ_NAME autoPtx_preproc : creating native space reference volume in 1mm cubic resolution"
run $FSLDIR/bin/flirt -in $SUBJ_NAME-dtifit_FA -ref $SUBJ_NAME-dtifit_FA -applyisoxfm 1 -out refVol
run $FSLDIR/bin/fslmaths refVol -mul 0 refVol    

