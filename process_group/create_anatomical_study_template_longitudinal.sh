#!/bin/bash

# create a study specific template:

#    Choose a reference participant (ideally a participant that is typical of your study, and has good quality data)
#    1)	Use non-linear registration to register each participant to this reference participant
#    2)	Create an average image of all of the transformed images (including the reference participant)
#    3)	Register (non-linear) every participant (including the reference participant) to this average image
#    4) Average all of the transformed images


# ====== set init params =============================================================================
PROJ_DIR=$1; shift
OUTPUT_TEMPLATE_IMAGE=$1; shift
NUM_SESS=$1; shift

EXECUTE_SH=$GLOBAL_SUBJECT_SCRIPT_DIR/subject_fnirt.sh
REF_SUBJ=""
STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
NUM_CPU=1
CLEAN_INTERMEDIATE=1

while [ ! -z "$1" ]
do
  case "$1" in
  		-refsubj) REF_SUBJ=$2; shift;;
			-ncpu)		NUM_CPU=$2; shift;;
      -stdimg) 	STANDARD_IMAGE=$2
			      		if [ ! -f $STANDARD_IMAGE ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit;fi
								shift;;	
			-noclean)	CLEAN_INTERMEDIATE=0; shift;;				
      *) break;;
  esac
  shift
done


# ===============================================================================
# remaining parameters are subjects_list
declare -a arr_subj=( $@ )
str_arr_subj=`echo ${arr_subj[@]}` 

if [ -z $REF_SUBJ ]; then REF_SUBJ=${arr_subj[0]}; fi

temp_dir=$PROJ_GROUP_ANALYSIS_DIR/temp_study_template_longitudinal_$REF_SUBJ
mkdir -p $temp_dir

SUBJ_NAME=$REF_SUBJ
SESS_ID=1
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
REF_T1_BRAIN=$T1_BRAIN_DATA
REF_T1_BRAIN_MASK=$T1_BRAIN_DATA_MASK

s=${REF_T1_BRAIN##*/}
ref_image_name=${s%.txt}


$FSLDIR/bin/imcp $REF_T1_BRAIN $temp_dir/$ref_image_name"_2_"$ref_image_name
# ===============================================================================

# 1)	Use non-linear registration to register each participant to this reference participant
echo 1: registering each participant to reference one

merge_list=$temp_dir/$ref_image_name"_2_"$ref_image_name
for SUBJ_NAME in ${arr_subj[@]}
do
	if [ $REF_SUBJ != $SUBJ_NAME ]; then
		SESS_ID=1; . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
		s=${T1_BRAIN_DATA##*/}
		subj_image_name=${s%.txt}
		merge_list="$merge_list $temp_dir/$subj_image_name"_2_"$ref_image_name"
		
		SESS_ID=2; . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
		s=${T1_BRAIN_DATA##*/}
		subj_image_name=${s%.txt}
		merge_list="$merge_list $temp_dir/$subj_image_name"_2_"$ref_image_name"

	fi
done

SESS_ID=1
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR -odp $temp_dir -ref $REF_T1_BRAIN -refmask $REF_T1_BRAIN_MASK
wait

SESS_ID=2
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR -odp $temp_dir -ref $REF_T1_BRAIN -refmask $REF_T1_BRAIN_MASK
wait


# 2)	Create an average image of all of the transformed images (including the reference participant)
echo 2: creating average1

$FSLDIR/bin/fslmerge -t $temp_dir/template$REF_SUBJ $merge_list
$FSLDIR/bin/fslmaths $temp_dir/template$REF_SUBJ -Tmean $temp_dir/template$REF_SUBJ

#rm $temp_dir/*_2_$REF_SUBJ*

# 3)	Register (non-linear) every participant (including the reference participant) to this average image
echo 3: registering each participant to average1
merge_list=""
for SUBJ_NAME in ${arr_subj[@]}
do
	SESS_ID=1; . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	s=${T1_BRAIN_DATA##*/}
	subj_image_name=${s%.txt}	
	echo registering2 $SUBJ_NAME
	merge_list="$merge_list $temp_dir/$subj_image_name"_2_template$REF_SUBJ
	
	SESS_ID=2; . $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	s=${T1_BRAIN_DATA##*/}
	subj_image_name=${s%.txt}	
	echo registering2 $SUBJ_NAME
	merge_list="$merge_list $temp_dir/$subj_image_name"_2_template$REF_SUBJ

	
done

SESS_ID=1
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR -odp $temp_dir -ref $temp_dir/template$REF_SUBJ -refmask $REF_T1_BRAIN_MASK
wait

SESS_ID=2
. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_subj" $PROJ_DIR -odp $temp_dir -ref $temp_dir/template$REF_SUBJ -refmask $REF_T1_BRAIN_MASK
wait

# 4)	Average all of the transformed images
echo 4: creating final study template
$FSLDIR/bin/fslmerge -t $temp_dir/final_template$REF_SUBJ $merge_list
$FSLDIR/bin/fslmaths $temp_dir/final_template$REF_SUBJ -Tmean $OUTPUT_TEMPLATE_IMAGE

#rm $temp_dir/*_2_template$REF_SUBJ*

[ $CLEAN_INTERMEDIATE -eq 1 ] && rm -rf $temp_dir




