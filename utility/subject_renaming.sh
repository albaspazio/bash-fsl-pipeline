

# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
SESS_ID=$1; shift
# ====== static variables: do not edit !  ============================================================
if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

HAS_T2=0
SESS=0
# ==================================================================================
# PROCESSING
# ==================================================================================
echo renaming subj : $SUBJ_NAME

# ---- T2 data ---------------------------------------------------------
HAS_T2=0
if [ -d "$T2_DIR" ]; then
  if [ "$(ls -A $T2_DIR)" ]; then
    cd $T2_DIR
    if [ ! -f $T2_DATA.nii.gz ]; then
      mv *.nii.gz $T2_DATA.nii.gz
    fi
    HAS_T2=1
  fi
fi

# ---- WB data ---------------------------------------------------------
if [ -d "$WB_DIR" ]; then
  if [ "$(ls -A $WB_DIR)" ]; then
    cd $WB_DIR
    if [ ! -f $WB_DATA.nii.gz ]; then
      mv *.nii.gz $WB_DATA.nii.gz
    fi
  fi
fi


# ---- RS data ---------------------------------------------------------
if [ -d "$RS_DIR" ]; then
  if [ "$(ls -A $RS_DIR)" ]; then
    cd $RS_DIR
    if [ ! -f $RS_DATA.nii.gz ]; then
      mv *.nii.gz $RS_DATA.nii.gz
    fi
  fi
fi

# ---- FMRI data ---------------------------------------------------------
for(( s=1; s<$SESS; s++ )); do
  CURR_FMRI_DIR=${FMRI_FOLDERS[$s]}
  CURR_FMRI_DATA_NAME=$SUBJ_NAME-fmri$s.nii.gz
   
  if [ -d "$CURR_FMRI_DIR" ]; then
    if [ "$(ls -A $CURR_FMRI_DIR)" ]; then
      cd $CURR_FMRI_DIR
      if [ ! -f $CURR_FMRI_DATA_NAME ]; then
        mv *.nii.gz $CURR_FMRI_DATA_NAME
        mkdir events
        mkdir model
      fi
    fi
  fi
done

# ---- T1 data ---------------------------------------------------------
if [ -d "$T1_DIR" ]; then
  if [ "$(ls -A $T1_DIR)" ]; then
    cd $T1_DIR
    if [ ! -f $T1_DATA ]; then
      # rename files
      mv co*.nii.gz co-$T1_IMAGE_LABEL.nii.gz2
      mv o*.nii.gz o-$T1_IMAGE_LABEL.nii.gz2
      mv *.nii.gz $T1_IMAGE_LABEL.nii.gz

      mv co*.nii.gz2 co-$T1_IMAGE_LABEL.nii.gz
      mv o*.nii.gz2 o-$T1_IMAGE_LABEL.nii.gz
    fi
  fi
fi

# ---- DTI data ---------------------------------------------------------
if [ -d "$DTI_DIR" ]; then
  if [ "$(ls -A $DTI_DIR)" ]; then
    cd $DTI_DIR
    if [ ! -f $DTI_IMAGE_LABEL.nii.gz ]; then
      mv *.nii.gz $DTI_IMAGE_LABEL.nii.gz
      mv *.bval $DTI_IMAGE_LABEL.bval
      mv *.bvec $DTI_IMAGE_LABEL.bvec
    fi
  fi
fi
