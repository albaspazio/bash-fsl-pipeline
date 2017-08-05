#!/bin/bash

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
echo "		-fsl5)"
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
MELODIC_MODEL=$PROJ_SCRIPT_DIR/glm/templates/singlesubj_melodic
MELODIC_OUTPUT_DIR=resting
MELODIC_DO_INIT_REG=0
FEAT_PREPROC_MODEL=$PROJ_SCRIPT_DIR/glm/templates/singlesubj_feat_preproc
FEAT_PREPROC_OUTPUT_DIR_NAME=resting

DO_SKIP_ANAT_PROC=0
	  		
DO_SIENAX=0
DO_FIRST=0
DO_MELODIC=0
DO_FEAT_PREPROC=0
DO_ICA_AROMA=0
DO_DTIFIT=0
DO_AUTOPTX_TRACT=0
DO_BEDPOST=0
DO_BEDPOST_CUDA=0
DO_NUISANCE=0
DO_FSL5=0
DO_BIAS_TYPE=2	# 0: no bias, 1: weak bias, 2:full bias

while [ ! -z "$1" ]
do
  case "$1" in
  	-noanat)							DO_SKIP_ANAT_PROC=1;;	
		-nobias)							DO_BIAS_TYPE=0;;
		-weakbias)						DO_BIAS_TYPE=1;;
	  	
		-sienax)							DO_SIENAX=1
													BET_PARAM_STRING="-B -f 0.20"; shift;;
		-firststructs) 				DO_FIRST=1
													FIRST_STRUCTURES="-structs $2"; shift;;
		-firstodn) 						DO_FIRST=1
													FIRST_OUTPUT_DIR_NAME="-odn $2"; shift;;				
		-firstlreg2odn) 			DO_FIRST=1
													FIRST_OUTPUT_REG_DIR_NAME="-lregodn $2"; shift;;
		-firstnlreg2odn) 			DO_FIRST=1
													FIRST_OUTPUT_REG_DIR_NAME="-nlregodn $2"; shift;;
				
		-mel)									DO_MELODIC=1;;
		-melodn)							DO_MELODIC=1
	  											MELODIC_OUTPUT_DIR=$2; shift;;				
		-melmodel)						DO_MELODIC=1
	  											MELODIC_MODEL=$2; shift;;	
		-melinitreg) 					MELODIC_DO_INIT_REG=$2; shift;;	

		-feat_preproc) 				DO_FEAT_PREPROC=1;;
		-feat_preproc_odn)		DO_FEAT_PREPROC=1;
													FEAT_PREPROC_OUTPUT_DIR_NAME=$2; shift;;		
		-feat_preproc_model)	DO_FEAT_PREPROC=1
	  											FEAT_PREPROC_MODEL=$2; shift;;	
		-featinitreg) 				FEAT_PREPROC_DO_INIT_REG=$2; shift;;
		-ica_aroma) 					DO_ICA_AROMA=1;;

		-sbfcpre)							DO_NUISANCE=1;;			
		
		-bedx)								DO_BEDPOST=1
													BEDPOST_OUTDIR_NAME=$2; shift;;
		-bedx_cuda)						DO_BEDPOST_CUDA=1
													BEDPOST_OUTDIR_NAME=$2; shift;;				
		-dtifit)							DO_DTIFIT=1;;			
		-autoptx_tract)				DO_AUTOPTX_TRACT=1;;			
		
		-fsl5)								DO_FSL5=1;;			
		*)  break;;
	esac
	shift
done

fsl_anat_elem=""
if [ $DO_FIRST -eq 0 ]; then		fsl_anat_elem=`echo "$fsl_anat_elem --nosubcortseg"`;fi

if [ $DO_BIAS_TYPE -eq 0 ]; then fsl_anat_elem=`echo "$fsl_anat_elem --nobias"`; 			  
elif [ $DO_BIAS_TYPE -eq 1 ]; then fsl_anat_elem=`echo "$fsl_anat_elem --weakbias"`;
fi

# ---- T1 data ---------------------------------------------------------
if [ -d "$T1_DIR" ]; then
	mkdir -p $ROI_DIR/reg_t1
	mkdir -p $ROI_DIR/reg_standard
	mkdir -p $FAST_DIR

	if [ $DO_SKIP_ANAT_PROC -eq 0 ]; then
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_processing.sh $SUBJ_NAME $PROJ_DIR $fsl_anat_elem
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_post_processing.sh $SUBJ_NAME $PROJ_DIR
	fi

	if [ $DO_SIENAX -eq 1 ]; then	
	  echo "===========>>>> $SUBJ_NAME: sienax with $BET_PARAM_STRING"
 	 	$FSLDIR/bin/sienax $T1_DATA -B "$BET_PARAM_STRING" -r
		rm $SIENAX_DIR/I.ni*
	fi

  if [ $DO_FIRST -eq 1 ]; then
  	if [ ! -f $FIRST_DIR/$T1_IMAGE_LABEL"_"all_none_origsegs.nii.gz -a ! -f $FIRST_DIR/$T1_IMAGE_LABEL"_"all_fast_origsegs.nii.gz ]
  	then
  		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_first.sh $SUBJ_NAME $PROJ_DIR $FIRST_STRUCTURES $FIRST_OUTPUT_DIR_NAME $FIRST_OUTPUT_REG_DIR_NAME
 		fi
 	fi
	. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_t1.sh $SUBJ_NAME $PROJ_DIR
