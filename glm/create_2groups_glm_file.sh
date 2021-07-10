#!/bin/bash
#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo $@
#echo "-----------------------------------------------------------------"
# ==================================================================================
# usage:	. ./path/create_Ncov_Xnuisance_glm_file.sh /path/proj_dir -model path/templ.fsf -odp /path/output_dir -isubjf /path/input_subjects_file.txt -nuisids "1,2,3" -covids "4,5,6" -nomodelcreate
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

OUTPUT_ROOT_FILE_NAME=mult_cov
INPUT_TEMPL_GLM_FSF=""		# /home/...../proj_label/script/glm/.....fsf
CREATE_MODEL=1 						#	if 1 call feat_model at the end to create .mat/.con file for randomise analysis...if 0 no..to be used for Feat analysis
RND_NAME=""								# string to be appended to output GLM files, useful when you create several design simultaneously
REGR_COMP=0								# if 1: create also covariate comparison contrast: e.g.  [0  1 -1], [0 -1  1]
GROUPSLASTSIDS=""					# comma-separated string contaning the ID of the last subject of each group.
													# eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group
DOUBLE_MEAN_CONTRASTS=0 	# if 1, create a -1 contrast for each 1 contrast of the mean.
													
declare -i NUM_GROUPS=1 	# manage the number of groups in the design. each group will have its regressor (EV). 
 													# covariates/nuisance regressors will be appended starting from the (NUM_GROUPS+1)th column_id

while [ ! -z "$1" ]
do
  case "$1" in
  
  		-model)						INPUT_TEMPL_GLM_FSF=$2;
  											shift;;
  							
      -odp) 						OUTPUT_ROOT_DIR=$2
												shift;;
												
      -ofn) 						OUTPUT_ROOT_FILE_NAME=$2
												shift;;												
								
			-groupslastids)		GROUPSLASTSIDS=$2  # cannot be empty
												shift;;	
																	
			-rndname) 				RND_NAME=$2
												shift;;	
								
			-dblcon)					DOUBLE_MEAN_CONTRASTS=1;;

			-nomodel)					CREATE_MODEL=0;;
								
      *) break;;
  esac
  shift
done

if [ ! -f $INPUT_TEMPL_GLM_FSF ]; then
	echo "error..INPUT_TEMPL_GLM_FSF ($INPUT_TEMPL_GLM_FSF) is missing....exiting"
	exit
fi

if [ -z $GROUPSLASTSIDS ]; then 
	echo "error.. -groupslastids parameter cannot be empty....exiting"
	exit
fi
#RND_NAME=""

#=======================================================
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#=======================================================
if [ ! -d $OUTPUT_ROOT_DIR ]; then
  mkdir $OUTPUT_ROOT_DIR
fi
# ======================================================

declare -a ARR_GROUPS_LASTS=()
declare -i NUM_SUBJ=0

