	#!/bin/bash

# ============================================================================================
#				 S T E P  4  : R A N D O M I S E
# ==========================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts_new
PROJ_DIR=/homer/home/dati/FSL_RESTING_DYT																			# <<<<@@@@@@@@@@@@@@@@@@@@						
. $GLOBAL_SCRIPT_DIR/use_fsl 5													
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================

NUM_CPU=2																																			# <<<<@@@@@@@@@@@@@@@@@@@@	
NUM_PERM=5000																																	# <<<<@@@@@@@@@@@@@@@@@@@@	
EXECUTE_STATS_SH=$GLOBAL_GROUP_SCRIPT_DIR/dual_regression_randomize_singleIC_multiple_folders.sh
#--------------------------------------------------------------------------------------------------------------------------------------
. $GLOBAL_SCRIPT_DIR/melodic_templates/belgrade_controls36_dyt50_skip4vol.sh # define templates variables # <<<<@@@@@@@@@@@@@@@@@@@@	

in_population_name=dyt_b_st_wc_skip4vol					# as defined in step3 (sorting) $out_population_name			# <<<<@@@@@@@@@@@@@@@@@@@@	

in_GLM_FILE=$PROJ_SCRIPT_DIR/glm/b_st_wc_x_age	# as defined by GLM program																# <<<<@@@@@@@@@@@@@@@@@@@@	
out_analysis_name=dyt_b_st_wc_maskrsn						# group_analysis/melodic/dr/$in_population_name/RSN_LABEL/$out_analysis_name	# <<<<@@@@@@@@@@@@@@@@@@@@	

in_path_to_specific_mask=/ddfdf/dfsfdf/dfsdfd/mask_gm.nii.gz
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
#--------------------------------------------------------------------------------------------------------------------------------------
ANALYSIS_OUTPUT_DIR_ROOT=$PROJ_GROUP_ANALYSIS_DIR/melodic/dr/templ_$template_name/$in_population_name
# do STATS !!
#arr_IC_labels=(DMN)   # remove the "#" to restrict analysis to some networks, or change analysis order

str_folders="$ANALYSIS_OUTPUT_DIR_ROOT/${arr_IC_labels[0]}"
for ic in ${arr_IC_labels[@]:1}
do
	str_folders="$str_folders $ANALYSIS_OUTPUT_DIR_ROOT/$ic"
done

# use default dual regression derived mask
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_STATS_SH "$str_folders" $PROJ_DIR -model $in_GLM_FILE -nperm $NUM_PERM -odn $out_analysis_name
# specify a file mask
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_STATS_SH "$str_folders" $PROJ_DIR -model $in_GLM_FILE -nperm $NUM_PERM -odn $out_analysis_name -maskf $in_path_to_specific_mask     
# specify a folder which must contain several files called   mask_RSNLABEL.nii.gz
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_STATS_SH "$str_folders" $PROJ_DIR -model $in_GLM_FILE -nperm $NUM_PERM -odn $out_analysis_name -maskd $TEMPLATE_MASK_FOLDER 
# GM correction... insert GLM column and path to gm demeaned 4d_file. 
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_STATS_SH "$str_folders" $PROJ_DIR -model $in_GLM_FILE -nperm $NUM_PERM -odn $out_analysis_name -vxl $num_column_in_glm -vxf $path_to_gm_demeaned_4d_file
wait
echo "=============> finished $0"
