#!/bin/bash
# ======================================================================================
#				 S T E P  2 : G R O U P   T E M P L A T E    C R E A T I O N 
# ======================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/krusty/home/dati/fsl_resting_belgrade_controls				# <<<<@@@@@@@@@@@@@@@@@@@@
. $GLOBAL_SCRIPT_DIR/use_fsl 5													
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh


SUBJECT_MELODIC_OUTPUT_DIR=resting  # melodic output folder name of single subject

TR_VALUE=3.0																										# <<<<@@@@@@@@@@@@@@@@@@@@
output_template_name=belgrade_dyt_other_controls21_skip4vol			# <<<<@@@@@@@@@@@@@@@@@@@@
arr_subj=${arr_controls[@]}																			# <<<<@@@@@@@@@@@@@@@@@@@@

# subject input file name
SUBJECT_INPUT_FILE_NAME=$RS_POST_NUISANCE_MELODIC_STANDARD_IMAGE_LABEL
#SUBJECT_INPUT_FILE_NAME=${RS_POST_NUISANCE_MELODIC_IMAGE_LABEL}_$SUBJECT_MELODIC_OUTPUT_DIR
#=========================================================================================================
#=========================================================================================================
#=========================================================================================================
#=========================================================================================================
#=========================================================================================================
MELODIC_OUTPUT_DIR=$PROJ_GROUP_ANALYSIS_DIR/melodic/group_templates/$output_template_name

[ -d $MELODIC_OUTPUT_DIR ] && rm -rf $MELODIC_OUTPUT_DIR
mkdir -p $MELODIC_OUTPUT_DIR

filelist=$MELODIC_OUTPUT_DIR/.filelist_$output_template_name

echo "creating file lists"
bglist=""
masklist=""	

#=================================================================================
for SUBJ_NAME in ${arr_patients[@]}
do
  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  bglist="$bglist $RS_REGSTD_DIR/bg_image" 	
  masklist="$masklist $RS_REGSTD_DIR/mask"	
  echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
done

. $GLOBAL_GROUP_SCRIPT_DIR/do_groupmelodic.sh $MELODIC_OUTPUT_DIR $filelist $bglist $masklist $TR_VALUE
echo "=================>>>>  End processing"
