#!/bin/bash
# ======================================================================================
#				 S T E P  2 : G R O U P   T E M P L A T E    C R E A T I O N 
# ======================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/krusty/home/dati/fsl_patients_project										# <<<<@@@@@@@@@@@@@@@@@@@@
. $GLOBAL_SCRIPT_DIR/use_fsl 4 # or 5														
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh

CTRL_PROJ_DIR=/krusty/home/dati/fsl_resting_belgrade_controls			# <<<<@@@@@@@@@@@@@@@@@@@@
TR_VALUE=3.0																											# <<<<@@@@@@@@@@@@@@@@@@@@
output_template_name=belgrade_dyt_controls21_patients45_skip4vol	# <<<<@@@@@@@@@@@@@@@@@@@@

arr_ctrl=${arr_controls21[@]}																			# <<<<@@@@@@@@@@@@@@@@@@@@
arr_patients=${arr_patients45[@]}																	# <<<<@@@@@@@@@@@@@@@@@@@@
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
  echo "$RS_REGSTD_IMAGE"_"skip4vol" >> $filelist;
done

. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
for SUBJ_NAME in ${arr_patients[@]}
do
  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  bglist="$bglist $RS_REGSTD_DIR/bg_image"
  masklist="$masklist $RS_REGSTD_DIR/mask"
  echo "$RS_REGSTD_IMAGE"_"skip4vol" >> $filelist;
done

. $GLOBAL_GROUP_SCRIPT_DIR/do_groupmelodic.sh $MELODIC_OUTPUT_DIR $filelist $bglist $masklist $TR_VALUE
echo "=================>>>>  End processing"
