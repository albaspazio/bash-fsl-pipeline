#!/bin/sh

#   do fast (if absent) or expect fast to be in $FAST_DIR.
#   calculate smoothing, 
#   do featregapply if necessary
#   register each smoothed gm images to standard2mm, subject epi space and standard4mm (if provided 2 the script)
#   ---> find warp files from FEAT directories and apply to GM
#   prepare GM-density-based higher-level FEAT confound regressor (concatenate -> 4D -> demean)

Usage() {
    echo "Usage: feat_gm_prepare <PROJ_DIR> -o <4D-GM-output> -s standard4mm  <list of first-level FEAT output directories>"
    echo "Note: these all have to have had registration completed in them"
    exit 1
}

STANDARD_4mm=""

PROJ_DIR=$1; shift
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR



while [ ! -z "$1" ]
do
  case "$1" in
		-ofp)	OUTPUT_GM=`${FSLDIR}/bin/remove_ext $2`;shift;;
		-std4img)	STANDARD_4mm=$2;shift
				if [ ! -f $STANDARD_4mm ]; then echo "standard4mm image file ($STANDARD_4mm) is missing....exiting"; exit; fi;;
		*)  break;;
	esac
	shift
done


echo Estimating how much we will need to smooth the structurals by...
func_smoothing=`grep "fmri(smooth)" $1/design.fsf | tail -n 1 | awk '{print $3}'`
standard_space_resolution=`${FSLDIR}/bin/fslval $1/reg/standard pixdim1`
struc_smoothing=`${FSLDIR}/bin/match_smoothing $1/example_func $func_smoothing $1/reg/highres $standard_space_resolution`

echo Structural-space GM PVE images will be smoothed by sigma=${struc_smoothing}mm to match the standard-space functional data

for f in "$@" ; do
	#extract SUBJ_NAME from FEAT folder
	base_dir=$(basename $f)
	SUBJ_NAME=${base_dir%-*}
	echo "processing $SUBJ_NAME"

	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	
	mkdir -p $ROI_DIR/reg_standard
	mkdir -p $ROI_DIR/reg_standard4
	mkdir -p $ROI_DIR/reg_epi	
	
	if [ ! -f $FAST_DIR/${T1_IMAGE_LABEL}_brain_pve_1.nii.gz ]; then
		echo "doing FAST over $SUBJ_NAME"
		$FSLDIR/bin/fast -t 1 -n 3 -g -o $FAST_DIR/$T1_IMAGE_LABEL"_brain" $T1_BRAIN_DATA
	fi

	reg_dir=$f/reg
	standard_reg_dir=$f/reg_standard
	
	if [ ! -d $standard_reg_dir ]; then 
		echo "doing featregapply over $f"
		$FSLDIR/bin/featregapply $f
	fi
	
	smoothed_img_name_t1=$ROI_DIR/reg_t1/t1_sgm.nii.gz
	smoothed_img_name_epi=$ROI_DIR/reg_epi/t1_sgm_epi.nii.gz
	smoothed_img_name_std=$ROI_DIR/reg_standasrd/t1_sgm_standard.nii.gz
	smoothed_img_name_std4=$ROI_DIR/reg_standard4/t1_sgm_standard4.nii.gz
	
	[ ! -f $smoothed_img_name_t1 ] && $FSLDIR/bin/fslmaths $FAST_DIR/${T1_IMAGE_LABEL}_brain_pve_1.nii.gz -s $struc_smoothing $smoothed_img_name_t1

	if [ ! -f $smoothed_img_name_std ]; then
		if [ -f $reg_dir/highres2standard_warp.nii.gz ] ; then
  	  ${FSLDIR}/bin/applywarp --ref=$reg_dir/standard --in=$smoothed_img_name_t1 --out=$smoothed_img_name_std --warp=$reg_dir/highres2standard_warp
		else
  	  ${FSLDIR}/bin/flirt -in $smoothed_img_name_t1 -out $smoothed_img_name_std -ref $reg_dir/standard -applyxfm -init $reg_dir/highres2standard.mat
		fi 
	fi
	GMlist_std2="$GMlist_std2 $smoothed_img_name_std"	
	
	if [ ! -f $smoothed_img_name_std4 -a -f $STANDARD_4mm ]; then
		$FSLDIR/bin/flirt -in $smoothed_img_name_std -out $smoothed_img_name_std4 -ref $STANDARD_4mm -omat $ROI_DIR/reg_standard4/standard2standard4.mat
		GMlist_std4="$GMlist_std4 $FAST_DIR/reg_standard4/$smoothed_img_name"
	fi
	
	[ ! -f $smoothed_img_name_epi ] && ${FSLDIR}/bin/flirt -in $smoothed_img_name_std -out $smoothed_img_name_epi -ref $reg_dir/example_func -applyxfm -init $reg_dir/standard2example_func.mat
		
done

. $GLOBAL_GROUP_SCRIPT_DIR/feat_gm_merge_smooth.sh $OUTPUT_GM "$GMlist_std2" "$GMlist_std4"

