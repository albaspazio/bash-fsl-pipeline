#!/bin/bash
# ==================================================================================
# input:
#		$1	subject label  		:  003
#	  $2	proj_dir				  : /media/data/MRI/projects/colegios
#		-i	input image name  : 
#		-m	input fsf template: 
#		-s	extra series name : 

# ===== check parameters ==============================================================================
usage_string="$0 SUBJ_NAME PROJ_DIR -i input_ffd_name -f denoised_folder_postfix_name -o output_postfixname_series_and_folder or $0 subj_label proj_dir -p full_input_image_path -o output_postfixname_series_and_folder"
# ====== set init params =============================================================================

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

SERIES_POSTFIX_NAME=""
INPUT_FILE_NAME=$RS_POST_NUISANCE_IMAGE_LABEL
INPUT_ROI_DIR=$ROI_DIR/reg_epi
FSF_TEMPL_FILE=$PROJ_SCRIPT_DIR/glm/templates/sbfc_3_feat_1roi
STD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain
while [ ! -z "$1" ]
do
  case "$1" in
      -ifn) 		INPUT_FILE_NAME=$2; shift;;
      				
      -idp)			INPUT_ROI_DIR=$2
      					if [ ! -d $INPUT_ROI_DIR ]; then echo "ERROR, input roi dir ($INPUT_ROI_DIR) does not exist.....exiting"; exit; fi
      					shift;;
      				
      -model) 		FSF_TEMPL_FILE=$2
       					if [ ! -f $FSF_TEMPL_FILE.fsf ]; then echo "ERROR, input FSF template ($FSF_TEMPL_FILE.fsf) does not exist.....exiting"; exit; fi
      					shift;;
      				
      -son) 		SERIES_POSTFIX_NAME="_"$2;shift;;
      
      -stdimg)		STD_IMAGE=$2; shift;;
      
      *) break;;
  esac
  shift
done

input_rs_image=$RS_DIR/$INPUT_FILE_NAME
if [ `$FSLDIR/bin/imtest $input_rs_image` = 0 ]; then echo "ERROR, input file name ($input_rs_image) does not exist.....exiting"; exit; fi


# remaining parameters are roi name (located in: $INPUT_ROI_DIR)
# ===============================================================================
output_series_path=$SBFC_DIR/series
TOT_VOL_NUM=`fslnvols $input_rs_image`

output_feat_dir_root=$SBFC_DIR/feat/feat_
DEST_FSF_ROI_ROOT=$SBFC_DIR/feat_roi_

#===================================================================================================================================================================================
# extract ROI timeseries
for ROI_NAME in "$@"
do
	output_serie=$output_series_path/$ROI_NAME"_ts"$SERIES_POSTFIX_NAME".txt"
	$FSLDIR/bin/fslmeants -i $input_rs_image -o $output_serie -m $INPUT_ROI_DIR/$ROI_NAME    # <<<<<<<<<<<<<<<<<<--------------------
	
	DEST_FSF=$DEST_FSF_ROI_ROOT$ROI_NAME$SERIES_POSTFIX_NAME
	OUTPUT_DIR=$output_feat_dir_root$ROI_NAME$SERIES_POSTFIX_NAME
	cp $FSF_TEMPL_FILE.fsf $DEST_FSF.fsf

	echo "" >> $DEST_FSF.fsf
	echo "################################################################" >> $DEST_FSF.fsf
	echo "# overriding parameters" >> $DEST_FSF.fsf
	echo "################################################################" >> $DEST_FSF.fsf
	echo "set fmri(npts) $TOT_VOL_NUM" >> $DEST_FSF.fsf
	echo "set feat_files(1) $input_rs_image" >> $DEST_FSF.fsf
	echo "set highres_files(1) $T1_BRAIN_DATA" >> $DEST_FSF.fsf
	echo "set fmri(outputdir) $OUTPUT_DIR" >> $DEST_FSF.fsf
	echo "set fmri(regstandard) $STD_IMAGE" >> $DEST_FSF.fsf
	echo "set fmri(custom1) $output_serie" >> $DEST_FSF.fsf

	echo "subj:$SUBJ_NAME, starting ROI FEAT: $ROI_NAME"
	$FSLDIR/bin/feat $DEST_FSF.fsf
	$FSLDIR/bin/featregapply $OUTPUT_DIR.feat	
done
