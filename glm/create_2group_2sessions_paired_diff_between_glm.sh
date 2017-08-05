#!/bin/bash

#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo "-----------------------------------------------------------------"
#echo $@
#echo "-----------------------------------------------------------------"
# ==================================================================================
# usage:	. ./path/create_1group_2sessions_paired_diff_glm.sh /path/proj_dir -model path/templ.fsf -odp /path/output_dir -isubjf /path/input_subjects_file.txt -nuisids "1,2,3" -covids "4,5,6" -nomodelcreate
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
CREATE_MODEL=1 						#	if 1 call feat_model at the end to create .mat/.con file for randomise analysis...if 0 no..to be used for Feat analysis
RND_NAME=""								# string to be appended to output GLM files, useful when you create several design simultaneously
GROUPSLASTSIDS=""					# comma-separated string contaning the ID of the last subject of each group.
													# eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group													
declare -i NUM_GROUPS=1 	# manage the number of groups in the design. each group will have its regressor (EV). 
 													# covariates/nuisance regressors will be appended starting from the (NUM_GROUPS+1)th column_id
SESS_MODE=time						# specify if input is first arranged by time or by subject
													#  		-time:		difference between => for ((s=0, s<S, s++));  (2*s+2) - 2*s+1 ......s1t1 s1t2 s2t1 s2t2, ....
													#			-subj:		difference between => for ((s=0, s<S, s++));  (s+1 + S) - s+1			......s1t1 s2t1 s3t1, ...., s1t2 s2t2 s3t2 													
OUTPUT_POSTFIX_NAME="" 
 													
while [ ! -z "$1" ]
do
  case "$1" in
  
			-groupslastids)		GROUPSLASTSIDS=$2  # cannot be empty
												shift;;	
												  
  		-model)						INPUT_TEMPL_GLM_FSF=$2;
  											shift;;
  							
      -odp) 						OUTPUT_ROOT_DIR=$2
												shift;;
												
      -opfn) 						OUTPUT_POSTFIX_NAME=$2
												shift;;		
																				
			-rndname) 				RND_NAME=$2
												shift;;	
												
			-sessmode) 				SESS_MODE=$2
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

#=======================================================
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#=======================================================
if [ ! -d $OUTPUT_ROOT_DIR ]; then
  mkdir $OUTPUT_ROOT_DIR
fi
#---------------------------------------------------------------------------------------------------------------------
declare -a ARR_GROUPS_LASTS=()
declare -i NUM_SUBJ=0

