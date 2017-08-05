#!/bin/bash

# ============================================================================================
#				 S T E P  2b  :  T E M P L A T E    M E A N I N G  &  M A S K I N G  
# ============================================================================================

GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/homer/home/dati/FSL_RESTING_MD				
export FSLDIR=/usr/share/fsl/4.1											
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================

SINGLE_IC_PRUNING_SCRIPT=$GLOBAL_GROUP_SCRIPT_DIR/dual_regression_split2singleIC.sh
EXECUTE_STATS_SH=$GLOBAL_GROUP_SCRIPT_DIR/dual_regression_randomize_singleIC_multiple_folders_mean_mask.sh

NUM_PERM=5000
NUM_CPU=3
NUM_SUBJECTS=78			# preserved for backward compatibility																				

. $GLOBAL_SCRIPT_DIR/melodic_templates/belgrade_controls_md_skip4vol.sh			# load template-related variables
TEMPLATE_DIR=$PROJ_GROUP_ANALYSIS_DIR/melodic/group_templates/$template_name
filelist=$TEMPLATE_DIR/.filelist_$template_name
DR_DIR=$TEMPLATE_DIR/dr

#===============================================================================================================================================
#===============================================================================================================================================
#===============================================================================================================================================
#===============================================================================================================================================
#===============================================================================================================================================
#===============================================================================================================================================
#===============================================================================================================================================

	
echo "start DR SORT !!"
. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_sort.sh $TEMPLATE_MELODIC_IC 1 $DR_DIR `cat $filelist`

echo "start DR SPLIT 2 SINGLE ICs !!"
. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_split2singleIC.sh $TEMPLATE_MELODIC_IC $DR_DIR $DR_DIR $NUM_SUBJECTS "$str_pruning_ic_id" "$str_arr_IC_labels" 

str_folders="$DR_DIR/${arr_IC_labels[0]}"
for ic in ${arr_IC_labels[@]:1}
do
	str_folders="$str_folders $DR_DIR/$ic"
done

. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_STATS_SH "$str_folders" $PROJ_DIR -nperm $NUM_PERM -maskf $GLOBAL_DATA_TEMPLATES/gray_matter/mask_T1_gray_4mm.nii.gz

mkdir -p $TEMPLATE_DIR/mask

for ic in ${arr_IC_labels[@]}
do
	input_file=$DR_DIR/$ic/mean/$ic"_mean_mask_tfce_corrp_tstat1.nii.gz"
	output_file=$TEMPLATE_DIR/mask/"mask_"$RSN_LABEL.nii.gz
	fslmaths $input_file -thr 0.998 -bin $output_file
done

rm -rf $DR_DIR
wait
echo "=================>>>>  End processing"
