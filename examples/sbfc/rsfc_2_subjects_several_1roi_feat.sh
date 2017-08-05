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




NUM_CPU=2
EXECUTE_SH=$GLOBAL_SCRIPT_DIR/process_subject/subject_epi_sbfc_several_1roi_feat.sh

# base name of ROI: final name used by the script will be $ROI_DIR/reg_epi/mask_ROINAME_epi.nii.gz
declare -a arr_roi=(l_caudate_hos_fsl l_pallidum_hos_fsl l_putamen_hos_fsl l_thalamus_hos_fsl)

ALTERNATIVE_TEMPL_FSF=$PROJ_SCRIPT_DIR/glm/templates/template_feat_roi.fsf  # can be omitted...as it is already the default template used by the script

# alternative call: define input file name and output series postfix name

OUTPUT_DIR_NAME2=roi_left_caud_pall_put_thal_ortho_denoised
ALTERNATIVE_INPUT_NUISANCE_FILE="nuisance_denoised_10000"
OUTPUT_SERIES_POSTFIX_NAME="denoised" # "skip4vol"
#====================================================================================
declare -a final_roi=()
declare -i cnt=0

for roi in ${arr_roi[@]}; do
	final_roi[cnt]=reg_epi/mask_$roi"_epi.nii.gz"
	cnt=$cnt+1 
done	

## !!!!! the OUTPUT feat folder name is defined in this way: feat_$ROINAME"_"$OUTPUT_SERIES_POSTFIX_NAME

# default call: read $RSFC_DIR/nuisance_10000.nii.gz and use template_feat_roi.fsf
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR ${final_roi[@]} # -model $ALTERNATIVE_TEMPL_FSF if u want a special feat setup
# default call but with a custom template : read $RSFC_DIR/nuisance_10000.nii.gz and use ALTERNATIVE_TEMPL_FSF
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -model $ALTERNATIVE_TEMPL_FSF ${final_roi[@]} 
# alternative call: read $RSFC_DIR/nuisance_denoised_10000.nii.gz
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$arr_subj" $PROJ_DIR -ifn $ALTERNATIVE_INPUT_NUISANCE_FILE -son $OUTPUT_SERIES_POSTFIX_NAME ${final_roi[@]} 
wait	


echo "=====================> finished processing $0"

