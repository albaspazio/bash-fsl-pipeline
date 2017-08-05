#!/bin/bash

#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo $@
#echo "-----------------------------------------------------------------"
# ==================================================================================
# usage:	. ./path/create_1group_2sessions_paired_diff_subjectscontrasts_glm.sh /path/proj_dir -model path/templ.fsf -odp /path/output_dir -isubjf /path/input_subjects_file.txt -nuisids "1,2,3" -covids "4,5,6" -nomodelcreate
# ==================================================================================

# ==================================================================================
# create a FSF file starting from a template and filling in:
# - N covariates 
# - X nuisance (without associated contrast) 
# values contained in $SUBJECTS_FILE
# must write $OUT_FSF_NAME variable  

# UNDER UPGRADE ....
# template has been already modeled with the correct elements (number of subjects, group composition and, number of contrast and EV columns) 
# the script just fill in the values.

# ====== set init params =============================================================================
PROJ_DIR=$1; shift

INPUT_TEMPL_GLM_FSF=""		# /home/...../proj_label/script/glm/.....fsf
declare -i NUM_SUBJ=0					# ..../colegios_dat_21subj.txt : file containing tab separated subject data
CREATE_MODEL=1 						#	if 1 call feat_model at the end to create .mat/.con file for randomise analysis...if 0 no..to be used for Feat analysis
RND_NAME=""								# string to be appended to output GLM files, useful when you create several design simultaneously
													

while [ ! -z "$1" ]
do
  case "$1" in
  
			-nsubj) 					NUM_SUBJ=$2
												shift;;
												  
  		-model)						INPUT_TEMPL_GLM_FSF=$2;
  											shift;;
  							
      -odp) 						OUTPUT_ROOT_DIR=$2
												shift;;
								
			-rndname) 				RND_NAME=$2
												shift;;	
								
			-nomodel)					CREATE_MODEL=0;;
								
      *)								break;;
  esac
  shift
done

if [ ! -f $INPUT_TEMPL_GLM_FSF ]; then
	echo "error..INPUT_TEMPL_GLM_FSF ($INPUT_TEMPL_GLM_FSF) is missing....exiting"
	exit
fi

#RND_NAME=""
templ_name=$(basename $INPUT_TEMPL_GLM_FSF)
#=======================================================
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#=======================================================
if [ ! -d $OUTPUT_ROOT_DIR ]; then
  mkdir $OUTPUT_ROOT_DIR
fi
#---------------------------------------------------------------------------------------------------------------------

declare -i tot_EV=$NUM_SUBJ
declare -i tot_CONT=$NUM_SUBJ
declare -i npts=2*$NUM_SUBJ
declare -i ev=0
declare -i sid=0

OUTPUT_GLM_FSF=$OUTPUT_ROOT_DIR/$RND_NAME${templ_name}
cp $INPUT_TEMPL_GLM_FSF $OUTPUT_GLM_FSF

# ==========  overridding GLM file
echo "" >> $OUTPUT_GLM_FSF
echo "# ==================================================================================================" >> $OUTPUT_GLM_FSF
echo "# ====== s t a r t   o v e r r i d e    ============================================================" >> $OUTPUT_GLM_FSF
echo "# ==================================================================================================" >> $OUTPUT_GLM_FSF

# Number of subjects
echo "set fmri(npts) $npts" >> $OUTPUT_GLM_FSF
echo "set fmri(multiple) $npts" >> $OUTPUT_GLM_FSF

# Number of EVs
echo "set fmri(evs_orig) $tot_EV" >> $OUTPUT_GLM_FSF
echo "set fmri(evs_real) $tot_EV" >> $OUTPUT_GLM_FSF

# Number of contrasts
echo "set fmri(ncon_orig) $tot_CONT" >> $OUTPUT_GLM_FSF
echo "set fmri(ncon_real) $tot_CONT" >> $OUTPUT_GLM_FSF

echo "#====================== init EV data" >> $OUTPUT_GLM_FSF
for (( s=1; s <= $tot_EV; s++ ))
do
	echo "set fmri(shape"$s") 2" >> $OUTPUT_GLM_FSF
	echo "set fmri(convolve"$s") 0" >> $OUTPUT_GLM_FSF
	echo "set fmri(convolve_phase"$s") 0" >> $OUTPUT_GLM_FSF
	echo "set fmri(tempfilt_yn"$s") 0" >> $OUTPUT_GLM_FSF
	echo "set fmri(deriv_yn"$s") 0" >> $OUTPUT_GLM_FSF
	echo "set fmri(custom"$s") dummy" >> $OUTPUT_GLM_FSF

	for (( t=0; t <= $tot_EV; t++ ))
	do
		echo "set fmri(ortho"$s"."$t") 0" >> $OUTPUT_GLM_FSF
	done
done


# =================================================================================================
echo "#====================== init to 1 groupsmem" >> $OUTPUT_GLM_FSF
for (( s=1; s <= $npts; s++ ))
do
	echo "set fmri(groupmem.$s) 1" >> $OUTPUT_GLM_FSF	
done

# =================================================================================================
echo "#====================== set nuisance event titles" >> $OUTPUT_GLM_FSF
for (( ev=1; ev<=$tot_EV; ev++ ))
do
  echo "set fmri(evtitle$ev) \"subj$ev\"" >> $OUTPUT_GLM_FSF
done

echo "#====================== init all cells to 0" >> $OUTPUT_GLM_FSF  
for (( s=1; s <= $npts; s++ ))
do
	for (( ev=1; ev<=$tot_EV; ev++ ))
	do
		echo "set fmri(evg$s.$ev) 0" >> $OUTPUT_GLM_FSF
	done
done

for (( ev=1; ev<=$tot_EV; ev++ ))
do
	sid=$(echo "scale=0;($ev-1)*2+1" | bc)
	echo "set fmri(evg$sid.$ev) 1" >> $OUTPUT_GLM_FSF
	sid=$(echo "scale=0;($ev-1)*2+2" | bc)
	echo "set fmri(evg$sid.$ev) -1" >> $OUTPUT_GLM_FSF
done

# =================================================================================================
# C O N T R A S T S
echo "#====================== reset all contrast values" >> $OUTPUT_GLM_FSF
for (( ev=1; ev<=$tot_EV; ev++ ))
do
	for (( con_id=1; con_id<=$tot_CONT; con_id++ ))
	do
		echo "set fmri(con_real$con_id.$ev) 0" >> $OUTPUT_GLM_FSF
	done
done

echo "#====================== set contrasts" >> $OUTPUT_GLM_FSF

for (( con_id=1; con_id<=$tot_CONT; con_id++ ))
do
	echo "set fmri(conpic_real.$con_id) 1" >> $OUTPUT_GLM_FSF
	echo "set fmri(conname_real.$con_id) \"subj$con_id\"" >> $OUTPUT_GLM_FSF
	echo "set fmri(con_real$con_id.$con_id) 1" >> $OUTPUT_GLM_FSF
done


# =================================================================================================
if [ $CREATE_MODEL -eq 1 ]; then

	MODEL_NOEXT=${OUTPUT_GLM_FSF%.*}
	feat_model $MODEL_NOEXT

	if [ $? -gt 0 ]; then
		echo "#===> KO: Error in feat_model"
		exit 1
	fi
fi
echo "#===> OK: multiple covariate GLM model ($OUTPUT_GLM_FSF) correctly created"

