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

EXECUTE_SH=$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_roi.sh

roi_folder=/media/dados/MRI/projects/temperamento_murcia/group_analysis/melodic/dr/templ_subjects80_baseline_aroma/subjects77_baseline_aroma/results/standard4

declare -i NUM_CPU=8


declare -a arr_rois_names=(R_ATN_FRONT_ampliasmate_brevesmate R_ATN_PREFRONT_ampliasmate_brevesmate) 

declare -a arr_rois_paths=()
declare -i cnt=0
for roi in ${arr_rois_names[@]}
do
	arr_rois_paths[cnt]=$roi_folder/$roi
	cnt=$cnt+1
done

. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_all_subjects77" $PROJ_DIR -regtype std42epi -nlin -pathtype abs ${arr_rois_paths[@]}

wait






echo "=================>>>>  End processing"
