# ==================================================================================
# usage:	. ./path/execute_subject_aroma.sh 003 colegios -idn resting.feat
# ==================================================================================
#!/bin/sh
# ==================================================================================
# input:
#		$1					subject label  		:  	003
#	  $2					proj_dir					:  	/homer/home/..../fsl_belgrade	
#		-idn				INPUT_FEAT_NAME		:  	resting.feat
#   -upsampling UPSAMPLING_FACTOR :		4
#
# output:	write a folder $RS_DIR/odn.ica
#
# task:		run single subject AROMA ICA, and apply registration to upsampled standard space
# it needs that feat created : 	1) reg/example_func2highres.mat
#																2) reg/highres2standard_warp.nii.gz
. $GLOBAL_SCRIPT_DIR/utility_functions.sh


usage_string="Usage: $0 subj_label proj_dir -idn INPUT_FEAT_DIR_NAME [resting/resting.feat]"
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift


INPUT_FEAT_DIR_NAME=resting.feat
UPSAMPLING_FACTOR=0

main()
{
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	# default
	INPUT_FEAT_DIR_NAME=resting.feat
	OUTPUT_FEAT_DIR_NAME=ica_aroma

	while [ ! -z "$1" ]
	do
		case "$1" in
		    -idn) 				INPUT_FEAT_DIR_NAME=$2;shift;;
		    -odn)					OUTPUT_FEAT_DIR_NAME=$2;shift;;
		    -upsampling) 	UPSAMPLING_FACTOR=$2;shift;;
		    *) break;;
		esac
		shift
	done

	# ===================================================================================
	# CHECK FILE EXISTENCE #.feat
	input_feat_dir=$RS_DIR/$INPUT_FEAT_DIR_NAME
	if [ ! -d $input_feat_dir ]; then echo "error in execute_subject_aroma: you specified an incorrect folder name ($input_feat_dir)......exiting"; exit; fi
	# ===================================================================================

	run echo "execute_subject_aroma of $SUBJ_NAME"
	run python2.7 $ICA_AROMA_SCRIPT_PATH -feat $input_feat_dir -out $RS_DIR/$OUTPUT_FEAT_DIR_NAME
	
	if [ $UPSAMPLING_FACTOR -gt 0 ]; then 

		run mkdir -p $RS_REGSTD_AROMA_DIR

		# problems with non linear registration....use linear one.	
		#	cp $input_feat_dir/design.fsf $RS_AROMA_DIR
		#	cp $input_feat_dir/reg $RS_AROMA_DIR
		#	$FSLDIR/bin/featregapply $RS_AROMA_DIR	

		# upsampling of standard
		run ${FSLDIR}/bin/flirt -ref $input_feat_dir/reg/standard -in $input_feat_dir/reg/standard -out $RS_REGSTD_AROMA_DIR/standard -applyisoxfm $UPSAMPLING_FACTOR  #4
		run ${FSLDIR}/bin/flirt -ref $RS_REGSTD_AROMA_DIR/standard -in $input_feat_dir/reg/highres -out $RS_REGSTD_AROMA_DIR/bg_image -applyxfm -init $input_feat_dir/reg/highres2standard.mat -interp sinc -datatype float
		run ${FSLDIR}/bin/flirt -ref $RS_REGSTD_AROMA_DIR/standard -in $RS_AROMA_DIR/denoised_func_data_nonaggr -out $RS_REGSTD_AROMA_DIR/filtered_func_data -applyxfm -init $input_feat_dir/reg/example_func2standard.mat -interp trilinear -datatype float
		run ${FSLDIR}/bin/fslmaths $RS_REGSTD_AROMA_DIR/filtered_func_data -Tstd -bin $RS_REGSTD_AROMA_DIR/mask -odt char
	fi
}

main $@
