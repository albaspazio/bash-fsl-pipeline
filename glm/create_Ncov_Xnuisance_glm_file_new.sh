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
SUBJECTS_FILE=""					# ..../colegios_dat_21subj.txt : file containing tab separated subject data
NUISANCE_COLUMNS=""				# comma separated columns ID. column of interest:  according to a 1-based array !!! so add -1 to adjust to 0-based arrays
COVARIATE_COLUMNS=""			# column of interest:  according to a 1-based array !!! so add -1 to adjust to 0-based arrays 
CREATE_MODEL=1 						#	if 1 call feat_model at the end to create .mat/.con file for randomise analysis...if 0 no..to be used for Feat analysis
RND_NAME=""								# string to be appended to output GLM files, useful when you create several design simultaneously
REGR_COMP=0								# if 1: create also covariate comparison contrast: e.g.  [0  1 -1], [0 -1  1]
GROUPSLASTSIDS=""					# comma-separated string contaning the ID of the last subject of each group.
													# eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group
NUM_MEAN_CONTRASTS=1 			# manage the creation of the mean contrast (valid when NUM_COVS>0)													
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
								
			-isubjf)					SUBJECTS_FILE=$2
												shift;;
								
			-groupslastids)		GROUPSLASTSIDS=$2
												shift;;	
																	
			-nuisids)					NUISANCE_COLUMNS=$2
												shift;;									
			
			-covids)					COVARIATE_COLUMNS=$2
												shift;;	
												
			-rndname) 				RND_NAME=$2
												shift;;	
								
			-dblcon)					NUM_MEAN_CONTRASTS=2;;

			-skipmean)				NUM_MEAN_CONTRASTS=0;;

			-nomodel)					CREATE_MODEL=0;;
								
			-regrcomp) 				REGR_COMP=1;;
								
      *) break;;
  esac
  shift
done

if [ ! -f $INPUT_TEMPL_GLM_FSF ]; then
	echo "error..INPUT_TEMPL_GLM_FSF ($INPUT_TEMPL_GLM_FSF) is missing....exiting"
	exit
fi

if [ ! -f $SUBJECTS_FILE ]; then
	echo "error..SUBJECTS_FILE ($SUBJECTS_FILE) is missing....exiting"
	exit
fi


factorial()
{
	fact=$1
	if [ $n -gt 0 ]; then for((i=$FACT_NUM;i>=1;i--)); do num_fact=`expr $fact \* $i`; done; fi; 
}



#RND_NAME=""

#=======================================================
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#=======================================================
if [ ! -d $OUTPUT_ROOT_DIR ]; then
  mkdir $OUTPUT_ROOT_DIR
fi
# ==========  Read covariate values  ===================
declare -a ARR_SUBJECTS=()
declare -a ARR_LABELS=()

declare -a ARR_COV=()
declare -a ARR_NUIS=()

declare -a ARR_NUISANCE_COLUMNS=()
declare -a ARR_COVARIATE_COLUMNS=()

declare -a ARR_USED_COV_LABELS=()
declare -a ARR_USED_NUIS_LABELS=()

declare -a ARR_GROUPS_LASTS=()

declare -i NUM_SUBJ=0
declare -i cnt=0
declare -i cnt2=0
declare -i ev=0
declare -i ev1=0
declare -i ev2=0
declare -i ncov=0
declare -i con_id=0

# transform comma separated column ID in array
OLD_IFS=$IFS; IFS=","

if [[ $NUISANCE_COLUMNS != "0" ]]; then ARR_NUISANCE_COLUMNS=( $NUISANCE_COLUMNS ); fi
if [[ $COVARIATE_COLUMNS != "0" ]]; then ARR_COVARIATE_COLUMNS=( $COVARIATE_COLUMNS ); fi
IFS=$OLD_IFS

