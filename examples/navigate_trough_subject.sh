#!/bin/bash

# ====== init params ===========================

GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/dados/MRI/projects/temperamento_murcia
. use_fsl 5
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh

for SUBJ_NAME in ${arr_all_subjects[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	# now you can access all the variables of each subject contained in the list "arr_all_subjects"

done

