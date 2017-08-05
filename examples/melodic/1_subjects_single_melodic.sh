#!/bin/bash

# ============================================================================================
#				 S T E P  1  :  S I N G L E   S U B J E C T S   M E L O D I C
# ==========================================================================================

GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/krusty/home/dati/fsl_resting_belgrade_controls
export FSLDIR=/usr/share/fsl/4.1														
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1

. $PROJ_SCRIPT_DIR/subjects_list.sh   	

EXECUTE_SH=$GLOBAL_SUBJECT_SCRIPT_DIR/execute_subject_melodic.sh	
melodic_fsf_template=$PROJ_SCRIPT_DIR/glm/singlesubj_melodic

declare -i NUM_CPU=2

#=================================================================
# standard call....read: SUBJ_NAME/rs/resting.nii.gz and write,  create a folder: SUBJ_NAME/resting/resting.ica
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -model $melodic_fsf_template

# non-standard input file....  read: SUBJ_NAME/resting/resting_skip4vol.nii.gz, create a folder SUBJ_NAME/resting/resting.ica
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -ifn resting_skip4vol -model $melodic_fsf_template 

# non-standard input file and folder....  read: SUBJ_NAME/resting2/resting_skip4vol.nii.gz, create a folder SUBJ_NAME/resting2/resting.ica
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -ifn resting_skip4vol -idn resting2 -model $melodic_fsf_template 

# non-standard input file and folder and output dir....  read: SUBJ_NAME/resting2/resting_skip4vol.nii.gz, create a folder SUBJ_NAME/resting2/resting_denoised.ica
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -ifn resting_skip4vol -idn resting2 -model $melodic_fsf_template -odn resting_denoised


wait
echo "=================>>>>  End processing"subjects_single_melodic.sh
