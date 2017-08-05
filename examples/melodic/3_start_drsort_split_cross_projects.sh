#!/bin/bash


PATIENT_PROJ_DIR=/gnappo/home1/dati/BELGRADO_1.5Philips/MD		# <<<<@@@@@@@@@@@@@@@@@@@@		
CTRL_PROJ_DIR=/gnappo/home2/dati/BELGRADO_1.5Philips/HC				# <<<<@@@@@@@@@@@@@@@@@@@@		

# is the study dir where group analysis will be done, often the patients dir
PROJ_DIR=$PATIENT_PROJ_DIR    															  # <<<<@@@@@@@@@@@@@@@@@@@@	
# ============================================================================================
#				 S T E P  3  :  S O R T I N G  (dual regression) + S P L I T T I N G 
# ============================================================================================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
. $GLOBAL_SCRIPT_DIR/use_fsl 5												
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1

# input subjects' array (defined in the patients project script dir)
. $PROJ_SCRIPT_DIR/subjects_list.sh
arr_ctrl=${arr_controls_md[@]}																					# <<<<@@@@@@@@@@@@@@@@@@@@
arr_patients=${arr_md_corr[@]}																					# <<<<@@@@@@@@@@@@@@@@@@@@

# load template-related variables
. $GLOBAL_SCRIPT_DIR/melodic_templates/controls_pls_for_MDstudy.sh			# <<<<@@@@@@@@@@@@@@@@@@@@

# populations investigated					
out_population_name=controls_pls_for_MDstudy_md													# <<<<@@@@@@@@@@@@@@@@@@@@

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
[ ! -d $CTRL_PROJ_DIR ] && echo "ERROR: CTRL PROJ DIR NOT present"
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
	echo "creating CONTROL file lists"
	. $GLOBAL_SCRIPT_DIR/init_vars.sh $CTRL_PROJ_DIR
	for SUBJ_NAME in ${arr_ctrl[@]}
	do
	  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	  echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
	done

	echo "creating PATIENTS file lists"
	. $GLOBAL_SCRIPT_DIR/init_vars.sh $PATIENT_PROJ_DIR
	for SUBJ_NAME in ${arr_patients[@]}
	do
	  . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	  echo "$RS_FINAL_REGSTD_DIR/$SUBJECT_INPUT_FILE_NAME" >> $filelist;
	done

	echo "start DR SORT !!"
	. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
	. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_sort.sh $TEMPLATE_MELODIC_IC 1 $DR_DIR `cat $filelist`
fi

if [ $DO_SPLIT -eq 1 ]
then
	echo "start DR SPLIT 2 SINGLE ICs !!"
	. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
	. $GLOBAL_GROUP_SCRIPT_DIR/dual_regression_split2singleIC.sh $TEMPLATE_MELODIC_IC $DR_DIR $DR_DIR "$str_pruning_ic_id" "$str_arr_IC_labels" 
fi
echo "=================>>>>  End processing"
