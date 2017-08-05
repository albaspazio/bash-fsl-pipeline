#!/bin/bash

PROJ_DIR=$1; shift
SUBJ_NAME=$1; shift

GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
. use_fsl 5

#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

SESS_ID=1;
