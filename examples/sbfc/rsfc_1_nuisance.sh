#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/homer/home/dati/fsl_belgrade_early_pd						# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
export FSLDIR=/usr/share/fsl/4.1														# change according to used PC	
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
. $PROJ_SCRIPT_DIR/subjects_list.sh

SESS_ID=1

NUM_CPU=1
EXECUTE_SH=$GLOBAL_SCRIPT_DIR/process_subject/rsfc_motion_nuisance_feat.sh

# standard call: reads /SUBJ_NAME/resting/resting.nii.gz
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR

# reads /SUBJ_NAME/resting/resting_skip4vol.nii.gz
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR resting_skip4vol # rs_denoised

wait

echo "finished executing $0"