OLD_IFS=$IFS; IFS=","
ARR_GROUPS_LASTS=( $GROUPSLASTSIDS );
IFS=$OLD_IFS	
NUM_GROUPS=${#ARR_GROUPS_LASTS[@]}

NUM_SUBJ=${ARR_GROUPS_LASTS[(NUM_GROUPS-1)]}
#---------------------------------------------------------------------------------------------------------------------



declare -i tot_EV=$NUM_GROUPS+$NUM_SUBJ
declare -i tot_CONT=2
declare -i npts=2*$NUM_SUBJ
declare -i ev=0
declare -i sid=0
declare -i idgrpA=0
declare -i idgrpB=0


echo "---------------- S U M M A R Y -------------------------------------------------------------------------------"
echo "creating 2groups x 2sessions paired diff glm file  with the following parameters:"
echo "NUM_GROUPS : $NUM_GROUPS"
echo "ARR_GROUPS_LASTS=${ARR_GROUPS_LASTS[@]}"
echo "tot_EV : $tot_EV"
echo "NUM_SUBJ : $NUM_SUBJ"
echo "npts : $npts"
echo "---------------------------------------------------------------------------------"


#RND_NAME=""
templ_name=$(basename $INPUT_TEMPL_GLM_FSF)
templ_name_noext="${templ_name%.*}"

OUTPUT_GLM_FSF=$OUTPUT_ROOT_DIR/$RND_NAME${templ_name_noext}${OUTPUT_POSTFIX_NAME}.fsf
OUTPUT_GLM_GRP=$OUTPUT_ROOT_DIR/$RND_NAME${templ_name_noext}${OUTPUT_POSTFIX_NAME}.grp
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

# ------------------------------------------------------------------------
echo "#====================== set EV titles (event [1:$NUM_GROUPS] are the means and are not overwritten)" >> $OUTPUT_GLM_FSF

for (( ev=1; ev<=$NUM_GROUPS; ev++ ))
do
  echo "set fmri(evtitle$ev) \"grp$ev\"" >> $OUTPUT_GLM_FSF
done

declare -i firstsubjev=$NUM_GROUPS+1
for (( ev=$firstsubjev; ev<=$tot_EV; ev++ ))
do
	sid=$ev-2
  echo "set fmri(evtitle$ev) \"subj$sid\"" >> $OUTPUT_GLM_FSF
done
# ------------------------------------------------------------------------
# G R O U P S

echo "#====================== init to 0 groups' means" >> $OUTPUT_GLM_FSF
# scrive 
#set fmri(groupmem.1) 1
# ...............................
#set fmri(groupmem.$NUM_SUBJ)		1

#set fmri(evg1.1)	0	
#.....
#set fmri(evgNUM_SUBJ.NUM_GROUPS) 0

for (( s=1; s <= $npts; s++ ))
do
	echo "set fmri(groupmem.$s) 1" >> $OUTPUT_GLM_FSF	
	for (( grp=1; grp<=$NUM_GROUPS; grp++ ))
	do
		echo "set fmri(evg"$s".$grp) 0" >> $OUTPUT_GLM_FSF
	done
done

echo "#====================== set groups' means to actual values" >> $OUTPUT_GLM_FSF

if [ "$SESS_MODE" == "time" ]; then
	# ORDERED BY TIME
	# writes 
	#1		0
	#1		0
	#1		0
	#0		1
	#0		1
	#0		1
	grplast=$(echo "scale=0;2*${ARR_GROUPS_LASTS[0]}" | bc)
	for (( s=1; s <= $grplast; s++ ))
	do
		echo "set fmri(evg"$s".1) 1" >> $OUTPUT_GLM_FSF
	done

	declare -i firstsubjofgroup=0
	declare -i lastsubjofgroup=0
	for (( grp=2; grp <= $NUM_GROUPS; grp++ ))
	do
		idgrpA=$grp-2
		idgrpB=$grp-1
		firstsubjofgroup=$(echo "scale=0;2*(${ARR_GROUPS_LASTS[idgrpA]})+1" | bc)
		lastsubjofgroup=2*${ARR_GROUPS_LASTS[idgrpB]}
		for (( s=$firstsubjofgroup; s<=$lastsubjofgroup; s++ ))
		do
			echo "set fmri(evg"$s".$grp) 1" >> $OUTPUT_GLM_FSF
		done
	done


	# init columns (NUM_GROUPS+1)->(NUM_SUBJ+NUM_GROUPS)
	for (( s=1; s <= $npts; s++ ))
	do
		for (( ev=firstsubjev; ev<=$tot_EV; ev++ ))
		do
			echo "set fmri(evg$s.$ev) 0" >> $OUTPUT_GLM_FSF
		done
	done
	# set EV values
	#0	0		1		0		0
	#0	0	 -1		0		0
	#0	0		0		1		0
	#0	0		0	 -1		0
	for (( ev=firstsubjev; ev<=$tot_EV; ev++ ))
	do
			sid=$(echo "scale=0; 2*($ev-$firstsubjev)+1" | bc)
			echo "set fmri(evg$sid.$ev) 1" >> $OUTPUT_GLM_FSF
			sid=$(echo "scale=0;2*($ev-$firstsubjev)+2" | bc)
			echo "set fmri(evg$sid.$ev) -1" >> $OUTPUT_GLM_FSF
	done
	
else
	# ORDERED BY SUBJECT
	# writes 
	grplast=$(echo "scale=0;${ARR_GROUPS_LASTS[0]}" | bc)
	for (( s=1; s <= $grplast; s++ ))
	do
		echo "set fmri(evg"$s".1) 1" >> $OUTPUT_GLM_FSF
	done

	declare -i firstsubjofgroup=0
	declare -i lastsubjofgroup=0
	for (( grp=2; grp <= $NUM_GROUPS; grp++ ))
	do
		idgrpA=$grp-2
		idgrpB=$grp-1
		firstsubjofgroup=$(echo "scale=0;(${ARR_GROUPS_LASTS[idgrpA]})+1" | bc)
		lastsubjofgroup=${ARR_GROUPS_LASTS[idgrpB]}
		for (( s=$firstsubjofgroup; s<=$lastsubjofgroup; s++ ))
		do
			echo "set fmri(evg"$s".$grp) 1" >> $OUTPUT_GLM_FSF
		done
	done

	grplast=$(echo "scale=0;${ARR_GROUPS_LASTS[0]}" | bc)
	declare -i stid=$NUM_SUBJ+1
	declare -i endid=$NUM_SUBJ+$grplast
	
	for (( s=$stid; s <= $endid; s++ ))
	do
		echo "set fmri(evg"$s".1) 1" >> $OUTPUT_GLM_FSF
	done

	declare -i firstsubjofgroup=0
	declare -i lastsubjofgroup=0
	for (( grp=2; grp <= $NUM_GROUPS; grp++ ))
	do
		idgrpA=$grp-2
		idgrpB=$grp-1
		firstsubjofgroup=$(echo "scale=0;(${ARR_GROUPS_LASTS[idgrpA]})+$NUM_SUBJ+1" | bc)
		lastsubjofgroup=$(echo "scale=0;2*${ARR_GROUPS_LASTS[idgrpB]}+$NUM_SUBJ" | bc)
		for (( s=$firstsubjofgroup; s<=$lastsubjofgroup; s++ ))
		do
			echo "set fmri(evg"$s".$grp) 1" >> $OUTPUT_GLM_FSF
		done
	done

	# init columns (NUM_GROUPS+1)->(NUM_SUBJ+NUM_GROUPS)
	for (( s=1; s <= $npts; s++ ))
	do
		for (( ev=firstsubjev; ev<=$tot_EV; ev++ ))
		do
			echo "set fmri(evg$s.$ev) 0" >> $OUTPUT_GLM_FSF
		done
	done
	# set EV values
	#.	.		1		0		0
	#.	.		0		1		0
	#.....
	#.	.	 -1		0		0
	#.	.		0	 -1		0
	
	for (( ev=firstsubjev; ev<=$tot_EV; ev++ ))
	do
			sid=$(echo "scale=0; $ev-$firstsubjev+1" | bc)
			echo "set fmri(evg$sid.$ev) 1" >> $OUTPUT_GLM_FSF
			
			sid=$(echo "scale=0;$ev-$firstsubjev+1+$NUM_SUBJ" | bc)
			echo "set fmri(evg$sid.$ev) -1" >> $OUTPUT_GLM_FSF
	done

fi
# =================================================================================================
# C O N T R A S T S
echo "#====================== set contrasts" >> $OUTPUT_GLM_FSF

echo "set fmri(conpic_real.1) 1" >> $OUTPUT_GLM_FSF
echo "set fmri(conname_real.1) \"grp1>grp2\"" >> $OUTPUT_GLM_FSF
echo "set fmri(conpic_real.2) 1" >> $OUTPUT_GLM_FSF
echo "set fmri(conname_real.2) \"grp2>grp1\"" >> $OUTPUT_GLM_FSF		
		
echo "set fmri(con_real1.1) 1" >> $OUTPUT_GLM_FSF
echo "set fmri(con_real1.2) -1" >> $OUTPUT_GLM_FSF
echo "set fmri(con_real2.1) -1" >> $OUTPUT_GLM_FSF
echo "set fmri(con_real2.2) 1" >> $OUTPUT_GLM_FSF


# =================================================================================================
if [ $CREATE_MODEL -eq 1 ]; then

	MODEL_NOEXT=${OUTPUT_GLM_FSF%.*}
	feat_model $MODEL_NOEXT

	if [ $? -gt 0 ]; then
		echo "#===> KO: Error in feat_model"
		exit 1
	fi

	# create a new design.grp
	echo "/NumWaves	1" > $OUTPUT_GLM_GRP
	echo "/NumPoints	$npts" >>	$OUTPUT_GLM_GRP
	echo ""  >>	$OUTPUT_GLM_GRP
	echo "/Matrix" >>	$OUTPUT_GLM_GRP
	if [ "$SESS_MODE" == "time" ]; then
		for (( s=1; s <= $NUM_SUBJ; s++ ))
		do
			echo "$s" >> $OUTPUT_GLM_GRP 
			echo "$s" >> $OUTPUT_GLM_GRP 
		done
	else
		for (( s=1; s <= $NUM_SUBJ; s++ ))
		do
			echo "$s" >> $OUTPUT_GLM_GRP 
		done
		for (( s=1; s <= $NUM_SUBJ; s++ ))
		do
			echo "$s" >> $OUTPUT_GLM_GRP 
		done
	fi
fi	
	
	
fi
echo "#===> OK: multiple covariate GLM model ($OUTPUT_GLM_FSF) correctly created"

