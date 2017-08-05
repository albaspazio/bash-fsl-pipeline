#!/bin/bash




# ============================================================================================
#				 S T E P  3  :  S O R T I N G  (dual regression) + S P L I T T I N G 
# ============================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts_new
PROJ_DIR=/homer/home/dati/FSL_RESTING_MD																		# <<<<@@@@@@@@@@@@@@@@@@@@		
. $GLOBAL_SCRIPT_DIR/use_fsl 5										
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1

# input subjects' array (defined in the patients project script dir)
. $PROJ_SCRIPT_DIR/subjects_list.sh
arr_patients=${arr_md_corr[@]}																							# <<<<@@@@@@@@@@@@@@@@@@@@


# load template-related variables
. $GLOBAL_SCRIPT_DIR/melodic_templates/belgrade_controls_md_skip4vol.sh			# <<<<@@@@@@@@@@@@@@@@@@@@

# populations investigated					
out_population_name=controls_md_skip4vol																		# <<<<@@@@@@@@@@@@@@@@@@@@

# subject input file name
SUBJECT_INPUT_FILE_NAME=$RS_POST_NUISANCE_MELODIC_STANDARD_IMAGE_LABEL
#SUBJECT_INPUT_FILE_NAME=${RS_POST_NUISANCE_MELODIC_IMAGE_LABEL}_$SUBJECT_MELODIC_OUTPUT_DIR

#===== operations ==========================================
DO_SORT=1
DO_SPLIT=1
#=========================================================================
# output DR dir
DR_DIR=$PROJ_GROUP_ANALYSIS_DIR/melodic/dr/templ_$template_name/$out_population_name 
#=========================================================================
# CHECK  PARAMS  
#=========================================================================
[ ! -d $PATIENT_PROJ_DIR ] && echo "ERROR: PATIENTS SUBJECT DIR NOT present"

[ -d $DR_DIR ] && rm -rf $DR_DIR
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
#================================================================================================================================
if [ $DO_SORT -eq 1 ]
then
	mkdir -p $DR_DIR
	filelist=$DR_DIR/.filelist_$out_population_name

	#=================================================================================
	echo "creating PATIENTS file lists"
	for SUBJ_NAME in ${arr_patients[@]}
	do
	  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  	echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
	done

	echo "start DR SORT !!"
	. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_sort.sh $TEMPLATE_MELODIC_IC 1 $DR_DIR `cat $filelist`
fi

if [ $DO_SPLIT -eq 1 ]
then
	echo "start DR SPLIT 2 SINGLE ICs !!"
	. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_split2singleIC.sh $TEMPLATE_MELODIC_IC $DR_DIR $DR_DIR "$str_pruning_ic_id" "$str_arr_IC_labels" 
fi
echo "=================>>>>  End processing"
