#!/bin/bash
echo ---------------------------- $@
# functions used to convert a set of images (string array located at the end of the parameters) )from/to different reference system.
# it accepts images name (default) or fullpath (-absp)
# it perform linear (default) or non-linear (-nlin) registration
. $GLOBAL_SCRIPT_DIR/utility_functions.sh

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

do_linear=1
roi_threshold=0
ref=""
input_path_type=standard 	#	"rel"			: a path relative to SUBJECT_DIR (subjectXX/s1/INPUTPATH)
									 				# "abs"			: a full path (INPUTPATH)
OUTPUT_REPORT_FILE=""
mask_image=""
full_report=0
output_roi_name_suffix=""

while [ ! -z "$1" ]
do
  case "$1" in
		-thresh)					roi_threshold=$2;shift;;

		-nlin)						do_linear=0;;				

		-refrel)					ref=$SUBJECT_DIR/$2;shift;;
		-refabs)					ref=$2;shift;;
 	
		-ipathtype)				input_path_type=$2;shift;;
		
		-transfrel)				transformation=$SUBJECT_DIR/$2; shift;;
		-transfabs)				transformation=$2; shift;;
		
		-maskrel)					mask_image=$SUBJECT_DIR/$2; shift;;
		-maskabs)					mask_image=$2; shift;;
				
		-opath)						output_path=$SUBJECT_DIR/$2; shift;;  # rel by definition
		-ofns)						output_roi_name_suffix=$2; shift;;  

		-orf)							OUTPUT_REPORT_FILE=$2; shift;;

		-fullrep)					full_report=1;;

		*)  break;;
	esac
	shift
done

declare -a ROI=( $@ )

echo ${ROI[@]}
#==============================================================================================================
if [ ! -z $ref ]; then
	if [ `$FSLDIR/bin/imtest $ref` = 0 ]; then echo "ERROR: reference image ($ref) do not exist......exiting"; exit; fi
else
	echo "ERROR: reference image ($ref) was not specified......exiting"; exit; 
fi


if [ ! -z $mask_image ]; then
	if [ `$FSLDIR/bin/imtest $mask_image` = 0 ]; then echo "ERROR: mask image ($mask_image) do not exist......exiting"; exit; fi
fi
mkdir -p $output_path


if [ $full_report -eq 1 -a -z $OUTPUT_REPORT_FILE ]; then
	echo "error in subject_transforms_roi_custom: you asked a full report, but did not specify the report file......exiting"
	exit
fi

declare -i v1=-1
declare -i v1_masked=-1
declare -i v1_thresholded=-1
#==============================================================================================================

for roi in ${ROI[@]};	do

	roi_name=$(basename $roi)		
	output_roi=$output_path/$roi_name$output_roi_name_suffix
	
	echo "converting $roi_name"

	if [ "$input_path_type" = "abs" ]; then
		input_roi=$roi
	elif [ "$input_path_type" == "rel" ]; then
		input_roi=$SUBJECT_DIR/$roi
	fi	
	
	if [ $do_linear -eq 0 ]; then
		$FSLDIR/bin/applywarp -i $input_roi -r $ref -o $output_roi --warp=$transformation
	else
		#echo "$FSLDIR/bin/flirt -in $input_roi -ref $ref -out $output_roi -applyxfm -init $transformation -interp trilinear"
		$FSLDIR/bin/flirt -in $input_roi -ref $ref -out $output_roi -applyxfm -init $transformation -interp trilinear
	fi

	v1=`$FSLDIR/bin/fslstats $output_roi -V | awk '{printf($1)}'`
	vol_str="subj: $SUBJ_NAME, roi: $roi_name ... transformed vol: $v1"

	# mask_image
	if [ ! -z $mask_image ]; then
		$FSLDIR/bin/fslmaths $output_roi -mas $mask_image $output_roi
		v1_masked=`$FSLDIR/bin/fslstats $output_roi -V | awk '{printf($1)}'`		
		vol_str=$vol_str", masked vol: $v1_masked"
	fi

	# threshold image
	if [ $(echo "$roi_threshold > 0" | bc) -gt 0 ]; then
		output_roi_name=$(basename $output_roi)
		output_input_roi=$(dirname $output_roi)
		$FSLDIR/bin/fslmaths $output_roi -thr $roi_threshold -bin $output_input_roi/mask_$output_roi_name
		
		v1_thresholded=`$FSLDIR/bin/fslstats $output_input_roi/mask_$output_roi_name -V | awk '{printf($1)}'`
		vol_str=$vol_str", thresholded vol: $v1_thresholded"
	fi

	if [ $full_report -eq 1 ]; then
		echo "$vol_str" >> $OUTPUT_REPORT_FILE
	elif [ ! -z $OUTPUT_REPORT_FILE ]; then
	
		vol_str="subj: $SUBJ_NAME, roi: $roi_name, "

		if [ $v1 -eq 0 ]; then
			vol_str=$vol_str" transformed roi is empty"
		fi

		if [ $v1_masked -eq 0 ]; then
			vol_str=$vol_str" masked roi is empty"
		fi	
		
		if [ $v1_thresholded -eq 0 ]; then
			vol_str=$vol_str" thresholded roi is empty"
		fi			
		echo "$vol_str" >> $OUTPUT_REPORT_FILE
	fi
		
done # for roi

echo "=====================> finished processing $0"

# =================================================================================================================
# CHANGES LOG
# =================================================================================================================

# 18/5/2017 added -ofns to may add a string to output rois' name
