#!/bin/bash

# initialize GLOBAL and PROJECT vars
# caller should have set $GLOBAL_SCRIPT_DIR
# requires ($1): full path of PROJECTS dir


if [ -z $GLOBAL_SCRIPT_DIR ]
then
	echo "GLOBAL_SCRIPT_DIR not defined.....exiting"
	exit
fi

if [ $# -eq 0 ]; then
	echo "PROJ_DIR not defined....exiting"
  echo "usage: /path_to_scriptdir/init_vars.sh /...../proj_path"
	exit
else
	if [ ! -d $1 ]
	then
		echo "PROJ_DIR ($1) do not exist, please verify!...exiting"
		exit
	fi
	PROJ_DIR=$1
	PROJ_NAME=$(basename $1)
	INIT_VARS_DEFINED="1"
fi 


GLOBAL_GROUP_SCRIPT_DIR=$GLOBAL_SCRIPT_DIR/process_group
GLOBAL_SUBJECT_SCRIPT_DIR=$GLOBAL_SCRIPT_DIR/process_subject
GLOBAL_GLM_SCRIPT_DIR=$GLOBAL_SCRIPT_DIR/glm
GLOBAL_UTILITY_SCRIPT_DIR=$GLOBAL_SCRIPT_DIR/utility

GLOBAL_DATA_TEMPLATES=$GLOBAL_SCRIPT_DIR/data_templates
MULTICORE_SCRIPT_DIR=$GLOBAL_SCRIPT_DIR/multicore_scripting

FSL_BINS=$FSLDIR/bin
FSL_DATA_STANDARD=$FSLDIR/data/standard
FSL_STANDARD_MNI_2mm=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain
FSL_STANDARD_MNI_MASK_2mm=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain_mask

FSL_STANDARD_MNI_4mm=$GLOBAL_DATA_TEMPLATES/mpr/MNI152_T1_4mm_brain
STANDARD_AAL_ATLAS_2mm=$GLOBAL_DATA_TEMPLATES/mpr/aal_262_standard
VTK_TRANSPOSE_FILE=$GLOBAL_UTILITY_SCRIPT_DIR/transpose_dti32.awk



# projects dirs
PROJ_SCRIPT_DIR=$PROJ_DIR/script
PROJ_GROUP_SCRIPT_DIR=$PROJ_SCRIPT_DIR/group
PROJ_GROUP_ANALYSIS_DIR=$PROJ_DIR/group_analysis

SUBJECTS_DIR=$PROJ_DIR/subjects

ICA_AROMA_SCRIPT_PATH=$GLOBAL_SCRIPT_DIR/external_tools/ica_aroma/ica_aroma.py
AUTOPTX_SCRIPT_PATH=$GLOBAL_SCRIPT_DIR/external_tools/autoPtx_0_1_1

TRACKVIS_BIN=/media/data/MRI/scripts/external_tools/dtk

