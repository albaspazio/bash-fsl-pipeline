#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
PROJ_DIR=/homer/home/dati/fsl_belgrade_early_pd						  # <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
export FSLDIR=/usr/share/fsl/4.1														# change according to used PC	
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh
BASH_SCRIPT=$GLOBAL_SUBJECT_SCRIPT_DIR/dti_multiple_subject_probtrackx_seedmask_classificationtarget.sh
NUM_CPU=1
#===============================================

DO_OVERWRITE_TARGET_FILE=0

SEED_IMAGE_r=reg_dti/mask_R_Thal_dti.nii.gz
SEED_IMAGE_l=reg_dti/mask_L_Thal_dti.nii.gz

STOP_IMAGE_r=$GLOBAL_DATA_TEMPLATES/gray_matter/MNI152_T1_2mm_brain_left.nii.gz
STOP_IMAGE_l=$GLOBAL_DATA_TEMPLATES/gray_matter/MNI152_T1_2mm_brain_right.nii.gz

OUTPUT_DIR_NAME_r=r_thalamus_to_8lobes
OUTPUT_DIR_NAME_l=l_thalamus_to_8lobes

# ----- target list ----------------------------------------------------------------------------------------------------------------------
input_roi_dir=$GLOBAL_SCRIPT_DIR/data_templates/roi/2mm/lobes
target_list_file_r=$input_roi_dir/r_8lobes_list.txt
target_list_file_l=$input_roi_dir/l_8lobes_list.txt
declare -a target_image_list_r=(r_mask_1_pfc r_mask_2_premotor r_mask_3_precentral r_mask_4_postcentral r_mask_5_parietal_lobes r_mask_6_temporal_lobes r_mask_7_tempoccip r_mask_8_occipital_lobes)
declare -a target_image_list_l=(l_mask_1_pfc l_mask_2_premotor l_mask_3_precentral l_mask_4_postcentral l_mask_5_parietal_lobes l_mask_6_temporal_lobes l_mask_7_tempoccip l_mask_8_occipital_lobes)

if [ ! -f $target_list_file_r -o $DO_OVERWRITE_TARGET_FILE -eq 1 ]; then
	do echo "$input_roi_dir/${target_image_list_r[0]}.nii.gz" > $target_list_file_r
	for f in ${target_image_list_r[@]:1}; do echo "$input_roi_dir/$f.nii.gz" >> $target_list_file_r; done
fi

if [ ! -f $target_list_file_l -o $DO_OVERWRITE_TARGET_FILE -eq 1 ]; then
	do echo "$input_roi_dir/${target_image_list_l[0]}.nii.gz" > $target_list_file_l
	for f in ${target_image_list_l[@]:1}; do echo "$input_roi_dir/$f.nii.gz" >> $target_list_file_l; done
fi
#====================================================================================================================

. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $BASH_SCRIPT "$str_arr_pd65" $PROJ_DIR -odn $OUTPUT_DIR_NAME_r -maskp "mask" -seed $SEED_IMAGE_r -targetp $target_list_file_r -stopp $STOP_IMAGE_r
wait
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $BASH_SCRIPT "$str_arr_pd65" $PROJ_DIR -odn $OUTPUT_DIR_NAME_l -maskp "mask" -seed $SEED_IMAGE_l -targetp $target_list_file_l -stopp $STOP_IMAGE_l
wait


declare -i cnt=0
for SUBJ_NAME in ${arr_pd65[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	cnt=1
	for ROI_NAME in ${target_image_list_r[@]}
	do
		$FSLDIR/bin/fslmaths $PROBTRACKX_DIR/r_thalamus_to_8lobes/biggest -thr $cnt -uthr $cnt -bin $ROI_DIR/reg_dti/$ROI_NAME
		cnt=$cnt+1
	done
	cnt=1
	for ROI_NAME in ${target_image_list_l[@]}
	do
		$FSLDIR/bin/fslmaths $PROBTRACKX_DIR/l_thalamus_to_8lobes/biggest -thr $cnt -uthr $cnt -bin $ROI_DIR/reg_dti/$ROI_NAME
		cnt=$cnt+1
	done
done


echo "=====================> finished processing $0"

