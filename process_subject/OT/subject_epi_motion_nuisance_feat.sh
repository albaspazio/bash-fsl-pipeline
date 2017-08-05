#!/bin/bash
# ==================================================================================
# input:
#		$1	subject label  		:  003
#	  $2	proj_dir				  :  /media/data/MRI/projects/colegios 	
#   $3  input_file_name_postfix : _skip4vol
# ===== check parameters ==============================================================================
if [ $# -lt 2 -o $# -gt 3 ]; then
  echo "Usage: $0 subj_label proj_dir input_file_name_postfix"
  exit
fi
# ====== set init params =============================================================================
SUBJ_NAME=$1
PROJ_DIR=$2
INPUT_FILE_NAME_POSTFIX=$3
# ===============================================================================

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

main()
{
	if [ ! -d $SUBJECT_DIR ]; then 
		echo "subject $SUBJ_NAME is not present in project $PROJ_DIR...skipping"; return 0
	fi

	TOT_VOL_NUM=`fslnvols $RS_DATA$INPUT_FILE_NAME_POSTFIX.nii.gz`
	mc_feat_dir=$SBFC_DIR/feat/motion.feat
	template_motion_fsf=$PROJ_SCRIPT_DIR/glm/templates/sbfc_1_feat_motion_feat.fsf
	DEST_FSF_MC=$SBFC_DIR/feat_motion
	output_rs_mc=$SBFC_DIR/nuisance_10000.nii.gz
	#===================================================================================================================================================================================
	if [ ! -f $template_motion_fsf ]; then echo "template motion fsf is missing....exiting"; exit; fi

	mkdir -p $SBFC_DIR/feat

	#===================================================================================================================================================================================
	# MOTION CORRECTION FEAT
	#===================================================================================================================================================================================
	cp $template_motion_fsf $DEST_FSF_MC.fsf

	echo "" >> $DEST_FSF_MC.fsf
	echo "################################################################" >> $DEST_FSF_MC.fsf
	echo "# overriding parameters" >> $DEST_FSF_MC.fsf
	echo "################################################################" >> $DEST_FSF_MC.fsf
	echo "set fmri(npts) $TOT_VOL_NUM" >> $DEST_FSF_MC.fsf
	echo "set feat_files(1) $RS_DATA$INPUT_FILE_NAME_POSTFIX.nii.gz" >> $DEST_FSF_MC.fsf
	echo "set highres_files(1) $T1_BRAIN_DATA" >> $DEST_FSF_MC.fsf
	echo "set fmri(outputdir) $mc_feat_dir" >> $DEST_FSF_MC.fsf
	echo "set fmri(regstandard) $FSL_DATA_STANDARD/MNI152_T1_2mm_brain" >> $DEST_FSF_MC.fsf

	echo "$SUBJ_NAME: start MC feat"
	$FSLDIR/bin/feat $DEST_FSF_MC.fsf
	$FSLDIR/bin/fslmaths $mc_feat_dir/stats/res4d -add 10000 -mul $mc_feat_dir/mask.nii.gz $output_rs_mc -odt float
	rm -rf $mc_feat_dir
	. $GLOBAL_SUBJECT_SCRIPT_DIR/OT/subject_epi_nuisance_from_feat.sh $SUBJ_NAME $PROJ_DIR -ifp $output_rs_mc
}
main
