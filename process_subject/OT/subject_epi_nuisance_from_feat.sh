#!/bin/bash
# ==================================================================================
# usage:	. ./path/rsfc_confounds_feat.sh 003 /media/data/MRI/projects/colegios 
# data have been already denoised with fsl_regfilt
# ==================================================================================

# ==================================================================================
# input:
#		$1	subject label  		:  003
#	  $2	proj_dir				  :  /media/data/MRI/projects/colegios
#		-f	folder postfix name		:  rs.ica
#		-i	filtered_func_data image name:
# 	-o  output postfix name
#		-p  full input path, alternative to -f,-i settings	

# ===== check parameters ==============================================================================
usage_string="$0 subj_label proj_dir -i input_ffd_name -f denoised_folder_postfix_name -o output_postfixname_series_and_folder or $0 subj_label proj_dir -p full_input_image_path -o output_postfixname_series_and_folder"
# ====== set init params =============================================================================



SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

INPUT_IMAGE_NAME="filtered_func_data"
ICA_DIR_POSTFIX="rs.ica"
OUTPUT_POSTFIX_NAME=""
INPUT_IMAGE=""

while [ ! -z "$1" ]
do
  case "$1" in
      -ifn) INPUT_IMAGE_NAME=$2;shift;;
      -idn) ICA_DIR_POSTFIX=$2;
      		ICA_DIR=$RS_DIR/$SUBJ_NAME-$ICA_DIR_POSTFIX
			 		if [ ! -d $ICA_DIR ]; then echo "error: ICA input dir ($ICA_DIR) do not exist......exiting"; exit; fi
      		shift;;
      -ifp) INPUT_IMAGE=$2;shift;;
      -odn) OUTPUT_POSTFIX_NAME="_"$2;shift;;
      *) break;;
  esac
  shift
done

# ===============================================================================
if [ -z $INPUT_IMAGE ]; then INPUT_IMAGE=$ICA_DIR/$INPUT_IMAGE_NAME; fi
if [ `$FSLDIR/bin/imtest $INPUT_IMAGE` = 0 ]; then "error: input image ($INPUT_IMAGE) do not exist......exiting"; exit; fi

TOT_VOL_NUM=`fslnvols $INPUT_IMAGE`

output_nuisance_feat_dir=$SBFC_DIR/feat/nuisance$OUTPUT_POSTFIX_NAME.feat
output_series_path=$SBFC_DIR/series
#===================================================================================================================================================================================
#template_nuisance_fsf=$PROJ_SCRIPT_DIR/glm/templates/sbfc_2_feat_nuisance_wm_csf_global.fsf
template_nuisance_fsf=$PROJ_SCRIPT_DIR/glm/templates/sbfc_2_feat_nuisance_wm_csf_HPF.fsf
if [ ! -f $template_nuisance_fsf ]; then echo "template nuisance fsf is missing....exiting"; exit; fi

DEST_FSF_NUISANCE=$SBFC_DIR/feat_nuisance$OUTPUT_POSTFIX_NAME

#===================================================================================================================================================================================
# fast2epi + nuisance variables calculation
#===================================================================================================================================================================================
echo "$SUBJ_NAME: extract confounds time series"
mkdir -p $SBFC_DIR/feat
mkdir -p $SBFC_DIR/series
mkdir -p $ROI_DIR/reg_epi

# extract GM,CSF,GLOBAL time-series

#$FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o $output_series_path/wm$SERIES_OUTPUT_NAME"_ts.txt" -m $ROI_DIR/reg_epi/mask_t1_wm_epi.nii.gz
#$FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o $output_series_path/csf$SERIES_OUTPUT_NAME"_ts.txt" -m $ROI_DIR/reg_epi/mask_t1_csf_epi.nii.gz
#$FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o $output_series_path/global$SERIES_OUTPUT_NAME"_ts.txt" -m $ROI_DIR/reg_epi/mask_t1_brain_epi.nii.gz
#===================================================================================================================================================================================
# NUISANCE FEAT
#===================================================================================================================================================================================
cp $template_nuisance_fsf $DEST_FSF_NUISANCE.fsf

echo "" >> $DEST_FSF_NUISANCE.fsf
echo "################################################################" >> $DEST_FSF_NUISANCE.fsf
echo "# overriding parameters" >> $DEST_FSF_NUISANCE.fsf
echo "################################################################" >> $DEST_FSF_NUISANCE.fsf
echo "set fmri(npts) $TOT_VOL_NUM" >> $DEST_FSF_NUISANCE.fsf
echo "set feat_files(1) $INPUT_IMAGE" >> $DEST_FSF_NUISANCE.fsf
echo "set highres_files(1) $T1_BRAIN_DATA" >> $DEST_FSF_NUISANCE.fsf
echo "set fmri(outputdir) $output_nuisance_feat_dir" >> $DEST_FSF_NUISANCE.fsf
echo "set fmri(regstandard) $FSL_DATA_STANDARD/MNI152_T1_2mm_brain" >> $DEST_FSF_NUISANCE.fsf
echo "set fmri(custom1) $RS_SERIES_CSF.txt" >> $DEST_FSF_NUISANCE.fsf
echo "set fmri(custom2) $RS_SERIES_WM.txt" >> $DEST_FSF_NUISANCE.fsf


#echo "set fmri(custom1) $output_series_path/wm$OUTPUT_POSTFIX_NAME"_"ts.txt" >> $DEST_FSF_NUISANCE.fsf
#echo "set fmri(custom2) $output_series_path/csf$OUTPUT_POSTFIX_NAME"_"ts.txt" >> $DEST_FSF_NUISANCE.fsf
#echo "set fmri(custom3) $output_series_path/global$OUTPUT_POSTFIX_NAME"_"ts.txt" >> $DEST_FSF_NUISANCE.fsf

echo "$SUBJ_NAME: sbfc NUISANCE feat"
$FSLDIR/bin/feat $DEST_FSF_NUISANCE.fsf
$FSLDIR/bin/fslmaths $output_nuisance_feat_dir/stats/res4d -add 10000 -mul $output_nuisance_feat_dir/mask.nii.gz $SBFC_DIR/nuisance$OUTPUT_POSTFIX_NAME"_10000" -odt float
#rm -rf $output_nuisance_feat_dir


