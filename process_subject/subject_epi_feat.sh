# ==================================================================================
# usage:	. ./path/execute_subject_feat.sh 003 colegios -ifn resting -idn resting -odn resting.feat -model -initreg 1 -tr 3 -te 55
# ==================================================================================
#!/bin/sh
# ==================================================================================
# input:
#		$1			subject label  		:  	003
#	  $2			proj_dir					:  	/homer/home/..../fsl_belgrade	
# 	-model	FEAT_fsf_path	: 	$PROJ_SCRIPT_DIR/glm/templates/single_FEAT.fsf
#		-idn		folder name				:  	resting
#		-odn		OUTPUT_FEAT_PATH	:  	auto_model_FEAT
# 	-ifn		input file name		: 	resting
# output:	write a folder $RS_DIR/odn.ica
#
# task:		run single subject ICA

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

usage_string="Usage: $0 proj_label subj_label -ifn input_file_name[resting] -model FEAT_fsf_path -idn INPUT_FOLDER_NAME[resting] -stdimg standard_image -odn OUTPUT_FEAT_PATH_name"
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift


main()
{
	
	
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

	# default
	INPUT_FILE_NAME=resting
	INPUT_FOLDER_NAME=resting
	OUTPUT_FEAT_NAME=resting.feat
	STANDARD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain
	DO_INIT_REG=0
	SET_TR=0
	SET_TE=0
	

	
	while [ ! -z "$1" ]
	do
		case "$1" in
		    -ifn) 		INPUT_FILE_NAME=$2;shift;;
		    -idn) 		INPUT_FOLDER_NAME=$2;shift;;
		    -odn) 		OUTPUT_FEAT_NAME=$2;shift;;
	 			-stdimg)	STANDARD_IMAGE=$2;shift;;
				-model)		INPUT_FEAT_FSF=$2;shift;;
				-initreg) DO_INIT_REG=$2;shift;;
				-tr)			SET_TR=1; TR=$2;shift;;
				-te)			SET_TE=1; TE=$2;shift;;
		    *) break;;
		esac
		shift
	done

	run echo "---------------------------------------------------------------------------------------------"
	run echo "$SUBJ_NAME: FEAT with model: " $INPUT_FEAT_FSF.fsf

	# ===================================================================================
	# CHECK FILE EXISTENCE
	INPUT_EPI_PATH=$SUBJECT_DIR/$INPUT_FOLDER_NAME
	if [ ! -d $INPUT_EPI_PATH ]; then echo "error: you specified an incorrect folder name ($INPUT_EPI_PATH)......exiting"; exit; fi

	INPUT_EPI_DATA_PATH=$INPUT_EPI_PATH/$INPUT_FILE_NAME
	if [ `$FSLDIR/bin/imtest $INPUT_EPI_DATA_PATH` = 0 ]; then echo "error: input rs file ($INPUT_EPI_DATA_PATH.nii.gz) do not exist......exiting"; exit; fi

	if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "error: template file ($STANDARD_IMAGE.nii.gz) do not exist......exiting"; exit; fi

	if [ ! -f $INPUT_FEAT_FSF.fsf ]; then echo "error: design file ($INPUT_FEAT_FSF.fsf) do not exist......exiting"; exit; fi

	# ===================================================================================

	TOT_VOL_NUM=`fslnvols $INPUT_EPI_DATA_PATH`

	# FEAT output folder full path 
	OUTPUT_FEAT_PATH=$INPUT_EPI_PATH/$OUTPUT_FEAT_NAME

	# final FEAT exploration fsf 
	mkdir -p $INPUT_EPI_PATH/model
	OUTPUT_FEAT_FSF=$INPUT_EPI_PATH/model/FEAT 
	run cp $INPUT_FEAT_FSF.fsf $OUTPUT_FEAT_FSF.fsf

	# FEAT fsf -------------------------------------------------------------------------------------------------------------------------
	echo "" >> $OUTPUT_FEAT_FSF.fsf
	echo "################################################################" >> $OUTPUT_FEAT_FSF.fsf
	echo "# overriding parameters" >> $OUTPUT_FEAT_FSF.fsf
	echo "################################################################" >> $OUTPUT_FEAT_FSF.fsf
	echo "set fmri(npts) $TOT_VOL_NUM" >> $OUTPUT_FEAT_FSF.fsf
	echo "set feat_files(1) $INPUT_EPI_DATA_PATH" >> $OUTPUT_FEAT_FSF.fsf
	echo "set highres_files(1) $T1_BRAIN_DATA" >> $OUTPUT_FEAT_FSF.fsf
	if [ -f $WB_BRAIN_DATA.nii.gz -a $DO_INIT_REG -eq 1 ]; then
		echo "set fmri(reginitial_highres_yn) 1" >> $OUTPUT_FEAT_FSF.fsf
		echo "set initial_highres_files(1) $WB_BRAIN_DATA" >> $OUTPUT_FEAT_FSF.fsf
	else
		echo "set fmri(reginitial_highres_yn) 0" >> $OUTPUT_FEAT_FSF.fsf
	fi
	echo "set fmri(outputdir) $OUTPUT_FEAT_PATH" >> $OUTPUT_FEAT_FSF.fsf
	echo "set fmri(regstandard) $STANDARD_IMAGE" >> $OUTPUT_FEAT_FSF.fsf
	
	if [ $SET_TR -eq 1 ]; then
		echo "set fmri(tr) $TR_VALUE";
	fi
	
	if [ $SET_TE -eq 1 ]; then
		echo "set fmri(te) $TE_VALUE"
	fi

	#--------------------------------------------------------------------------------------------------------------------------------------
	run $FSLDIR/bin/feat $OUTPUT_FEAT_FSF.fsf		# execute  FEAT
	
	# if func_data were coregistered, then calculate reg_standard and copy files to roi/reg_epi folder
	if [ -d $OUTPUT_FEAT_PATH/reg ]; then 
		run $FSLDIR/bin/featregapply $OUTPUT_FEAT_PATH
		run . $GLOBAL_SUBJECT_SCRIPT_DIR/subject_epi_reg_copy_feat.sh $SUBJ_NAME $PROJ_DIR -odp $OUTPUT_FEAT_PATH #equals to : -idn $INPUT_FOLDER_NAME -idn2 $OUTPUT_FEAT_NAME
	fi
}
main $@
