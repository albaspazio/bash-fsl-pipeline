#!/bin/sh

Usage() {
    cat <<EOF

dual_regression v0.5 (beta)

***NOTE*** ORDER OF COMMAND-LINE ARGUMENTS IS DIFFERENT FROM PREVIOUS VERSION

Usage: dual_regression_select <group_IC_maps> <dualregr_directory> <output root directory> <num subjects> <0-based ICs 2 preserve> <label 2 preserve>.........

<group_IC_maps_4D>      	4D image containing spatial IC maps (melodic_IC) from the whole-group ICA analysis
<dualregr_directory>    	contains input original stage_2 files
<out root directory>			will contains single IC folders (with pruned stage_2 files)
<0-based ICs 2 preserve>	"1 2 4 6 9 12 14"
<IC LABEL 2 preserve>			"DMN,FT,V1,SM,....,"

EOF
    exit 1
}

############################################################################
[ "$3" = "" ] && Usage

ORIG_COMMAND=$*

ICA_MAPS=`${FSLDIR}/bin/remove_ext $1` ; shift
DR_DIR=`${FSLDIR}/bin/remove_ext $1` ; shift
OUT_ROOT_DIR=`${FSLDIR}/bin/remove_ext $1` ; shift
OLD_IFS=$IFS; IFS=","; 
declare -a arrICs=( $1 )
declare -a arrICLabels=( $2 )
IFS=$OLD_IFS;


TEMPLATE_MELODIC_DIR=$(dirname ${ICA_MAPS})
############################################################################
if [ ${#arrICs[@]} -ne ${#arrICLabels[@]} ]
then
	echo "number of IC IDs (${arrICs[@]}) and labels (${arrICLabels[@]}) do not coincide....exiting"
	exit
fi

if [ ! -d $DR_DIR ]
then
	echo "input DR dir does not exist......exiting"
	exit
fi

if [ ! -e $ICA_MAPS.nii.gz ]
then
	echo "input ICA MAPS ($ICA_MAPS) does not exist......exiting"
	exit
fi
############################################################################
if [ ! -d $OUT_ROOT_DIR ]; then
  mkdir -p $OUT_ROOT_DIR
fi

cd $OUT_ROOT_DIR

echo "pruning melodic_IC maps, preserving components: ${arrICs[@]}"

$FSLDIR/bin/fslsplit $ICA_MAPS melodic_temp_pruned_IC

declare -i cnt=0
for comp in ${arrICs[@]}
do
  cmp=`$FSLDIR/bin/zeropad $comp 4`
  mkdir $OUT_ROOT_DIR/${arrICLabels[cnt]}
  mv melodic_temp_pruned_IC$cmp.nii.gz $OUT_ROOT_DIR/${arrICLabels[cnt]}/melodic_IC.nii.gz
  cp $DR_DIR/mask.nii.gz $OUT_ROOT_DIR/${arrICLabels[cnt]}/mask.nii.gz
  cnt=$cnt+1
done
rm *melodic_temp_pruned*

echo "copying and renaming preserved components: dr_stage2_ic000xx"
cnt=0
for comp in ${arrICs[@]}
do
	cmp=`$FSLDIR/bin/zeropad $comp 4`
	cp dr_stage2_ic$cmp.nii.gz $OUT_ROOT_DIR/${arrICLabels[cnt]}/dr_stage2_ic0000.nii.gz
	cnt=$cnt+1
done


echo "mask RSN within stats folder"
cnt=0
for comp in ${arrICs[@]}
do
	comp=$(echo $comp + 1 | bc)
	$FSLDIR/bin/fslmaths $TEMPLATE_MELODIC_DIR/stats/thresh_zstat$comp -thr 2.3 -bin $TEMPLATE_MELODIC_DIR/stats/mask_${arrICLabels[cnt]}
	cnt=$cnt+1
done

echo "=====================>>>> END splitting ICs"
