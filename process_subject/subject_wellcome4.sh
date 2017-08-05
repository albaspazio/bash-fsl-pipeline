#!/bin/bash

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

Usage()
{
echo "usage: $0 SUBJ_LABEL PROJ_DIR -sienax \"-B -f 0.3\" -firststructs L_Thal,R_Thal -mel resting -dtifit -sbfcpre -bedx bedpostx"

echo "		-sienax)				bet param string e.g. \"-B -f 0.3\""
echo "		-firststructs) 	structs_list"
echo "		-firstodn) 			output dir name"
echo "		-firstreg2odn)	output dir name"
echo "		-mel)						output dir name"
echo "		-bedx)					output dir name"
echo "		-dtifit)"
echo "		-sbfcpre)"			
exit
}


if [ -z "$1" ]; then Usage;	fi
#if [[ "$1" = "-h" -o "$1" = "--help" ]]; then Usage;	fi
# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift
# ====== static variables: do not edit !  ============================================================
if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

HAS_T2=0
# ==================================================================================
# PROCESSING
# ==================================================================================
BET_PARAM_STRING="-SNB -f 0.2"
BET_F_VALUE_T2="0.5"
MELODIC_MODEL=$PROJ_SCRIPT_DIR/glm/templates/singlesubj_melodic4
MELODIC_OUTPUT_DIR=resting

DO_SKIP_SIENAX=0
DO_SIENAX=0
DO_FIRST=0
DO_MELODIC=0
DO_DTIFIT=0
DO_BEDPOST=0
DO_BEDPOST_CUDA=0
DO_NUISANCE=0
DO_FREESURFER_RECON=0
DO_AUTOPTX_TRACT=0

while [ ! -z "$1" ]
do
  case "$1" in
		-sienax)	DO_SIENAX=1
				BET_PARAM_STRING="-B -f 0.20" #"$2"
				shift;;
		-nosienax)	DO_SKIP_SIENAX=1;;		
		-firststructs) DO_FIRST=1
				FIRST_STRUCTURES="-structs $2"
				shift;;
		-firstodn) DO_FIRST=1
				FIRST_OUTPUT_DIR_NAME="-odn $2"
				shift;;				
		-freesurfer)		DO_FREESURFER_RECON=1; shift;;	

						
		-mel)	DO_MELODIC=1;;
		-melodn)	DO_MELODIC=1
	  		MELODIC_OUTPUT_DIR=$2
				shift;;				
		-melmodel)	DO_MELODIC=1
	  		MELODIC_MODEL=$2
				shift;;	
		-sbfcpre)	DO_NUISANCE=1;;			

				
		-bedx)	DO_BEDPOST=1
				BEDPOST_OUTDIR_NAME=$2
				shift;;
		-bedx_cuda)	DO_BEDPOST_CUDA=1
				BEDPOST_OUTDIR_NAME=$2
				shift;;				
		-dtifit)	DO_DTIFIT=1;;			
		
		*)  break;;
	esac
	shift
done

