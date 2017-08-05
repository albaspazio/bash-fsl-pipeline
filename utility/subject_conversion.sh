

# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
SESS_ID=$1; shift
# ====== static variables: do not edit !  ============================================================
if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh


# ==================================================================================
# PROCESSING
# ==================================================================================
cd $SUBJECT_DIR

count=`ls -1 $SUBJECT_DIR/*.v2 2>/dev/null | wc -l`
if [ $count != 0 ]
then 
	echo $SUBJ_NAME
	
	
	cd $SUBJECT_DIR
	dcm2nii $SUBJECT_DIR

	# move original .v2
	dest_dicom_dir=../../dicom/$SUBJ_NAME/s$SESS_ID
	mkdir -p $dest_dicom_dir
	mv *.v2 $dest_dicom_dir

fi



