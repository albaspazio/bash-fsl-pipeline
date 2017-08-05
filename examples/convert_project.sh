#!/bin/bash


# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls 					# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================

# usalo cosi 

cd $SUBJECTS_DIR
for SUBJ_NAME in *
do
	echo $SUBJ_NAME
	. $GLOBAL_SCRIPT_DIR/utility/convert_file_system.sh $SUBJ_NAME $PROJ_DIR
done


# oppure 

. $PROJ_SCRIPT_DIR/subjects_list.sh

for SUBJ_NAME in ${arr_XXX[@]} # arr contenuto in subjects_list.sh
do
	echo $SUBJ_NAME
	. $GLOBAL_SCRIPT_DIR/utility/convert_file_system.sh $SUBJ_NAME $PROJ_DIR
done
