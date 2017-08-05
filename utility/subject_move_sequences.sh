

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

# expected file size limits
rs=(15000000 22000000)
dti=(115000000 200000000)
mpr=(8000000 13000000)
wb=(400000 800000)
t2=(3000000 6000000)

echo processing SUBJECT_DIR : $SUBJECT_DIR
cd $SUBJECT_DIR

# create subject file system
mkdir -p $SUBJECT_DIR/mpr
mkdir -p $SUBJECT_DIR/resting
mkdir -p $SUBJECT_DIR/dti
mkdir -p $SUBJECT_DIR/wb
mkdir -p $SUBJECT_DIR/t2
mkdir -p $SUBJECT_DIR/roi
mkdir -p $SUBJECT_DIR/ot

# remove possible duplicates
#mv *A.nii.gz *A.nii.gz__
#mv *B.nii.gz *B.nii.gz__
#mv *C.nii.gz *C.nii.gz__
#mv *D.nii.gz *D.nii.gz__
#mv *E.nii.gz *E.nii.gz__

#mv *A.bval
#mv *B.bval
#mv *C.bval
#mv *D.bval
#mv *E.bval

#mv *A.bvec
#mv *B.bvec
#mv *C.bvec
#mv *D.bvec
#mv *E.bvec

# move localizer and calibration to OT folder
mkdir -p $SUBJECT_DIR/ot
mv *s001* $SUBJECT_DIR/ot
mv *s002* $SUBJECT_DIR/ot
mv *s5* $SUBJECT_DIR/ot
mv *s6* $SUBJECT_DIR/ot
mv *s7* $SUBJECT_DIR/ot

for f in *.nii.gz
do

	FILESIZE=$(stat -c%s "$f")
	echo processing $f of size $FILESIZE

	
	# mpr
	if [ $FILESIZE -gt ${mpr[0]} -a $FILESIZE -lt ${mpr[1]} ]; then
	
		first2ch=${f:0:2}
		firstch=${f:0:1}
#		echo $first2ch : $firstch
		if [ $first2ch = 'co' ]; then 
			mv $f $T1_DIR/co$T1_IMAGE_LABEL.nii.gz
	  else
	  	if [ $firstch = 'o' ]; then 
	  		mv $f $T1_DIR/c$T1_IMAGE_LABEL.nii.gz
	  	else
	  		mv $f $T1_DATA.nii.gz
	  	fi
	  fi
		
	fi
	
	# t2
	if [ $FILESIZE -gt ${t2[0]} -a $FILESIZE -lt ${t2[1]} ]; then
		mv $f $T2_DATA.nii.gz
	fi
	
	# resting
	if [ $FILESIZE -gt ${rs[0]} -a $FILESIZE -lt ${rs[1]} ]; then
		mv $f $RS_DATA.nii.gz
	fi
	
	# wb
	if [ $FILESIZE -gt ${wb[0]} -a $FILESIZE -lt ${wb[1]} ]; then
		mv $f $WB_DATA.nii.gz
	fi
	
	# dti
	if [ $FILESIZE -gt ${dti[0]} -a $FILESIZE -lt ${dti[1]} ]; then
		mv $f $DTI_DATA.nii.gz
	fi					
	
done


mv *.bval $DTI_DIR/$DTI_BVAL
mv *.bvec $DTI_DIR/$DTI_BVEC