declare -i NUM_COVS=${#ARR_COVARIATE_COLUMNS[@]} 
declare -i NUM_NUIS=${#ARR_NUISANCE_COLUMNS[@]} 


#---------------------------------------------------------------------------------------------------------------------
# check if a valid contrast will be created 
if [ $NUM_COVS -eq 0 -a $NUM_MEAN_CONTRASTS -eq 0 ]; then
	echo "error in create_Ncov_Xnuisance_glm_file.. NEITHER COVS or MEAN contrast were specified..dont know what to do, so....exiting"
	exit
fi

#---------------------------------------------------------------------------------------------------------------------
# READ FILE to fill cov/nuis arrays & define design name
# get also NUM_SUBJ

while read line   
do
#  declare -i len=${#line}-1; last_ch=${line[@]:len:1};  echo "last:$last_ch""__|"
  # len=$len-1;  line=${line[@]:0:len}  # remove last character (/r)
  
  # extract label from FIRST LINE
  if [ $cnt -eq 0 ]; then
    cnt=1
    declare -i len=${#line}-1; last_ch=${line[@]:len:1};
    # get columns labels, define OUT DIR, fsf file name and fill columns labels array
    # first covariates then nuisance values
    ARR_LABELS=( $line )
    OUT_FSF_NAME=$OUTPUT_ROOT_FILE_NAME
    if [ $NUM_COVS -gt 0 ]; then
		  for cov_id in ${ARR_COVARIATE_COLUMNS[@]}
		  do
		    cov_label=${ARR_LABELS[cov_id-1]}      
		    OUT_FSF_NAME=$OUT_FSF_NAME"_"$cov_label
#			  echo ---$OUT_FSF_NAME --- $cov_label
 		    ARR_USED_COV_LABELS[ncov]=$cov_label		# fill columns labels array
		    ncov=$ncov+1
		  done
		fi
#		echo OUT_FSF_NAME $OUT_FSF_NAME
    if [ $NUM_NUIS -gt 0 ]; then
		  OUT_FSF_NAME=$OUT_FSF_NAME"_x"
		  ncov=0
#		  echo $NUM_NUIS :: ${ARR_NUISANCE_COLUMNS[@]}    
    
		  for cov_id in ${ARR_NUISANCE_COLUMNS[@]}
		  do
		    cov_label=${ARR_LABELS[cov_id-1]}      
		    OUT_FSF_NAME=$OUT_FSF_NAME"_"$cov_label
		    ARR_USED_NUIS_LABELS[ncov]=$cov_label		# fill columns labels array
		    ncov=$ncov+1
		  done
		fi
		
    OUTPUT_GLM_FSF=$OUTPUT_ROOT_DIR/$OUT_FSF_NAME$RND_NAME.fsf
    
    [[ $INPUT_TEMPL_GLM_FSF != $OUTPUT_GLM_FSF ]] && cp $INPUT_TEMPL_GLM_FSF $OUTPUT_GLM_FSF
    continue
  fi

  # get columns: first nuisance than covariate
  subj=`echo $line | awk '{print $1}'`
  
  if [ -z $subj ]; then continue; fi;
  
  ARR_SUBJECTS[$NUM_SUBJ]=$subj 
  declare -i curr_cov=0
  for column_id in ${ARR_NUISANCE_COLUMNS[@]}
  do
    cov_val=`echo $line | awk '{print $'$column_id'}'`;
    declare -i arr_id=$NUM_SUBJ*$NUM_NUIS+$curr_cov   # echo "arr_id: "$arr_id
    ARR_NUIS[$arr_id]=$cov_val
    curr_cov=$curr_cov+1
  done

  declare -i curr_cov=0
  for column_id in ${ARR_COVARIATE_COLUMNS[@]}
  do
    cov_val=`echo $line | awk '{print $'$column_id'}'`;
    declare -i arr_id=$NUM_SUBJ*$NUM_COVS+$curr_cov   # echo "arr_id: "$arr_id
    ARR_COV[$arr_id]=$cov_val
    curr_cov=$curr_cov+1
  done
  NUM_SUBJ=$NUM_SUBJ+1
done < $SUBJECTS_FILE

#---------------------------------------------------------------------------------------------------------------------
# check num groups input params

if [ -z $GROUPSLASTSIDS ]; then 
	ARR_GROUPS_LASTS[0]=$NUM_SUBJ
else

	OLD_IFS=$IFS; IFS=","
	ARR_GROUPS_LASTS=( $GROUPSLASTSIDS );
	IFS=$OLD_IFS	
	NUM_GROUPS=${#ARR_GROUPS_LASTS[@]}
fi

declare -i tot_EV=0
declare -i tot_cont=2

# RULES TO CREATE THE CONTRASTS
# 1 group: 
# COVARIATES > 0 : each covariate have 1 EV and 2 contrast + 2 contrasts for group mean (unless SKIP_MEAN_CONTRASTS=1).
# COVARIATES = 0 : 1 contrasts for group mean (2 if DOUBLE_MEAN_CONTRASTS=1)
# 2+ groups:
# COVARIATES > 0 : each covariate have 1 EV + 1 contrast for each group .....group comparisons are not performed, we create 1 contrasts for each group
#						 			(2 if DOUBLE_MEAN_CONTRASTS=1)..(0 if SKIP_MEAN_CONTRASTS=1).
# COVARIATES = 0 : group comparisons + 1 contrast x group (2 if DOUBLE_MEAN_CONTRASTS=1).

tot_EV=$NUM_COVS*$NUM_GROUPS+$NUM_NUIS+$NUM_GROUPS	# Nnuisance*Ggroups + Mcov + Ggroups

if [ $NUM_GROUPS -eq 1 ]; then
	tot_cont=2*$NUM_COVS+$NUM_MEAN_CONTRASTS
else
	if [ $NUM_COVS -gt 0 ]; then
		NUM_MEAN_CONTRASTS=0
		tot_cont=2*$NUM_COVS*$NUM_GROUPS
	else # $NUM_COVS = 0
		tot_cont=$(echo "scale=0;$NUM_GROUPS*($NUM_GROUPS-1) + $NUM_MEAN_CONTRASTS*$NUM_GROUPS" | bc)
	fi
fi


# DEBUG
echo "---------------- S U M M A R Y -------------------------------------------------------------------------------"
echo "creating Ncov_Xnuisance with the following parameters:"
echo "NUM_COVS, NUM_NUIS, NUM_GROUPS : $NUM_COVS, $NUM_NUIS, $NUM_GROUPS"
echo "ARR_COV=${ARR_COV[@]}"
echo "ARR_NUIS=${ARR_NUIS[@]}"
echo "ARR_GROUPS_LASTS=${ARR_GROUPS_LASTS[@]}"
echo "NUM_GROUPS=$NUM_GROUPS"
echo "ARR_COVARIATE_COLUMNS=${ARR_COVARIATE_COLUMNS[@]}"
echo "ARR_NUISANCE_COLUMNS=${ARR_NUISANCE_COLUMNS[@]}"
echo "ARR_LABELS=${ARR_LABELS[@]}" 
echo "---------------------------------------------------------------------------------"


# echo "----------------${ARR_COV[@]}"
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
# N U I S A N C E 

echo "#====================== set nuisance event titles (event [1:$NUM_GROUPS] are the means and are not overwritten)" >> $OUTPUT_GLM_FSF
for (( cov_id=0; cov_id<$NUM_NUIS; cov_id++ ))
do
  NUISANCE_LABEL=${ARR_USED_NUIS_LABELS[cov_id]}
  cnt=$cov_id+1+$NUM_GROUPS
  
  echo "set fmri(evtitle$cnt) \"$NUISANCE_LABEL\"" >> $OUTPUT_GLM_FSF
done

echo "#====================== set nuisance values" >> $OUTPUT_GLM_FSF
for (( s=1; s <= $NUM_SUBJ; s++ ))
do
  for (( cov_id=0; cov_id<$NUM_NUIS; cov_id++ ))
  do
    cnt=$cov_id+1+$NUM_GROUPS
    cnt2=($s-1)*$NUM_NUIS+$cov_id
    echo "set fmri(evg$s.$cnt) ${ARR_NUIS[(cnt2)]}" >> $OUTPUT_GLM_FSF
  done
done


# =================================================================================================
# C O V A R I A T E S

echo "#====================== set covariates event titles (event [1:$NUM_GROUPS] are the means and are not overwritten)" >> $OUTPUT_GLM_FSF
for (( cov_id=0; cov_id<$NUM_COVS; cov_id++ ))
do
	for (( grp=1; grp <= $NUM_GROUPS; grp++ ))
	do
		COV_LABEL=${ARR_USED_COV_LABELS[cov_id]}
		ev=($cov_id+1)*$NUM_GROUPS+$NUM_NUIS+$grp
	
		echo "set fmri(evtitle$ev) \"$COV_LABEL group$grp\"" >> $OUTPUT_GLM_FSF
	done
done


echo "#====================== init to 0 covariates EV" >> $OUTPUT_GLM_FSF
declare -i startEVid=$NUM_GROUPS+1+$NUM_NUIS
for (( s=1; s <= $NUM_SUBJ; s++ ))
do
  for (( id=$startEVid; id<=$tot_EV; id++ ))
  do
	  echo "set fmri(evg$s.$id) 0" >> $OUTPUT_GLM_FSF		
	done
done



echo "#====================== set covariates values" >> $OUTPUT_GLM_FSF
for (( s=1; s <= ${ARR_GROUPS_LASTS[0]}; s++ ))
do
  for (( cov_id=0; cov_id<$NUM_COVS; cov_id++ ))
  do
	
	  cnt=($cov_id+1)*$NUM_GROUPS+1+$NUM_NUIS
	  cnt2=($s-1)*$NUM_COVS+$cov_id
	  echo "set fmri(evg$s.$cnt) ${ARR_COV[(cnt2)]}" >> $OUTPUT_GLM_FSF		
		
	done
done


declare -i firstsubjofgroup=0
declare -i lastsubjofgroup=0

for (( grp=2; grp <= $NUM_GROUPS; grp++ ))
do
	idgrpA=$grp-2
	idgrpB=$grp-1
	firstsubjofgroup=${ARR_GROUPS_LASTS[idgrpA]}+1
	lastsubjofgroup=${ARR_GROUPS_LASTS[idgrpB]}

  for (( cov_id=0; cov_id<$NUM_COVS; cov_id++ ))
  do	
		for (( s=$firstsubjofgroup; s<=$lastsubjofgroup; s++ ))
		do
			cnt=$NUM_GROUPS+$NUM_NUIS+$cov_id*$NUM_GROUPS+$grp
			cnt2=($s-1)*$NUM_COVS+$cov_id
			echo "set fmri(evg$s.$cnt) ${ARR_COV[(cnt2)]}" >> $OUTPUT_GLM_FSF	
		done
	done
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


declare -i ev_id=0
declare -i contr_id=0	
if [ $NUM_GROUPS -eq 1 ]; then
	# write mean contrasts if present
	if [ $NUM_MEAN_CONTRASTS -gt 0 ]; then  
		echo "set fmri(conpic_real.1) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.1) \"group1 pos\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real1.1) 1" >> $OUTPUT_GLM_FSF	
		if [ $NUM_MEAN_CONTRASTS -eq 2 ]; then
			echo "set fmri(conpic_real.2) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.2) \"group1 neg\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real2.1) -1" >> $OUTPUT_GLM_FSF	
		fi	
	fi
	# write cov contrasts if present
	for (( cov_id=0; cov_id<$NUM_COVS; cov_id++ ))
	do
		COV_LABEL=${ARR_USED_COV_LABELS[cov_id]}
		ev_id=$NUM_GROUPS+$NUM_NUIS+1+$cov_id
		
		# ===== POS CONTRAST	
		contr_id=$NUM_GROUPS*$NUM_MEAN_CONTRASTS+1+2*cov_id
		echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.$contr_id) \"pos $COV_LABEL\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real$contr_id.$ev_id) 1" >> $OUTPUT_GLM_FSF
	
		# ===== NEG CONTRAST
		contr_id=$contr_id+1
		echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
		echo "set fmri(conname_real.$contr_id) \"neg $COV_LABEL\"" >> $OUTPUT_GLM_FSF
		echo "set fmri(con_real$contr_id.$ev_id) -1" >> $OUTPUT_GLM_FSF	
	done		
else   # NUM_GROUPS > 1

	if [ $NUM_COVS -gt 0 ]; then  # test only interaction  covariate x group, no group mean & comparisons

		for (( cov_id=0; cov_id<$NUM_COVS; cov_id++ ))
		do
			COV_LABEL=${ARR_USED_COV_LABELS[cov_id]}
			for (( grp=1; grp <= $NUM_GROUPS; grp++ ))
			do	
				ev_id=$NUM_GROUPS+$NUM_NUIS+$cov_id*$NUM_GROUPS+$grp
				# ===== POS CONTRAST	
				contr_id=$(echo "scale=0;2*$cov_id*$NUM_GROUPS+($grp-1)*$NUM_GROUPS+1" | bc)						
				echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
				echo "set fmri(conname_real.$contr_id) \"group$grp pos $COV_LABEL\"" >> $OUTPUT_GLM_FSF
				echo "set fmri(con_real$contr_id.$ev_id) 1" >> $OUTPUT_GLM_FSF
		
				# ===== NEG CONTRAST
				contr_id=$contr_id+1				
				echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
				echo "set fmri(conname_real.$contr_id) \"group$grp neg $COV_LABEL\"" >> $OUTPUT_GLM_FSF
				echo "set fmri(con_real$contr_id.$ev_id) -1" >> $OUTPUT_GLM_FSF
			done
		done


	else # $NUM_COVS = 0, NUM_MEAN_CONTRASTS = 1 or 2

		for (( grp=1; grp <= $NUM_GROUPS; grp++ ))
		do	
			contr_id=$contr_id+1
			echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$contr_id) \"group$grp pos\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$contr_id.$grp) 1" >> $OUTPUT_GLM_FSF			

			if [ $NUM_MEAN_CONTRASTS -eq 2 ]; then
				contr_id=$contr_id+1
				echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
				echo "set fmri(conname_real.$contr_id) \"group$grp neg\"" >> $OUTPUT_GLM_FSF
				echo "set fmri(con_real$contr_id.$grp) -1" >> $OUTPUT_GLM_FSF			
			fi
		done	

		# pairwise comparisons between groups
		if [ $NUM_GROUPS -eq 2 ]; then
			contr_id=$contr_id+1
			echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$contr_id) \"group1 > group2\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$contr_id.1) 1" >> $OUTPUT_GLM_FSF				
			echo "set fmri(con_real$contr_id.2) -1" >> $OUTPUT_GLM_FSF				

			contr_id=$contr_id+1
			echo "set fmri(conpic_real.$contr_id) 1" >> $OUTPUT_GLM_FSF
			echo "set fmri(conname_real.$contr_id) \"group2 > group1\"" >> $OUTPUT_GLM_FSF
			echo "set fmri(con_real$contr_id.1) -1" >> $OUTPUT_GLM_FSF				
			echo "set fmri(con_real$contr_id.2) 1" >> $OUTPUT_GLM_FSF				
		else 
			echo "error in create_Ncov_Xnuisance_glm_file.. pairwise comparisons among more than 2 groups are still not implemented.....exiting"
			exit
		fi
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

