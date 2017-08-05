#!/bin/bash

FINAL_ROI=$1
shift
declare -a ROIS=( "$@" )

num_roi=${#ROIS[@]}
final_dir=$(dirname $FINAL_ROI)
final_name=$(basename $FINAL_ROI)
temp_roi=$final_dir/temp_roi.nii.gz

#echo -------------------------------------------------
#echo "${ROIS[@]}"
#echo num_roi $num_roi
#echo -------------------------------------------------


$FSLDIR/bin/fslmaths ${ROIS[0]} -bin $FINAL_ROI

for (( r=1; r<$num_roi; r++ ))
do
	roi=${ROIS[r]} 
	$FSLDIR/bin/fslmaths $roi -bin $temp_roi 
	$FSLDIR/bin/fslmaths $FINAL_ROI -add $temp_roi $FINAL_ROI
done

$FSLDIR/bin/fslmaths $FINAL_ROI -bin $FINAL_ROI
rm $temp_roi
