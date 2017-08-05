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
EXECUTE_SH=$GLOBAL_SCRIPT_DIR/process_group/rsfc_multiple_roi_group_feat.sh

. $PROJ_SCRIPT_DIR/subjects_list.sh

declare -a arr_1stlevel_input_roi=(roi_right_caud roi_right_pall roi_right_put roi_right_thal)
str_arr_1stlevel_input_roi=`echo ${arr_1stlevel_input_roi[@]}`

OUTPUT_DIR=$PROJ_GROUP_ANALYSIS_DIR/rsfc/ctrl_treated_naive
fsf_template=$PROJ_SCRIPT_DIR/glm/templates/groupfeat_ctrl28_treated45_naive21_maskgm

CONTROLS_SUBJ_DIR=/media/data/MRI/projects/CAB/fsl_resting_belgrade_controls/subjects

# create 1st level feat roots list
first_level_feat_roots=""

for SUBJ_NAME in ${arr_controls28[@]}
do
	first_level_feat_roots="$first_level_feat_roots $CONTROLS_SUBJ_DIR/$SUBJ_NAME/s$SESS_ID/resting/fc/feat"
done

for SUBJ_NAME in ${arr_treated45[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	first_level_feat_roots="first_level_feat_roots $RSFC_DIR/feat"
done

for SUBJ_NAME in ${arr_naive21[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	first_level_feat_roots="$first_level_feat_roots $RSFC_DIR/feat"
done

#====================================================================================
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_1stlevel_input_roi" $PROJ_DIR -model $fsf_template -odp $OUTPUT_DIR -ncope 8 $first_level_feat_roots
wait


echo "=====================> finished processing $0"

