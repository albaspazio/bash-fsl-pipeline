

# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
SESS_ID=$1; shift
log_file=$1; shift
# ====== static variables: do not edit !  ============================================================
if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh


# ==================================================================================
# PROCESSING
# ==================================================================================
cd $SUBJECT_DIR

str_images="$SUBJ_NAME s$SESS_ID:"

for dir in *; 
do
	if [ -d $dir ]
	then
		count=`ls -1 $SUBJECT_DIR/$dir/*.nii.gz 2>/dev/null | wc -l`
		if [ $count != 0 ]
		then 
			str_images="$str_images "$dir"=yes"
			echo $SUBJ_NAME
		else
			str_images="$str_images "$dir"=no"
		fi
	fi
done

echo $str_images >> $log_file
echo $str_images
