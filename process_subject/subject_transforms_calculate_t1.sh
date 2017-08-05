#!/bin/bash

if [ $# -lt 2 ]
then
	echo "usage: reg_nonlin_t1_standard subj_name proj_dir std_image :  $@"
	exit
fi

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
				
STD_IMAGE_LABEL=standard
STD_IMAGE=$FSLDIR/data/standard/MNI152_T1_2mm_brain
STD_IMAGE_MASK=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil

while [ ! -z "$1" ]
do
  case "$1" in
  	-stdimg)	
  			STD_IMAGE=$2; 
  			shift;;
  			
#  	-stdimghead)	
#  			STD_IMAGE_HEAD=$2; 
#  			shift;;
#  			
  	-stdimgmask)	
  			STD_IMAGE_MASK=$2; 
  			shift;;

  	-stdimglabel)	
  			STD_IMAGE_LABEL=$2; 
  			shift;;
  esac
  shift;
done


main()
{
	if [ `$FSLDIR/bin/imtest $STD_IMAGE` = 0 ]; then
		echo "file STD_IMAGE: $STD_IMAGE.nii.gz is not present...skipping reg_nonlin_epi_t1_standard.sh"
		return 0; 
	fi

	if [ `$FSLDIR/bin/imtest $STD_IMAGE_MASK` = 0 ]; then
		echo "file STD_IMAGE_MASK: $STD_IMAGE_MASK.nii.gz is not present...skipping reg_nonlin_epi_t1_standard.sh"
		return 0; 
	fi

	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	if [ `$FSLDIR/bin/imtest $T1_BRAIN_DATA` = 0 ]; then
		echo "file T1_BRAIN_DATA: $T1_BRAIN_DATA.nii.gz is not present...skipping reg_nonlin_epi_t1_standard.sh"
		return 0; 
	fi
	
	if [ `$FSLDIR/bin/imtest $STD_IMAGE` = 0 ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	echo "$SUBJ_NAME:						STARTED : nonlin t1-standard coregistration"

		# highres <--> standard
	mkdir -p $ROI_DIR/reg_${STD_IMAGE_LABEL}
	mkdir -p $ROI_DIR/reg_${STD_IMAGE_LABEL}4
	mkdir -p $ROI_DIR/reg_t1


	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# ---- HIGHRES <--------> STANDARD
	# => highres2standard.mat
	[ ! -f $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard.mat ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA -ref $STD_IMAGE -out $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard -omat $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
	# => standard2highres.mat
	[ ! -f $ROI_DIR/reg_t1/${STD_IMAGE_LABEL}2highres.mat ] && $FSLDIR/bin/convert_xfm -inverse -omat $ROI_DIR/reg_t1/${STD_IMAGE_LABEL}2highres.mat $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard.mat	

	# NON LINEAR
	# => highres2standard_warp
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard_warp` = 0 ] && $FSLDIR/bin/fnirt --in=$T1_BRAIN_DATA --aff=$ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard.mat --cout=$ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard_warp --iout=$ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard --jout=$ROI_DIR/reg_t1/highres2highres_jac --config=T1_2_MNI152_2mm --ref=$STD_IMAGE --refmask=$STD_IMAGE_MASK --warpres=10,10,10
	
	# => standard2highres_warp
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_t1/${STD_IMAGE_LABEL}2highres_warp` = 0 ] && $FSLDIR/bin/invwarp -r $T1_BRAIN_DATA -w $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard_warp -o $ROI_DIR/reg_t1/${STD_IMAGE_LABEL}2highres_warp
	
##	# => highres2${STD_IMAGE_LABEL}.nii.gz
##	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard` = 0 ] && $FSLDIR/bin/applywarp -i $T1_BRAIN_DATA -r $STD_IMAGE -o $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard -w $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard_warp
	
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
	# highres <--> standard4
	mkdir -p $ROI_DIR/reg_${STD_IMAGE_LABEL}4

	highres2standard4_mat=$ROI_DIR/reg_${STD_IMAGE_LABEL}4/highres2standard.mat
	standard42highres_mat=$ROI_DIR/reg_t1/${STD_IMAGE_LABEL}42highres.mat
	hr2std4_warp=$ROI_DIR/reg_${STD_IMAGE_LABEL}4/highres2standard_warp.nii.gz
	std42hr_warp=$ROI_DIR/reg_t1/${STD_IMAGE_LABEL}42highres_warp.nii.gz

	[ ! -f $highres2standard4_mat ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA.nii.gz -ref $FSL_STANDARD_MNI_4mm -omat $highres2standard4_mat 
	[ ! -f $standard42highres_mat ] && $FSLDIR/bin/convert_xfm -omat $standard42highres_mat -inverse $highres2standard4_mat 

#	[ ! -f $hr2std4_warp ] && $FSLDIR/bin/fnirt --in=$T1_DATA --aff=$highres2standard4_mat --cout=$hr2std4_warp --iout=$ROI_DIR/reg_standard4/highres2standard --jout=$ROI_DIR/reg_standard4/highres2standard_jac --config=$GLOBAL_DATA_TEMPLATES/gray_matter/T1_2_MNI152_4mm --ref=$FSL_STANDARD_MNI_4mm --refmask=$GLOBAL_DATA_TEMPLATES/gray_matter/MNI152_T1_4mm_brain_mask_dil --warpres=10,10,10
#	[ ! -f $std42hr_warp ] && $FSLDIR/bin/invwarp -w $hr2std4_warp -o $std42hr_warp -r $T1_BRAIN_DATA
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	

	echo "$SUBJ_NAME:						TERMINATED : nonlin t1-standard coregistration"
}

main	
