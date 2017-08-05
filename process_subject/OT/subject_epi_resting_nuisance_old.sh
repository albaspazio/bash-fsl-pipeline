# ==================================================================================
# usage:	. ./path/execute_subject_resting_nuisance.sh 003 colegios -idn resting.feat
# ==================================================================================
#!/bin/sh
# ==================================================================================
# input:
#		$1			subject label  		:  	003
#	  $2			proj_dir					:  	/homer/home/..../fsl_belgrade	
#		-idn		INPUT_FEAT_NAME		:  	resting.feat
#
# output:	write a folder $RS_DIR/odn.ica
#
# task:		run single subject AROMA ICA, and apply registration to upsampled standard space

usage_string="Usage: $0 subj_label proj_dir"
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift


main()
{
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	# ===================================================================================
	echo "execute_subject_resting_nuisance of $SUBJ_NAME"

	mkdir -p $RS_DIR/fc/feat
	mkdir -p $RS_DIR/fc/series
			
	echo "===========>>>> $SUBJ_NAME: coregister fast-highres to epi"
	[ ! -f $ROI_DIR/reg_epi/t1_wm_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_wm -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_wm_epi
	[ ! -f $ROI_DIR/reg_epi/t1_csf_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_csf -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_csf_epi
	[ ! -f $ROI_DIR/reg_epi/t1_gm_epi.nii.gz ] && $FSLDIR/bin/flirt -in $ROI_DIR/reg_t1/mask_t1_gm -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_gm_epi
	[ ! -f $ROI_DIR/reg_epi/t1_brain_epi.nii.gz ] && $FSLDIR/bin/flirt -in $T1_BRAIN_DATA.nii.gz -ref $ROI_DIR/reg_epi/example_func -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -out $ROI_DIR/reg_epi/t1_brain_epi.nii.gz			

	# mask & binarize 
	[ ! -f $ROI_DIR/reg_epi/mask_t1_gm_epi.nii.gz ] && $FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_gm_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_gm_epi.nii.gz
	[ ! -f $ROI_DIR/reg_epi/mask_t1_wm_epi.nii.gz ] && $FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_wm_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_wm_epi.nii.gz
	[ ! -f $ROI_DIR/reg_epi/mask_t1_csf_epi.nii.gz ] && $FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_csf_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_csf_epi.nii.gz
	[ ! -f $ROI_DIR/reg_epi/mask_t1_brain_epi.nii.gz ] && $FSLDIR/bin/fslmaths $ROI_DIR/reg_epi/t1_brain_epi.nii.gz -thr 0.2 -bin $ROI_DIR/reg_epi/mask_t1_brain_epi.nii.gz

	if [ -f $PROJ_SCRIPT_DIR/glm/templates/sbfc_1_feat_motion_feat.fsf -a -f $PROJ_SCRIPT_DIR/glm/templates/sbfc_2_feat_nuisance_wm_csf_global.fsf ]; 
	then 
			[ ! -f $SBFC_DIR/nuisance_10000.nii.gz ] && . $GLOBAL_SCRIPT_DIR/process_subject/subject_epi_motion_nuisance_feat.sh $SUBJ_NAME $PROJ_DIR
	else
		[ ! -f $PROJ_SCRIPT_DIR/glm/templates/sbfc_1_feat_motion_feat.fsf ] && echo "motion feat template file ($SUBJ_NAME, template_feat_preprocessing_motion_feat.fsf ) is missing...skipping sbfc preprocessing"
		[ ! -f $PROJ_SCRIPT_DIR/glm/templates/sbfc_2_feat_nuisance_wm_csf_global.fsf ] && echo "nuisance feat template file ($SUBJ_NAME, template_feat_nuisance_wm_csf_global.fsf ) is missing...skipping sbfc preprocessing"
	fi

}
main $@
