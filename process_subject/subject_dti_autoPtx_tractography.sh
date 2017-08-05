

# ===== check parameters ==============================================================================
if [ -z $1 ]; then
  echo $usage_string
  exit
fi
# ====== set init params =============================================================================
OVERWRITE=0;
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
#if [ "$#" -gt 0]; then
#	OVERWRITE=$1;
#fi

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

structures=$AUTOPTX_SCRIPT_PATH/structureList

report_file=$PROBTRACKX_DIR/autoPtx_waytotal_resume.txt
[ -e $report_file ] && rm $report_file

while read structstring; do
    struct=`echo $structstring | awk '{print $1}'`
		tracts=$PROBTRACKX_DIR/$struct    
		
		if [ ! -e $PROBTRACKX_DIR/$struct/tracts/$struct"_density.nii.gz" -o $OVERWRITE -eq 1 ]; then		
		  nseed=`echo $structstring | awk '{print $2}'`
		  run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_struct.sh $SUBJ_NAME $PROJ_DIR $struct $nseed
		  
		  run mv $PROBTRACKX_DIR/$struct/tracts/density.nii.gz $PROBTRACKX_DIR/$struct/tracts/$struct"_density.nii.gz"
		  run mv $PROBTRACKX_DIR/$struct/tracts/tractsNorm.nii.gz $PROBTRACKX_DIR/$struct/tracts/$struct"_norm.nii.gz"
		fi
		
		way=`cat $tracts/tracts/waytotal | sed 's/e/\\*10^/' | tr -d '+' `
		run echo -e "$struct\t$way" >> $report_file		
done < $structures