fi

# ---- WB data ---------------------------------------------------------
if [ -d "$WB_DIR" ]; then
  if [ -f $WB_DATA.nii.gz ]; then
  	if [ ! -f $WB_BRAIN_DATA.nii.gz ]; then
  		echo "===========>>>> $SUBJ_NAME: bet on WB"
  		$FSLDIR/bin/bet $WB_DATA $WB_BRAIN_DATA -f $BET_F_VALUE_T2 -g 0 -m
  	fi
  fi
fi

# ---- RS data ---------------------------------------------------------
if [ -d "$RS_DIR" ]; then
	mkdir -p $ROI_DIR/reg_epi
  if [ ! -f $RS_DATA.nii.gz ]; 
  then
		echo "===========>>>> rs image $RS_DATA.nii.gz is missing...continuing"	  
	else

		mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/dr
		mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/group_templates
	
		# MELODIC
		if [ ! -d $RS_DIR/$RS_IMAGE_LABEL.ica -a $DO_MELODIC -eq 1 ]; then
			if [ ! -f $MELODIC_MODEL.fsf ]; 
			then 
				echo "===========>>>> melodic template file ($SUBJ_NAME $PROJ_DIR $MELODIC_MODEL.fsf) is missing...skipping 1st level melodic"
			else
				[ ! -d $RS_DIR/$MELODIC_OUTPUT_DIR.ica ] && . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_feat.sh $SUBJ_NAME $PROJ_DIR -model $MELODIC_MODEL -odn $MELODIC_OUTPUT_DIR.ica -initreg $MELODIC_DO_INIT_REG
			fi
		fi
		
		# FEAT PRE PROCESSING
		if [ ! -d $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat -a $DO_FEAT_PREPROC -eq 1 ]; then
			if [ ! -f $FEAT_PREPROC_MODEL.fsf ]; 
			then 
				echo "===========>>>> melodic template file ($SUBJ_NAME $PROJ_DIR $FEAT_PREPROC_MODEL.fsf) is missing...skipping feat preprocessing"
			else
				if [ ! -d $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat ]; then
					. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_feat.sh $SUBJ_NAME $PROJ_DIR -model $FEAT_PREPROC_MODEL -odn $FEAT_PREPROC_OUTPUT_DIR_NAME.feat -initreg $FEAT_PREPROC_DO_INIT_REG
				fi
			fi
		fi
		
		# if previous steps were not performed we apply conventional (not BBR) coregistration 
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_epi.sh $SUBJ_NAME $PROJ_DIR

		if [ $DO_ICA_AROMA -eq 1 ]; then
			. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_aroma.sh	$SUBJ_NAME $PROJ_DIR -idn $FEAT_PREPROC_OUTPUT_DIR_NAME -upsampling 4
		fi
		
		# do resting data nuisance removal		
		if [ $DO_NUISANCE -eq 1 ]; then
			. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_resting_nuisance.sh $SUBJ_NAME $PROJ_DIR
		fi		
  fi
fi

# ---- T2 data ---------------------------------------------------------
if [ -d "$DE_DIR" ]; then
  if [ -f $T2_DATA.nii.gz ]; then
  	HAS_T2=1
		mkdir -p $ROI_DIR/reg_t2
  	if [ ! -f $T2_BRAIN_DATA.nii.gz ]; then
  		echo "$SUBJ_NAME: bet on t2"
  		$FSLDIR/bin/bet $T2_DATA $T2_BRAIN_DATA -f $BET_F_VALUE_T2 -g 0.2 -m
  	fi
  fi
fi

# ---- DTI data ---------------------------------------------------------
if [ -d "$DTI_DIR" ]; then
  if [ "$(ls -A $DTI_DIR)" ]; then
  	if [ ! -f $DTI_DIR/$DTI_FIT_LABEL"_FA.nii.gz" -a $DO_DTIFIT -eq 1 ]; then
			echo "===========>>>> $SUBJ_NAME: dtifit"  	
			.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_ec_fit.sh $SUBJ_NAME $PROJ_DIR
  		$FSLDIR/bin/fslmaths $DTI_DIR/$DTI_FIT_LABEL"_L2" -add $DTI_DIR/$DTI_FIT_LABEL"_L3" -div 2 $DTI_DIR/$DTI_FIT_LABEL"_L23"
			.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_preproc.sh $SUBJ_NAME $PROJ_DIR
  	fi
  	mkdir -p $ROI_DIR/reg_dti

#  	if [ $HAS_T2 -eq 1 ]; then 	.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti_t2.sh $SUBJ_NAME $PROJ_DIR;
#  	else							  				
  	.	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti.sh $SUBJ_NAME $PROJ_DIR; 	 #fi
  	
  	if [ ! -f $DTI_DIR/$BEDPOST_OUTDIR_NAME/mean_S0samples.nii.gz ]; then
			[ -f $DTI_DIR/dw_aligned.bvecs.gz ] && gunzip $DTI_DIR/dw_aligned.bvecs.gz
      [ -f $DTI_DIR/dw_aligned.bvals.gz ] && gunzip $DTI_DIR/dw_aligned.bvals.gz
      
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



