#!/bin/bash

GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/dados/MRI/projects/temperamento_murcia
. use_fsl 5
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================

# modify :
# 1- LAST_FOLDER
# 2- INPUT_FOLDER
# 3- arr_contrasts

# show Dual Regression results

#===============================================
# default variable in: show_dr_results_in_folder.sh
SHOW_IMAGE=1
WRITE_ONLY_SIGNIFICANT=1
THRESH_VALUE="0.95"
stats_type="corrp"

. $GLOBAL_SCRIPT_DIR/melodic_templates/controls_belgrade18_cab45_earlypd_skip4vol.sh
POPULATION_DIR=controls28_pd66_denoised

# results file is written by default in $MELODIC_POPULATION_DIR/results/RSN_$ICLABEL
#========================================================================
MELODIC_POPULATION_DIR=$PROJ_GROUP_ANALYSIS_DIR/melodic/dr/templ_$template_name/$POPULATION_DIR

#arr_IC_labels=(DMN)
for IC_NAME in ${arr_IC_labels[@]}
do
  INPUT_FOLDER=$MELODIC_POPULATION_DIR/$IC_NAME 
  result_file=$MELODIC_POPULATION_DIR/"RSN_"$STUDY_DIR"_"$IC_NAME"_"results.txt

  . $GLOBAL_SCRIPT_DIR/utility/show_dr_results_in_singleIC_subfolders.sh $INPUT_FOLDER -res $result_file -bgimg $TEMPLATE_BG_IMAGE -ifn "corrp" -showimg $SHOW_IMAGE -wrsign $WRITE_ONLY_SIGNIFICANT -thr $THRESH_VALUE -omr $MELODIC_STUDY_DIR/results/standard4
done
#========================================================================
#========================================================================
