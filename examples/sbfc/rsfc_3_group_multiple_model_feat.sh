#!/bin/bash

WORK_IN_CAB=0
# ====== init params ===========================
if [ $WORK_IN_CAB -eq 0 ]
then
	GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
	PROJ_DIR=/media/data/MRI/projects/CAB/fsl_belgrade_early_pd 					# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	export FSLDIR=/usr/local/fsl																# change according to used PC
else
	GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
	PROJ_DIR=/media/Iomega_HDD/MRI/projects/CAB/fsl_belgrade_early_pd		# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	export FSLDIR=/usr/share/fsl/4.1														# change according to used PC	
fi

#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
NUM_CPU=1
EXECUTE_SH=$GLOBAL_SCRIPT_DIR/process_group/rsfc_multiple_model_group_feat.sh

. $PROJ_SCRIPT_DIR/subjects_list.sh

INPUT_1stlevel_DIR="roi_right_caud_pall_put_thal_ortho_denoised"

OUTPUT_DIR=$PROJ_GROUP_ANALYSIS_DIR/sbfc/$INPUT_1stlevel_DIR
declare -a arr_fsf_templates=($PROJ_SCRIPT_DIR/glm/templates/groupfeat_ctrl28_treated45_naive21_maskgm )
str_arr_fsf_templates=`echo ${arr_fsf_templates[@]}`

CONTROLS_SUBJ_DIR=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/subjects

# create 1st level feat dir list
first_level_feat_paths=""

for SUBJ_NAME in ${arr_controls28[@]}
do
	first_level_feat_paths="$first_level_feat_paths $CONTROLS_SUBJ_DIR/$SUBJ_NAME/s$SESS_ID/resting/fc/feat/$INPUT_1stlevel_DIR"
done

for SUBJ_NAME in ${arr_treated45[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	first_level_feat_paths="$first_level_feat_paths $RSFC_DIR/feat/$INPUT_1stlevel_DIR"
done

for SUBJ_NAME in ${arr_naive21[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	first_level_feat_paths="$first_level_feat_paths $RSFC_DIR/feat/$INPUT_1stlevel_DIR"
done

#====================================================================================
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_fsf_templates" $PROJ_DIR -odp $OUTPUT_DIR -ncope 8 $first_level_feat_paths
wait


echo "=====================> finished processing $0"

