#!/bin/sh

Usage() {
    cat <<EOF

dual_regression v0.5 (beta)

***NOTE*** ORDER OF COMMAND-LINE ARGUMENTS IS DIFFERENT FROM PREVIOUS VERSION

Usage: dual_regression_selectmask_template_rsn_masks <template stats_directory>  <0-based ICs 2 preserve> <label 2 preserve>.........

<template stats_directory>   template stas images
<0-based ICs 2 preserve>	"1 2 4 6 9 12 14"
<IC LABEL 2 preserve>			"DMN,FT,V1,SM,....,"

EOF
    exit 1
}

############################################################################
[ "$3" = "" ] && Usage


TEMPLATE_MELODIC_STATS_DIR=`${FSLDIR}/bin/remove_ext $1` ; shift
OLD_IFS=$IFS; IFS=","; 
declare -a arrICs=( $1 )
declare -a arrICLabels=( $2 )
IFS=$OLD_IFS;

############################################################################
if [ ${#arrICs[@]} -ne ${#arrICLabels[@]} ]
then
	echo "number of IC ID and label do not coincide....exiting"
	exit
fi

if [ ! -d $TEMPLATE_MELODIC_STATS_DIR ]
then
	echo "input TEMPLATE_MELODIC_STATS_DIR ($TEMPLATE_MELODIC_STATS_DIR) does not exist......exiting"
	exit
fi
############################################################################

echo "mask RSN within stats folder"
cnt=0
for comp in ${arrICs[@]}
do
	comp=$(echo $comp + 1 | bc)
	$FSLDIR/bin/fslmaths $TEMPLATE_MELODIC_STATS_DIR/thresh_zstat$comp -thr 2.3 -bin $TEMPLATE_MELODIC_STATS_DIR/mask_${arrICLabels[cnt]}
	cnt=$cnt+1
done

echo "=====================>>>> END splitting ICs"
