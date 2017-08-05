

# ===== check parameters ==============================================================================
if [ -z $1 ]; then
  echo $usage_string
  exit
fi
# ====== set init params =============================================================================


PROJ_DIR=$1; shift


structures=$AUTOPTX_SCRIPT_PATH/structureList
report_file=$PROJ_GROUP_ANALYSIS_DIR/tbss/autoPtx_waytotal_resume.txt
[ -e $report_file ] && rm $report_file


for
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	while read structstring; do
		  struct=`echo $structstring | awk '{print $1}'`
			tracts=$PROBTRACKX_DIR/$struct    
		
			way=`cat $tracts/tracts/waytotal | sed 's/e/\\*10^/' | tr -d '+' `
			echo -e "$struct\t$way" >> $report_file		
	done < $structures
done