OLD_IFS=$IFS; IFS=","
ARR_GROUPS_LASTS=( $GROUPSLASTSIDS );
IFS=$OLD_IFS	
NUM_GROUPS=${#ARR_GROUPS_LASTS[@]}

declare -i tot_EV=0
declare -i tot_cont=2
declare -i MEAN_CONTRASTS=0

# RULES TO CREATE THE CONTRASTS
# 1 group: 
# 1 contrasts for group mean
# 2+ groups:
# group comparisons + 1 contrast x group.

tot_EV=$NUM_GROUPS	# G groups

if [ $NUM_GROUPS -eq 1 ]; then

	if [ $DOUBLE_MEAN_CONTRASTS -eq 1 ]; then
		tot_cont=2
	else
		tot_cont=1
	fi		
	MEAN_CONTRASTS=1 # grppos/grpneg
else
	# create grp1pos/grp1neg + grp2pos/grp2neg + grp1>grp2 + grp2>grp1
	MEAN_CONTRASTS=1
	if [ $DOUBLE_MEAN_CONTRASTS -eq 1 ]; then
		tot_cont=$(echo "scale=0;$NUM_GROUPS*($NUM_GROUPS-1) + 2*$NUM_GROUPS" | bc)
	else
		tot_cont=$(echo "scale=0;$NUM_GROUPS*($NUM_GROUPS-1) + $NUM_GROUPS" | bc)
	fi		
fi

# DEBUG
#echo "---------------- S U M M A R Y -------------------------------------------------------------------------------"
#echo "creating 2groups glm file  with the following parameters:"
#echo "NUM_GROUPS : $NUM_GROUPS"
#echo "ARR_GROUPS_LASTS=${ARR_GROUPS_LASTS[@]}"
#echo "---------------------------------------------------------------------------------"


# ==========  overridding GLM file
echo "" >> $OUTPUT_GLM_FSF
echo "# ==================================================================================================" >> $OUTPUT_GLM_FSF
echo "# ====== s t a r t   o v e r r i d e    ============================================================" >> $OUTPUT_GLM_FSF
echo "# ==================================================================================================" >> $OUTPUT_GLM_FSF

# Number of subjects
echo "set fmri(npts) $NUM_SUBJ" >> $OUTPUT_GLM_FSF
echo "set fmri(multiple) $NUM_SUBJ" >> $OUTPUT_GLM_FSF

# Number of EVs
echo "set fmri(evs_orig) $tot_EV" >> $OUTPUT_GLM_FSF
echo "set fmri(evs_real) $tot_EV" >> $OUTPUT_GLM_FSF

# Number of contrasts
echo "set fmri(ncon_orig) $tot_cont" >> $OUTPUT_GLM_FSF
echo "set fmri(ncon_real) $tot_cont" >> $OUTPUT_GLM_FSF

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
# G R O U P S

echo "#====================== init to 0 groups' means" >> $OUTPUT_GLM_FSF
for (( s=1; s <= $NUM_SUBJ; s++ ))
do
	echo "set fmri(groupmem.$s) 1" >> $OUTPUT_GLM_FSF	
	for (( grp=1; grp<=$NUM_GROUPS; grp++ ))
	do
		echo "set fmri(evg"$s".$grp) 0" >> $OUTPUT_GLM_FSF
	done
done

echo "#====================== set groups' means to actual values" >> $OUTPUT_GLM_FSF
for (( s=1; s <= ${ARR_GROUPS_LASTS[0]}; s++ ))
do
	echo "set fmri(evg"$s".1) 1" >> $OUTPUT_GLM_FSF
done


declare -i firstsubjofgroup=0
declare -i lastsubjofgroup=0

for (( grp=2; grp <= $NUM_GROUPS; grp++ ))
do
	idgrpA=$grp-2
	idgrpB=$grp-1
	firstsubjofgroup=${ARR_GROUPS_LASTS[idgrpA]}+1
	lastsubjofgroup=${ARR_GROUPS_LASTS[idgrpB]}
	
	for (( s=$firstsubjofgroup; s<=$lastsubjofgroup; s++ ))
	do
		echo "set fmri(evg"$s".$grp) 1" >> $OUTPUT_GLM_FSF
	done
done

echo "#====================== set groups' evtitle" >> $OUTPUT_GLM_FSF
for (( grp=1; grp<=$NUM_GROUPS; grp++ ))
do
	echo "set fmri(evtitle$grp) \"grp$grp\"" >> $OUTPUT_GLM_FSF
done

# =================================================================================================
# C O N T R A S T S

echo "#====================== reset contrast values" >> $OUTPUT_GLM_FSF
for (( ev_id=1; ev_id<=$tot_EV; ev_id++ ))
do
	for (( con_id=1; con_id<=$tot_cont; con_id++ ))
	do
		echo "set fmri(con_real$con_id.$ev_id) 0" >> $OUTPUT_GLM_FSF
	done
done

echo "#====================== set contrasts" >> $OUTPUT_GLM_FSF

if [ $NUM_GROUPS -eq 1 ]; then
	echo "set fmri(conpic_real.1) 1" >> $OUTPUT_GLM_FSF
	echo "set fmri(conname_real.1) \"group1 pos\"" >> $OUTPUT_GLM_FSF
	echo "set fmri(con_real1.1) 1" >> $OUTPUT_GLM_FSF	
	
	if [ $DOUBLE_MEAN_CONTRASTS -eq 1 ]; then
		echo "set fmri(conpic_real.2) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.2) \"group1 neg\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real2.1) -1" >> $OUTPUT_GLM_FSF	
	fi
else
	# 1 group mean for each group
	declare -i curr_cont=0
	con_id=0
	if [ $DOUBLE_MEAN_CONTRASTS -eq 1 ]; then	
		for (( grp=1; grp <= $NUM_GROUPS; grp++ ))
		do	
			con_id=$con_id+1
			echo "set fmri(conpic_real.$con_id) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$con_id) \"group$grp pos\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$con_id.$grp) 1" >> $OUTPUT_GLM_FSF			

			con_id=$con_id+1
			echo "set fmri(conpic_real.$con_id) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$con_id) \"group$grp neg\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$con_id.$grp) -1" >> $OUTPUT_GLM_FSF			
		done	
	else
		for (( grp=1; grp <= $NUM_GROUPS; grp++ ))
		do	
			echo "set fmri(conpic_real.$grp) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$grp) \"group$grp\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$grp.$grp) 1" >> $OUTPUT_GLM_FSF			
		done	
		con_id=$NUM_GROUPS
	fi
	# pairwise comparisons between groups
	if [ $NUM_GROUPS -eq 2 ]; then
		con_id=$con_id+1
		echo "set fmri(conpic_real.$con_id) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.$con_id) \"group1 > group2\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real$con_id.1) 1" >> $OUTPUT_GLM_FSF				
		echo "set fmri(con_real$con_id.2) -1" >> $OUTPUT_GLM_FSF				

		con_id=$con_id+1
		echo "set fmri(conpic_real.$con_id) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.$con_id) \"group2 > group1\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real$con_id.1) -1" >> $OUTPUT_GLM_FSF				
		echo "set fmri(con_real$con_id.2) 1" >> $OUTPUT_GLM_FSF				
	else 
		echo "contrasts to be implemented"
	fi
fi

# =================================================================================================
if [ $CREATE_MODEL -eq 1 ]; then

	MODEL_NOEXT=${OUTPUT_GLM_FSF%.*}
	feat_model $MODEL_NOEXT

	if [ $? -gt 0 ]; then
		echo "===> KO: Error in feat_model"
		exit 1
	fi
fi
echo "===> OK: multiple covariate GLM model ($OUT_FSF_NAME.fsf) correctly created"

