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
# ==================================================================================
if [ -d "$DTI_DIR" ]; then
  if [ "$(ls -A $DTI_DIR)" ]; then
    cd $DTI_DIR
    # image processing
    echo "creating mask"
    run $FSLDIR/bin/fslroi $DTI_IMAGE_LABEL nodif 0 1
    run $FSLDIR/bin/bet nodif nodif_brain -m -f 0.3
    echo "starting eddy_correct on $DTI_IMAGE_LABEL"
    [ ! -f $DTI_DIR/$DTI_IMAGE_LABEL"_ec".nii.gz ] && run $FSLDIR/bin/eddy_correct $DTI_IMAGE_LABEL $DTI_IMAGE_LABEL"_ec" 0
    run $FSLDIR/bin/fdt_rotate_bvecs $DTI_IMAGE_LABEL.bvec $DTI_IMAGE_LABEL"_rotated".bvec $DTI_IMAGE_LABEL"_ec".ecclog 
    echo "starting dtifit on "$DTI_IMAGE_LABEL"_ec"
    run $FSLDIR/bin/dtifit --sse -k $DTI_IMAGE_LABEL"_ec" -o $SUBJ_NAME-dtifit -m nodif_brain_mask -r $DTI_IMAGE_LABEL"_rotated".bvec -b $DTI_IMAGE_LABEL.bval
  fi
fi
