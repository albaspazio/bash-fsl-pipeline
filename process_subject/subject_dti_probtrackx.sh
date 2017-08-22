#!/bin/bash

usage_string="ERROR: usage=> $0 SUBJ_LABEL PROJ_DIR -i input_merged_dir_name -o output_dir_name -m mask_file_path -e seed_file_name -s stop_file_name -t target_text_file <waypoint file name>"


# ===== check parameters ==============================================================================
if [ -z $1 ]; then
  echo $usage_string
  exit
fi
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/utility_functions.sh
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

thrPvalue=0
wp_rel=0

while [ ! -z "$1" ]
do
  case "$1" in
      -idn) INPUT_MERGED_DIR=$2;shift;;
      -odn) OUTPUT_DIR_NAME=$2;shift;;
			-mask)	MASK_IMAGE=$ROI_DIR/$2;shift;;		
			-maskp)	MASK_IMAGE=$2;shift;;		
			-seed)	SEED_NAME=$ROI_DIR/$2;shift;;
			-seedp)	SEED_NAME=$2;shift;;
			-stop)	STOP_FILE=$ROI_DIR/$2;shift;;
			-stopp)	STOP_FILE=$2;shift;;
			-target)	TARGET_FILE=$2;shift;target_rel=1;;			    
			-targetp)	TARGET_FILE=$2;shift;;
			-wp)	wp_rel=1;;
      -thrP) thrPvalue=$2;shift;;
      *) break;;
  esac
  shift
done

declare -a WP_FILES=( "$@" )

# ==================================================================================
#main ()
#{

if [ ! -d $DTI_DIR/$INPUT_MERGED_DIR ]; then run echo "$SUBJ_NAME: INPUT_MERGED_DIR ($DTI_DIR/$INPUT_MERGED_DIR) is absent"; return; fi
if [[ $MASK_IMAGE = $ROI_DIR/"mask" ]]; then MASK_IMAGE=$DTI_DIR/nodif_brain_mask.nii.gz; fi
if [ ! -f $MASK_IMAGE ]; then run echo "error: mask file ($MASK_IMAGE) of subj $SUBJ_NAME do not exist......exiting"; return; fi
if [ ! -f $SEED_NAME.nii.gz ]; then run echo "error: seed file ($SEED_NAME.nii.gz) of subj $SUBJ_NAME do not exist......exiting"; return; fi
if [ ! -f $STOP_FILE.nii.gz ]; then run echo "error: you specified an incorrect STOP file ($STOP_FILE.nii.gz) of subj $SUBJ_NAME......exiting"; return; fi
if [ ! -f $TARGET_FILE ]; then run echo "error: you specified an incorrect TARGET file ($TARGET_FILE) of subj $SUBJ_NAME......exiting"; return; fi


run mkdir -p $PROBTRACKX_DIR/$OUTPUT_DIR_NAME

param_string="--mode=seedmask -x $SEED_NAME -l -c 0.2 -S 2000 --steplength=0.5 -P 5000 --forcedir --opd --pd -s $DTI_DIR/$INPUT_MERGED_DIR/merged -m $MASK_IMAGE --dir=$PROBTRACKX_DIR/$OUTPUT_DIR_NAME"

if [ ! -z $STOP_FILE ]; then param_string="$param_string --stop=$STOP_FILE"; fi
if [ ! -z $TARGET_FILE ]; then
	if [ $target_rel -eq 1 ]; then
		TARGET_LIST_FILE=$ROI_DIR/target_file_$OUTPUT_DIR_NAME.txt
		for target in $(`echo cat $TARGET_FILE`)
		do
			if [ ! -f $ROI_DIR/$target.nii.gz ]; then 
				echo "error: the target mask $target do not exist.....exiting"; rm $PROBTRACKX_DIR/$OUTPUT_DIR_NAME; return; 
			else
				echo "$ROI_DIR/$target.nii.gz" >> $TARGET_LIST_FILE
			fi
		done
		param_string="$param_string --targetmasks=$TARGET_LIST_FILE"
	else
		param_string="$param_string --targetmasks=$TARGET_FILE"
	fi
fi


if [ ${#WP_FILES[@]} -gt 0 ]; then
	out_wpfiles=$PROBTRACKX_DIR/$OUTPUT_DIR_NAME/waypoints.txt
	[ -f $out_wpfiles ] && rm $out_wpfiles
	for wp in ${WP_FILES[@]}
	do
		if [ $wp_rel -eq 1 ]; then
			if [ ! -f $ROI_DIR/$wp.nii.gz ]; then echo "error: one of your waypoint file ($ROI_DIR/$wp.nii.gz) of subj $SUBJ_NAME do not exist......exiting"; rm -rf $PROBTRACKX_DIR/$OUTPUT_DIR_NAME; return; fi
			echo "$ROI_DIR/$wp.nii.gz" >> $out_wpfiles
		else
			if [ ! -f $wp.nii.gz ]; then echo "error: one of your waypoint file ($wp.nii.gz) of subj $SUBJ_NAME do not exist......exiting"; rm -rf $PROBTRACKX_DIR/$OUTPUT_DIR_NAME; return; fi
			echo "$wp.nii.gz" >> $out_wpfiles
		fi
	done
	param_string="$param_string --waypoints=$out_wpfiles"	
fi
# ==================================================================================

run echo "$SUBJ_NAME: probtrackx to $OUTPUT_DIR_NAME " #with : $param_string "
run $FSLDIR/bin/probtrackx $param_string

if [ ! -z $TARGET_FILE ]; then run $FSLDIR/bin/find_the_biggest $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/seeds_to* $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/biggest; fi


# normalize fdt_paths
w=$(cat $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/waytotal | tr -d ' ')  # read value and remove space chars
if [ $w -eq 0 ]; then run echo "$SUBJ_NAME: Error in probtracks, waypoint=0"
else	run $FSLDIR/bin/fslmaths $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/fdt_paths.nii.gz -div $w $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/fdt_paths_norm.nii.gz; 
fi

# threshold fdt_paths_norm
if [ -f $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/fdt_paths_norm.nii.gz ]; then

	declare -i nvox=-1; nvox=`fslstats $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/fdt_paths_norm.nii.gz -V | awk '{ print $1}'`
	if [ $nvox -eq 0 ]; then echo "$SUBJ_NAME: ERROR...fdt_paths_norm  of $SUBJ_NAME is empty"; fi 

	OLD_IFS=$IFS; IFS=","; 
	declare -a arr_thrp=( $thrPvalue )
	IFS=$OLD_IFS
	declare -a arr_files=()
	declare -i cnt=0

	for pvalue in ${arr_thrp[@]}
	do 
		 arr_files[cnt]="mask_"$OUTPUT_DIR_NAME"_P$pvalue.nii.gz"
		 cnt=$cnt+1
	done

	cnt=0
	if [ ${#arr_thrp[@]} -gt 0 ]; then 
		for pvalue in ${arr_thrp[@]}
		do
			run $FSLDIR/bin/fslmaths $PROBTRACKX_DIR/$OUTPUT_DIR_NAME/fdt_paths_norm.nii.gz -thrP $pvalue $ROI_DIR/reg_dti/${arr_files[cnt]}
			cnt=$cnt+1
		done
	fi
fi


echo "finished probtrackx for $SUBJ_NAME in $OUTPUT_DIR_NAME"
#}
#main 








