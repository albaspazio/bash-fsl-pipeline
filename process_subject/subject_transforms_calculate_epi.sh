#!/bin/bash

Usage()
{
	echo "usage: $0 SUBJ_NAME PROJ_DIR "

	echo "		-stdimg)			alternative standard brain image: e.g. pediatric template"
	echo "		-stdimghead)		alternative standard head image"
	echo "		-stdimgmask)		alternative standard brain mask"
	echo "		-stdimglabel)		alternative standard brain label"
	echo "		-nobbr) 			do not use BBR registration"
	echo "		-wmseg) 			set wmseg image for BBR reg, otherwise calculates it"
	exit
}


if [ -z "$1" ]; then Usage;	fi
# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
# ====== static variables: do not edit !  ============================================================
if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

STD_IMAGE_LABEL=standard
STD_IMAGE=$FSLDIR/data/standard/MNI152_T1_2mm_brain
STD_IMAGE_MASK=$FSLDIR/data/standard/MNI152_T1_2mm_brain_mask_dil
STD_IMAGE_HEAD=$FSLDIR/data/standard/MNI152_T1_2mm


WM_SEG_IMAGE=$T1_SEGMENT_WM_BBR_PATH
DO_BBR=1
while [ ! -z "$1" ]
do
  case "$1" in
  	-stdimg)	
  			STD_IMAGE=$2; 
  			shift;;
  			
  	-stdimghead)	
  			STD_IMAGE_HEAD=$2; 
  			shift;;
  			
  	-stdimgmask)	
  			STD_IMAGE_MASK=$2; 
  			shift;;

  	-stdimglabel)	
  			STD_IMAGE_LABEL=$2; 
  			shift;;
  			  			  			
  	-nobbr)
  			DO_BBR=0;;
  			
  	-wmseg)
  			WM_SEG_IMAGE=$2;
  			shift;;
  esac
  shift;
done
	
main()
{
	mkdir -p $ROI_DIR/reg_epi
	mkdir -p $ROI_DIR/reg_${STD_IMAGE_LABEL}
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	if [ `$FSLDIR/bin/imtest $T1_BRAIN_DATA` = 0 ]; then
		echo "returning"
	 return 0; 
	 
	fi
	if [ ! -d $PROJ_DIR ]; then echo "project dir ($PROJ_DIR) not present....exiting"; exit; fi
	if [ `$FSLDIR/bin/imtest $STD_IMAGE` = 0 ]; then echo "standard image ($STD_IMAGE) not present....exiting"; exit; fi
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	if [ `$FSLDIR/bin/imtest $RS_EXAMPLEFUNC` = 0 ]; then
		$FSLDIR/bin/fslmaths $RS_DATA $ROI_DIR/reg_epi/prefiltered_func_data -odt float
		$FSLDIR/bin/fslroi $ROI_DIR/reg_epi/prefiltered_func_data $RS_EXAMPLEFUNC 100 1
		$FSLDIR/bin/bet2 $RS_EXAMPLEFUNC $RS_EXAMPLEFUNC -f 0.3
		rm $ROI_DIR/reg_epi/prefiltered_func_data*	
	fi
	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# ---- EPI <--> HIGHRES
	if [ $DO_BBR -eq 1 ]; then

		# BBR (taken from $FSLDIR/bin/epi_reg.sh)
		$FSLDIR/bin/flirt -ref $T1_BRAIN_DATA -in $RS_EXAMPLEFUNC -dof 6 -omat $ROI_DIR/reg_t1/epi2highres_init.mat
		
    if [ `$FSLDIR/bin/imtest $T1_SEGMENT_WM_BBR_PATH` = 0 ] ; then
			echo "Running FAST segmentation for subj $SUBJ_NAME"
			mkdir -p $ROI_DIR/reg_t1/temp
			$FSLDIR/bin/fast -o $ROI_DIR/reg_t1/temp/temp $T1_BRAIN_DATA
			$FSLDIR/bin/fslmaths $ROI_DIR/reg_t1/temp/temp_pve_2 -thr 0.5 -bin $T1_SEGMENT_WM_BBR_PATH
			rm -rf $ROI_DIR/reg_t1/temp
    fi		
    
    # => epi2highres.mat
    [ ! -f $ROI_DIR/reg_t1/epi2highres.mat ] && $FSLDIR/bin/flirt -ref $T1_DATA -in $RS_EXAMPLEFUNC -dof 6 -cost bbr -wmseg $T1_SEGMENT_WM_BBR_PATH -init $ROI_DIR/reg_t1/epi2highres_init.mat -omat $ROI_DIR/reg_t1/epi2highres.mat -out $ROI_DIR/reg_t1/epi2highres -schedule ${FSLDIR}/etc/flirtsch/bbr.sch
    # => epi2highres.nii.gz
    [ `$FSLDIR/bin/imtest $ROI_DIR/reg_t1/epi2highres` = 0 ] && $FSLDIR/bin/applywarp -i $RS_EXAMPLEFUNC -r $T1_DATA -o $ROI_DIR/reg_t1/epi2highres --premat=$ROI_DIR/reg_t1/epi2highres.mat --interp=spline	
    rm $ROI_DIR/reg_t1/epi2highres_init.mat
	else
		# NOT BBR
		[ ! -f $ROI_DIR/reg_epi/${STD_IMAGE_LABEL}2epi.mat ] && $FSLDIR/bin/flirt -in $RS_EXAMPLEFUNC -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/epi2highres -omat $ROI_DIR/reg_t1/epi2highres.mat -cost corratio -dof 6 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
	fi
	[ ! -f $ROI_DIR/reg_epi/highres2epi.mat ] && $FSLDIR/bin/convert_xfm -inverse -omat $ROI_DIR/reg_epi/highres2epi.mat $ROI_DIR/reg_t1/epi2highres.mat

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# ---- EPI <--> STANDARD
	

	# => epi2standard.mat (as concat)
	[ ! -f $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard.mat ] && $FSLDIR/bin/convert_xfm -omat $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard.mat -concat $ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard.mat $ROI_DIR/reg_t1/epi2highres.mat
	# => standard2epi.mat
	[ ! -f $ROI_DIR/reg_epi/${STD_IMAGE_LABEL}2epi.mat ] && $FSLDIR/bin/convert_xfm -inverse -omat $ROI_DIR/reg_epi/${STD_IMAGE_LABEL}2epi.mat $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard.mat		
	
	# => $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard.nii.gz
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard` = 0 ] && $FSLDIR/bin/flirt -ref $STD_IMAGE -in $RS_EXAMPLEFUNC -out $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard -applyxfm -init $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard.mat -interp trilinear

	#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	# epi -> highres -> standard
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard_warp` = 0 ] && $FSLDIR/bin/convertwarp --ref=$STD_IMAGE --premat=$ROI_DIR/reg_t1/epi2highres.mat --warp1=$ROI_DIR/reg_${STD_IMAGE_LABEL}/highres2standard_warp --out=$ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard_warp
	# invwarp: standard -> highres -> epi
	[ `$FSLDIR/bin/imtest $ROI_DIR/reg_epi/${STD_IMAGE_LABEL}2epi_warp` = 0 ] && $FSLDIR/bin/invwarp -r $ROI_DIR/reg_epi/example_func -w $ROI_DIR/reg_${STD_IMAGE_LABEL}/epi2standard_warp -o $ROI_DIR/reg_epi/${STD_IMAGE_LABEL}2epi_warp

}

main