# ---- T1 data ---------------------------------------------------------
if [ -d "$T1_DIR" ]; then
	mkdir -p $ROI_DIR/reg_t1
	mkdir -p $ROI_DIR/reg_standard
	mkdir -p $FAST_DIR

	if [ $DO_SKIP_SIENAX -eq 0 ]; then	
		really_do_sienax=0
		if [  $DO_SIENAX -eq 1 -a ! -f $SIENAX_DIR/I_vent_render.nii.gz ]; then really_do_sienax=1; fi
		if [ `$FSLDIR/bin/imtest $T1_BRAIN_DATA` = 0 -o `$FSLDIR/bin/imtest $FAST_DIR/$T1_IMAGE_LABEL"_brain_mixeltype"` = 0 ]; then really_do_sienax=1; fi  
		
		if [  $really_do_sienax -eq 1 ]; then
		  # SIENAX + FAST + BET
		  echo "===========>>>> $SUBJ_NAME: sienax with $BET_PARAM_STRING"
	 	 	$FSLDIR/bin/sienax $T1_DATA -B "$BET_PARAM_STRING" -d -r
			rm $SIENAX_DIR/I.ni*
			mv $SIENAX_DIR/I_brain.nii.gz $T1_BRAIN_DATA.nii.gz
			mv $SIENAX_DIR/I_brain_mask.nii.gz $T1_BRAIN_DATA"_mask".nii.gz

			mv $SIENAX_DIR/I_stdmaskbrain* $FAST_DIR
			for img in $FAST_DIR/*
			do
				new_name=${img/I_stdmaskbrain/$T1_IMAGE_LABEL"_brain"} 
				mv $img $new_name
			done
		fi
	fi
	# ---------  COPY SEGMENTATION TO ROI_DIR/reg_t1 ---------------------------------------
	run_notexisting_img $T1_SEGMENT_GM_PATH  cp $T1_SEGMENT_GM_PATH.nii.gz $ROI_DIR/reg_t1/mask_t1_gm.nii.gz
	run_notexisting_img $T1_SEGMENT_WM_PATH  cp $T1_SEGMENT_WM_PATH.nii.gz $ROI_DIR/reg_t1/mask_t1_wm.nii.gz
	run_notexisting_img $T1_SEGMENT_CSF_PATH cp $T1_SEGMENT_CSF_PATH.nii.gz $ROI_DIR/reg_t1/mask_t1_csf.nii.gz

  if [ $DO_FIRST -eq 1 ]; then
  	if [ `$FSLDIR/bin/imtest $FIRST_DIR/$T1_IMAGE_LABEL"_"all_none_origsegs` = 0 -a `$FSLDIR/bin/imtest $FIRST_DIR/$T1_IMAGE_LABEL"_"all_fast_origsegs` = 0 ]
  	then
  		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_first.sh $SUBJ_NAME $PROJ_DIR $FIRST_STRUCTURES $FIRST_OUTPUT_DIR_NAME
 		fi
 	fi
	. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_t1.sh $SUBJ_NAME $PROJ_DIR
	
 	if [ $DO_FREESURFER_RECON -eq 1 ]; then
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_freesurfer_reconall.sh $SUBJ_NAME $PROJ_DIR
 	fi	
fi

# ---- WB data ---------------------------------------------------------
if [ -d "$WB_DIR" ]; then
  if [ `$FSLDIR/bin/imtest $WB_DATA` = 1 ]; then
  	if [ `$FSLDIR/bin/imtest $WB_BRAIN_DATA` = 0 ]; then
  		echo "===========>>>> $SUBJ_NAME: bet on WB"
  		$FSLDIR/bin/bet $WB_DATA $WB_BRAIN_DATA -f $BET_F_VALUE_T2 -g 0 -m
  	fi
  fi
fi

# ---- RS data ---------------------------------------------------------
if [ -d "$RS_DIR" ]; then
	mkdir -p $ROI_DIR/reg_epi
  if [ `$FSLDIR/bin/imtest $RS_DATA` = 0 ];  then
		echo "===========>>>> rs image $RS_DATA.nii.gz is missing...continuing"	  
	else
	
		mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/dr
		mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/group_templates
		
		if [ ! -d $RS_DIR/$RS_IMAGE_LABEL.ica -a $DO_MELODIC -eq 1 ]; then
			if [ ! -f $MELODIC_MODEL.fsf ]; 
			then 
				echo "===========>>>> melodic template file ($SUBJ_NAME $PROJ_DIR $MELODIC_MODEL.fsf) is missing...skipping 1st level melodic"
			else
				[ ! -d $RS_DIR/$MELODIC_MELODIC_OUTPUT_DIR.ica ] && . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_feat.sh $SUBJ_NAME $PROJ_DIR -model $MELODIC_MODEL -odn $MELODIC_OUTPUT_DIR
			fi
		fi
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_epi.sh $SUBJ_NAME $PROJ_DIR
				
		# do resting data nuisance removal		
		if [ $DO_NUISANCE -eq 1 ]; then
			. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_resting_nuisance.sh $SUBJ_NAME $PROJ_DIR
		fi		
  fi
fi

# ---- T2 data ---------------------------------------------------------
if [ -d "$DE_DIR" ]; then
  if [ `$FSLDIR/bin/imtest $T2_DATA` = 1 ]; then
  	HAS_T2=1
		mkdir -p $ROI_DIR/reg_t2
  	if [ `$FSLDIR/bin/imtest $T2_BRAIN_DATA` = 0 ]; then
  		echo "$SUBJ_NAME: bet on t2"
  		$FSLDIR/bin/bet $T2_DATA $T2_BRAIN_DATA -f $BET_F_VALUE_T2 -g 0.2 -m
  	fi
  fi
fi

# ---- DTI data ---------------------------------------------------------
if [ -d "$DTI_DIR" ]; then
  if [ "$(ls -A $DTI_DIR)" ]; then
  	if [ `$FSLDIR/bin/imtest $DTI_DIR/$DTI_FIT_LABEL"_FA"` = 0 -a $DO_DTIFIT -eq 1 ]; then
			echo "===========>>>> $SUBJ_NAME: dtifit"  	
			.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_ec_fit.sh $SUBJ_NAME $PROJ_DIR
  		$FSLDIR/bin/fslmaths $DTI_DIR/$DTI_FIT_LABEL"_L2" -add $DTI_DIR/$DTI_FIT_LABEL"_L3" -div 2 $DTI_DIR/$DTI_FIT_LABEL"_L23"
  		.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_preproc.sh $SUBJ_NAME $PROJ_DIR
  	fi
  	mkdir -p $ROI_DIR/reg_dti

  	if [ $HAS_T2 -eq 1 ]; then
  	 	.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti_t2.sh $SUBJ_NAME $PROJ_DIR;
  	else							  				
  		.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti.sh $SUBJ_NAME $PROJ_DIR; 	 
  	fi
  	
  	if [ `$FSLDIR/bin/imtest $DTI_DIR/$BEDPOST_OUTDIR_NAME/mean_S0samples` = 0 ]; then
			[ -f $DTI_DIR/$DTI_ROTATED_BVEC.gz ] && gunzip $DTI_DIR/$DTI_ROTATED_BVEC.gz
      [ -f $DTI_DIR/$DTI_BVAL.gz ] && gunzip $DTI_DIR/$DTI_BVAL.gz
      
      if [ $DO_BEDPOST -eq 1 ]; then 
		  	. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_bedpostx.sh $SUBJ_NAME $PROJ_DIR $BEDPOST_OUTDIR_NAME
		  fi

      if [ $DO_BEDPOST_CUDA -eq 1 ]; then 
		  	. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_bedpostx_CUDA.sh $SUBJ_NAME $PROJ_DIR $BEDPOST_OUTDIR_NAME
		  fi
		fi

		if [ $DO_AUTOPTX_TRACT -eq 1 ]; then
			if [ ! -f $DTI_DIR/$BEDPOST_OUTDIR_NAME/mean_S0samples.nii.gz ]; then
				echo "subj $SUBJ_NAME ,you requested the autoPtx tractorgraphy, but bedpostx was not performed.....skipping"
			else
				. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_tractography.sh $SUBJ_NAME $PROJ_DIR
			fi
		fi  
  fi
fi
# -------------------------------------------------------------



