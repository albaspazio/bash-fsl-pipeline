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
OUTPUT_TS_FILE=$1;shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

INPUT_IMAGE_NAME="nuisance_10000"
INPUT_IMAGE=$SBFC_DIR/$INPUT_IMAGE_NAME
INPUT_ROI_DIR=$ROI_DIR/reg_epi

while [ ! -z "$1" ]
do
  case "$1" in
     
      -ifp) 	INPUT_IMAGE=$2;shift;;      
      
      -idp)		INPUT_ROI_DIR=$2
      				if [ ! -d $INPUT_ROI_DIR ]; then echo "ERROR, input roi dir ($INPUT_ROI_DIR) does not exist.....exiting"; exit; fi
      				shift;;    

      *) break;;
  esac
  shift
done

output_dir=$(dirname $OUTPUT_TS_FILE)
output_name=$(basename $OUTPUT_TS_FILE)
output_name_noext=${output_name%.fsf}

MASK_FILES=$@
# ===============================================================================
if [ ! -f $INPUT_IMAGE ]; then "error: input image ($INPUT_IMAGE) do not exist......exiting"; exit; fi
TOT_VOL_NUM=`fslnvols $INPUT_IMAGE`

#===================================================================================================================================================================================
declare -i cnt=0
declare -a arr_series_files=()
for ROI in ${MASK_FILES[@]}
do
	roi_name=$(basename $ROI)
	roi_name=$(remove_ext $roi_name)
	arr_series_files[cnt]=$output_dir/series_$roi_name"_"$output_name
	$FSLDIR/bin/fslmeants -i $INPUT_IMAGE -o ${arr_series_files[cnt]} -m $ROI
	cnt=$cnt+1
done

paste ${arr_series_files[@]} | column -s $'\t' -t > $OUTPUT_TS_FILE
#rm ${arr_series_files[@]}






