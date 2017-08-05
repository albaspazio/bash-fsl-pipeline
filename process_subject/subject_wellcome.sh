#!/bin/bash

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

Usage()
{
echo "usage: $0 SUBJ_LABEL PROJ_DIR -sienax \"-B -f 0.3\" -firststructs L_Thal,R_Thal -mel resting -dtifit -bedx bedpostx"
echo "-----t1 processing				"
echo "  	-noanat)							"
echo "  	-nobias)							"
echo "  	-weakbias)						"
echo "  	-sienax)							"
echo "  	-firststructs) 				"
echo "  	-firstodn) 						"
echo "  	-firstlreg2odn) 			"
echo "  	-firstnlreg2odn) 			"
echo "  	-freesurfer)					"
echo "-----epi preprocessing		"
echo "  	-epirm2vol)						"
echo "  	-skip_aroma) 					"
echo "  	-skip_nuisance)				"
echo "  	-hpfsec)							"
echo "  	-feat_preproc_odn)		"
echo "  	-feat_preproc_model)	"
echo "  	-featinitreg) 				"
echo "-----melodic processing	  " 						
echo "  	-mel)									"
echo "  	-melodn)							"
echo "  	-melmodel)						"
echo "  	-melinitreg) 					"
echo "-----dti processing 			"
echo "  	-bedx)								"
echo "  	-bedx_cuda)						"
echo "  	-dtifit)							"
echo "  	-autoptx_tract)				"
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
BEDPOST_OUTDIR_NAME=bedpostx
STRUCT_CONN_ATLAS_PATH="freesurfer"	  		# default value, otherwise specify path to image
STRUCT_CONN_ATLAS_NROI=0
# standard steps	  		
DO_ANAT_PROC=1
DO_FEAT_PREPROC=1
DO_ICA_AROMA=1
DO_NUISANCE=1

# to be chosen
DO_SIENAX=0
DO_FIRST=0
DO_MELODIC=0
DO_DTIFIT=0
DO_AUTOPTX_TRACT=0
DO_BEDPOST=0
DO_BEDPOST_CUDA=0
DO_FREESURFER_RECON=0
DO_STRUCT_CONN=0

# more params
DO_FEAT_PREPROC_INIT_REG=0 # valid also for melodic
DO_BIAS_TYPE=2	# 0: no bias, 1: weak bias, 2:full bias
HPF_SEC=100
STANDARD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain

declare -i DO_RMVOL_TO_NUM=0  # indicate how many volumes must have the final EPI image


while [ ! -z "$1" ]
do
  case "$1" in
  
  	# t1 preprocessing
  	-skipanat)						DO_ANAT_PROC=0;;	
		-nobias)							DO_BIAS_TYPE=0;;		# see subject_t1_processing.sh
		-weakbias)						DO_BIAS_TYPE=1;;
		-sienax)							DO_SIENAX=1
													BET_PARAM_STRING="-B -f 0.20"; shift;;
		-first) 							DO_FIRST=1;;
		-firststructs) 				DO_FIRST=1
													FIRST_STRUCTURES="-structs $2"; shift;;
		-firstodn) 						DO_FIRST=1
													FIRST_OUTPUT_DIR_NAME="-odn $2"; shift;;	
		-freesurfer)					DO_FREESURFER_RECON=1; shift;;			
		-stdimg) 							STANDARD_IMAGE=$2; shift;;
		
		# epi preprocessing
		-epirm2vol)						DO_RMVOL_TO_NUM=$2;	shift;;
		-skiparoma) 					DO_ICA_AROMA=0;;
		-skipnuisance)				DO_NUISANCE=0;;			
		-skippreproc)					DO_FEAT_PREPROC=0;;
		-hpfsec)							HPF_SEC=$2; shift;;
		-featpreprocodn)			DO_FEAT_PREPROC=1;
													FEAT_PREPROC_OUTPUT_DIR_NAME=$2; shift;;		
		-featpreprocmodel)		DO_FEAT_PREPROC=1
	  											FEAT_PREPROC_MODEL=$2; shift;;	
		-featinitreg) 				DO_FEAT_PREPROC_INIT_REG=1;;  # valid also for melodic

		# melodic													
		-mel)									DO_MELODIC=1;;
		-melodn)							DO_MELODIC=1
	  											MELODIC_OUTPUT_DIR=$2; shift;;				
		-melmodel)						DO_MELODIC=1
	  											MELODIC_MODEL=$2; shift;;	
		# dti	
		-bedx)								DO_BEDPOST=1; shift;;
		-bedxodn)							DO_BEDPOST=1
													BEDPOST_OUTDIR_NAME=$2; shift;;
		-bedxcuda)						DO_BEDPOST_CUDA=1; shift;;
		-bedxcudaodn)					DO_BEDPOST_CUDA=1
													BEDPOST_OUTDIR_NAME=$2; shift;;				
		-dtifit)							DO_DTIFIT=1;;			
		-autoptx_tract)				DO_AUTOPTX_TRACT=1;;		
		-structconn)					DO_STRUCT_CONN=1; 	
													STRUCT_CONN_ATLAS_PATH=$2; shift;;
		
		-structconn_nroi)			STRUCT_CONN_ATLAS_NROI=$2; shift;;
			
		*)  									echo "ERROR: unrecognized input parameter($1)";
													exit;;
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

	if [ $DO_ANAT_PROC -eq 1 ]; then
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_processing.sh $SUBJ_NAME $PROJ_DIR $fsl_anat_elem
		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_post_processing.sh $SUBJ_NAME $PROJ_DIR
	fi

	if [ $DO_SIENAX -eq 1 ]; then	
	  echo "===========>>>> $SUBJ_NAME: sienax with $BET_PARAM_STRING"
 	 	$FSLDIR/bin/sienax $T1_DATA -B "$BET_PARAM_STRING" -r
		rm $SIENAX_DIR/I.ni*
	fi
	
	. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_t1.sh $SUBJ_NAME $PROJ_DIR
	
  if [ $DO_FIRST -eq 1 ]; then
  	if [ ! -f $FIRST_DIR/$T1_IMAGE_LABEL"_"all_none_origsegs.nii.gz -a ! -f $FIRST_DIR/$T1_IMAGE_LABEL"_"all_fast_origsegs.nii.gz ];	then
  		. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_first.sh $SUBJ_NAME $PROJ_DIR $FIRST_STRUCTURES $FIRST_OUTPUT_DIR_NAME $FIRST_OUTPUT_REG_DIR_NAME
 		fi
 	fi
 	
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
  if [ 1 = 0 ];  then
		echo "===========>>>> rs image $RS_DATA.nii.gz is missing...continuing"	  
	else
	

		LOGFILE=$RS_DIR/log_epi_processing.txt
		
		run mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/dr
		run mkdir -p $PROJ_GROUP_ANALYSIS_DIR/melodic/group_templates
		run mkdir -p $RS_DIR/reg_standard
	
		if [ $DO_RMVOL_TO_NUM -gt 0 ]; then
			# check if I have to remove the first (TOT_VOL-DO_RMVOL_TO_NUM) volumes
			declare -i TOT_VOL_NUM=`fslnvols $RS_DATA`
			declare -i vol2remove=$TOT_VOL_NUM-$DO_RMVOL_TO_NUM
			if [ $vol2remove -gt 0 ]; then
				run mv $RS_DATA.nii.gz $RS_DATA"_fullvol".nii.gz
				run $FSLDIR/bin/fslroi $RS_DATA"_fullvol" $RS_DATA $vol2remove $TOT_VOL_NUM
			fi
		fi

		# FEAT PRE PROCESSING
		if [ `$FSLDIR/bin/imtest $RS_DIR/$RS_POST_PREPROCESS_IMAGE_LABEL` = 0 ]; then
			if [ ! -f $FEAT_PREPROC_MODEL.fsf ]; then 
				echo "===========>>>> FEAT_PREPROC template file ($SUBJ_NAME $PROJ_DIR $FEAT_PREPROC_MODEL.fsf) is missing...skipping feat preprocessing"
			else
				if [ ! -d $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat ]; then
					run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_feat.sh $SUBJ_NAME $PROJ_DIR -model $FEAT_PREPROC_MODEL -odn $FEAT_PREPROC_OUTPUT_DIR_NAME.feat -stdimg $STANDARD_IMAGE -initreg $DO_FEAT_PREPROC_INIT_REG
					run $FSLDIR/bin/imcp $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat/filtered_func_data $RS_DIR/$RS_POST_PREPROCESS_IMAGE_LABEL
				fi
			fi
		fi

		# do AROMA processing
		if [ $DO_ICA_AROMA -eq 1 -a `$FSLDIR/bin/imtest $RS_DIR/$RS_POST_AROMA_IMAGE_LABEL` = 0 ]; then
			run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_aroma.sh $SUBJ_NAME $PROJ_DIR -idn $FEAT_PREPROC_OUTPUT_DIR_NAME.feat  # do not register to standard
			run $FSLDIR/bin/imcp $RS_AROMA_IMAGE $RS_DIR/$RS_POST_AROMA_IMAGE_LABEL	
		fi
		
		# do nuisance removal (WM, CSF & highpass temporal filtering)....create the following file: $RS_IMAGE_LABEL"_preproc_aroma_nuisance"
		if [ $DO_NUISANCE -eq 1 -a `$FSLDIR/bin/imtest $RS_DIR/$RS_POST_NUISANCE_IMAGE_LABEL` = 0 ]; then
			run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_resting_nuisance.sh $SUBJ_NAME $PROJ_DIR -hpfsec $HPF_SEC -ifn $RS_POST_AROMA_IMAGE_LABEL
			run . $GLOBAL_SCRIPT_DIR/process_subject/subject_transforms_roi.sh $SUBJ_NAME $PROJ_DIR -thresh 0 -regtype epi2std4 -pathtype abs $RS_DIR/$RS_POST_NUISANCE_IMAGE_LABEL
			$FSLDIR/bin/immv $ROI_DIR/reg_standard4/$RS_POST_NUISANCE_STANDARD_IMAGE_LABEL $RS_FINAL_REGSTD_IMAGE
		fi
		
		run $FSLDIR/bin/imcp $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat/reg_standard/bg_image $RS_FINAL_REGSTD_DIR/bg_image
		run $FSLDIR/bin/imcp $RS_DIR/$FEAT_PREPROC_OUTPUT_DIR_NAME.feat/reg_standard/mask $RS_FINAL_REGSTD_DIR/mask		


		# NOW reg_standard contains a denoised file with its mask and background image. nevertheless, we also do a melodic to check the output,
		# doing another MC and HPF results seems to improve...although they should not...something that should be investigated....
		

		# MELODIC
		if [ ! -d $RS_DIR/$MELODIC_OUTPUT_DIR.ica -a $DO_MELODIC -eq 1 ]; then
			if [ ! -f $MELODIC_MODEL.fsf ]; 
			then 
				echo "===========>>>> melodic template file ($SUBJ_NAME $PROJ_DIR $MELODIC_MODEL.fsf) is missing...skipping 1st level melodic"
			else
				if [ ! -d $RS_DIR/$MELODIC_OUTPUT_DIR.ica ]; then
					run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_feat.sh $SUBJ_NAME $PROJ_DIR -model $MELODIC_MODEL -odn $MELODIC_OUTPUT_DIR.ica -stdimg $STANDARD_IMAGE -initreg $DO_FEAT_PREPROC_INIT_REG -ifn $RS_POST_NUISANCE_IMAGE_LABEL
					if [ `$FSLDIR/bin/imtest $RS_DIR/$MELODIC_OUTPUT_DIR.ica/reg_standard/filtered_func_data` = 1 ]; then
						run $FSLDIR/bin/imcp $RS_DIR/$MELODIC_OUTPUT_DIR.ica/reg_standard/filtered_func_data $RS_FINAL_REGSTD_DIR/${RS_POST_NUISANCE_MELODIC_IMAGE_LABEL}_$MELODIC_OUTPUT_DIR
					fi
				fi
			fi
		fi

		
		# calculate the remaining transformations   .....3/4/2017 si blocca qui...devo commentarlo per andare avanti !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_epi.sh $SUBJ_NAME $PROJ_DIR
		
		# coregister fast-highres to epi
		echo "$SUBJ_NAME: coregister fast-highres to epi"
		[ ! -f $ROI_DIR/reg_epi/t1_wm_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_wm.nii.gz -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_wm_epi.nii.gz
		[ ! -f $ROI_DIR/reg_epi/t1_csf_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_csf.nii.gz -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_csf_epi.nii.gz
		[ ! -f $ROI_DIR/reg_epi/t1_gm_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_gm.nii.gz -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_gm_epi.nii.gz
		[ ! -f $ROI_DIR/reg_epi/t1_brain_epi.nii.gz ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA.nii.gz -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_brain_epi.nii.gz			

		# mask & binarize 
		$FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_gm_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_gm_epi.nii.gz
		$FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_wm_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_wm_epi.nii.gz
		$FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_csf_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_csf_epi.nii.gz
		$FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_brain_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_brain_epi.nii.gz		
		
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
			LOGFILE=$DTI_DIR/log_dti_processing.txt
			
			run .	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_ec_fit.sh $SUBJ_NAME $PROJ_DIR
  		run $FSLDIR/bin/fslmaths $DTI_DIR/$DTI_FIT_LABEL"_L2" -add $DTI_DIR/$DTI_FIT_LABEL"_L3" -div 2 $DTI_DIR/$DTI_FIT_LABEL"_L23"
			run .	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_preproc.sh $SUBJ_NAME $PROJ_DIR
  	fi
  	run mkdir -p $ROI_DIR/reg_dti

  	if [ $HAS_T2 -eq 1 ]; then 	run .	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti_t2.sh $SUBJ_NAME $PROJ_DIR;
  	else							  				
  		run .	$GLOBAL_SUBJECT_SCRIPT_DIR/subject_transforms_calculate_dti.sh $SUBJ_NAME $PROJ_DIR; 	 
  	fi
  	
  	if [ ! -f $DTI_DIR/$BEDPOST_OUTDIR_NAME/mean_S0samples.nii.gz ]; then
			[ -f $DTI_DIR/$DTI_ROTATED_BVEC.gz ] && gunzip $DTI_DIR/$DTI_ROTATED_BVEC.gz
      [ -f $DTI_DIR/$DTI_BVAL.gz ] && gunzip $DTI_DIR/$DTI_BVAL.gz
      
      if [ $DO_BEDPOST -eq 1 ]; then 
		  	run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_bedpostx.sh $SUBJ_NAME $PROJ_DIR $BEDPOST_OUTDIR_NAME
		  fi

      if [ $DO_BEDPOST_CUDA -eq 1 ]; then 
		  	run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_bedpostx_CUDA.sh $SUBJ_NAME $PROJ_DIR $BEDPOST_OUTDIR_NAME
		  fi
		fi

		if [ $DO_AUTOPTX_TRACT -eq 1 ]; then
			if [ ! -f $DTI_DIR/$BEDPOST_OUTDIR_NAME/mean_S0samples.nii.gz ]; then
				echo "subj $SUBJ_NAME ,you requested the autoPtx tractorgraphy, but bedpostx was not performed.....skipping"
			else
				. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_autoPtx_tractography.sh $SUBJ_NAME $PROJ_DIR
			fi
		fi
		
		if [ $DO_STRUCT_CONN -eq 1 -a ! -f $TV_MATRICES_DIR/fa_AM.mat ]; then
			. $GLOBAL_SUBJECT_SCRIPT_DIR/subject_dti_conn_matrix.sh $SUBJ_NAME $PROJ_DIR 		
		fi
		
		
  fi
fi
# -------------------------------------------------------------



