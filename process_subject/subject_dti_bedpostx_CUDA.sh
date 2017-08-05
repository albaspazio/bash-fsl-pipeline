# usage : $GLOBAL_SCRIPT_DIR/process/execute_subject_ec_dtifit.sh sassi 003 1 1
#
# NEEDS TO BE CALLED WITH SUDO !!!
#
# script to be used for data that:
# 	were already converted in nifti and in their correct directory
# 	calculate DTI
# ===== check parameters ==============================================================================
if [ $# -lt 2 ]; then
  echo "Usage: $0 subj_label proj_path bedpost_output_dir"
  echo "calculate BEDPOSTX:"
  exit
fi
# ====== set init params =============================================================================
SUBJ_NAME=$1
PROJ_PATH=$2
OUTPUT_DIR_NAME=$3

if [ $# -eq 4 ]; then 
	STD_IMAGE=$4
else
	STD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain
fi

#. $GLOBAL_SCRIPT_DIR/use_fsl 4
# ==================================================================================
. $GLOBAL_SCRIPT_DIR/utility_functions.sh
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

if [ -z $OUTPUT_DIR_NAME ]; then
	BEDPOST_DIR=$DTI_DIR/bedpost_x
	BEDPOST_OUT_DIR=$BEDPOST_DIR.bedpostX
	OUTPUT_DIR_NAME=bedpostx
else
	BEDPOST_DIR=$DTI_DIR/bedpost_x$OUTPUT_DIR_NAME
	BEDPOST_OUT_DIR=$BEDPOST_DIR.bedpostX	
fi

if [ -d "$DTI_DIR" ]; then
  if [ "$(ls -A $DTI_DIR)" ]; then
    echo "setting output dir to: $BEDPOST_DIR"

    mkdir -p $BEDPOST_DIR
    cp $DTI_DATA"_"ec.nii.gz $BEDPOST_DIR/data.nii.gz
    cp $DTI_DATA.bval $BEDPOST_DIR/bvals
    cp $DTI_DATA"_rotated".bvec $BEDPOST_DIR/bvecs
    cp $DTI_DIR/nodif_brain_mask.nii.gz $BEDPOST_DIR
 
    $FSLDIR/bin/bedpostx_datacheck $BEDPOST_DIR

    if [ $? -gt 0 ]; then
      echo "......................................................Error in $BEDPOST_DIR directory"
      exit
    fi
    $FSLDIR/bin/bedpostx_gpu $BEDPOST_DIR -n 2 -w 1 -b 1000
    if [ -f $BEDPOST_OUT_DIR/mean_S0samples.nii.gz ]; then 
    	mv $BEDPOST_OUT_DIR $DTI_DIR/$OUTPUT_DIR_NAME
    	rm -rf $BEDPOST_DIR
    else	
    	echo "ERROR in bedpostx !!!!!"
    fi
 fi
fi

. $GLOBAL_SCRIPT_DIR/use_fsl 5
# =============================================
# registration to MNI152_T1_2mm_brain (using subject T1_brain)

cp $ROI_DIR/reg_t1/dti2highres.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/diff2str.mat
cp $ROI_DIR/reg_dti/highres2dti.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/str2diff.mat
cp $ROI_DIR/reg_standard/highres2standard.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/str2standard.mat
cp $ROI_DIR/reg_t1/standard2highres.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/standard2str.mat
cp $ROI_DIR/reg_standard/dti2standard.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/diff2standard.mat
cp $ROI_DIR/reg_dti/standard2dti.mat $DTI_DIR/$OUTPUT_DIR_NAME/xfms/standard2diff.mat


