#!/bin/bash


PATIENT_PROJ_DIR=/gnappo/home1/dati/BELGRADO_1.5Philips/MD		# <<<<@@@@@@@@@@@@@@@@@@@@		
CTRL_PROJ_DIR=/gnappo/home2/dati/BELGRADO_1.5Philips/HC				# <<<<@@@@@@@@@@@@@@@@@@@@

# is the study dir where group analysis will be done, often the patients dir
PROJ_DIR=$PATIENT_PROJ_DIR    															  # <<<<@@@@@@@@@@@@@@@@@@@@		
# ======================================================================================
#				 S T E P  2 : G R O U P   T E M P L A T E    C R E A T I O N 
# ======================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
. $GLOBAL_SCRIPT_DIR/use_fsl 5								
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1

# input subjects' array (defined in the patients project script dir)
. $PROJ_SCRIPT_DIR/subjects_list.sh
arr_ctrl=${arr_controls21[@]}																			# <<<<@@@@@@@@@@@@@@@@@@@@
arr_patients=${arr_patients45[@]}																	# <<<<@@@@@@@@@@@@@@@@@@@@

TR_VALUE=3.0																											# <<<<@@@@@@@@@@@@@@@@@@@@

# name of the output template
output_template_name=belgrade_dyt_controls21_patients45_skip4vol	# <<<<@@@@@@@@@@@@@@@@@@@@

# subject input file name
SUBJECT_INPUT_FILE_NAME=$RS_POST_NUISANCE_MELODIC_STANDARD_IMAGE_LABEL
#SUBJECT_INPUT_FILE_NAME=${RS_POST_NUISANCE_MELODIC_IMAGE_LABEL}_$SUBJECT_MELODIC_OUTPUT_DIR


#=========================================================================
# CHECK  PARAMS  
#=========================================================================
[ ! -d $PATIENT_PROJ_DIR ] && echo "ERROR: PATIENTS SUBJECT DIR NOT present"
[ ! -d $CTRL_PROJ_DIR ] && echo "ERROR: CTRL PROJ DIR NOT present"
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
# use RS_REGSTD_DIR/RS_REGSTD_IMAGE or RS_REGSTD_DENOIS_DIR/RS_REGSTD_DENOIS_IMAGE
# skip4vol is appended at the end of the file

. $GLOBAL_SCRIPT_DIR/init_vars.sh $CTRL_PROJ_DIR
for SUBJ_NAME in ${arr_ctrl[@]}
do
  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  bglist="$bglist $RS_REGSTD_DIR/bg_image"
  masklist="$masklist $RS_REGSTD_DIR/mask"
  echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
done

. $GLOBAL_SCRIPT_DIR/init_vars.sh $PATIENT_PROJ_DIR
for SUBJ_NAME in ${arr_patients[@]}
do
  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  bglist="$bglist $RS_REGSTD_DIR/bg_image"
  masklist="$masklist $RS_REGSTD_DIR/mask"
  echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
done

. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
. $GLOBAL_GROUP_SCRIPT_DIR/do_groupmelodic.sh $MELODIC_OUTPUT_DIR $filelist $bglist $masklist $TR_VALUE
echo "=================>>>>  End processing"
