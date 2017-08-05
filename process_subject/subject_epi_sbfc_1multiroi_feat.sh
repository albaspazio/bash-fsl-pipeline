#!/bin/bash
# ==================================================================================
# input:
#		$1			subject label  		:  003
#	  $2			proj_dir				  : /media/data/MRI/projects/colegios
#		-ifn		input image name  : 
# 	-odn  	output dir name		:	appended to $SBFC_DIR/feat
#		-model	input fsf template: 
#		-son		extra series name : 
# ===== check parameters ==============================================================================
usage_string="$0 subj_label proj_dir -i input_ffd_name -f denoised_folder_postfix_name -o output_postfixname_series_and_folder or $0 subj_label proj_dir -p full_input_image_path -o output_postfixname_series_and_folder"
# ====== set init params =============================================================================

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh


echo "input params : $@"

SERIES_POSTFIX_NAME=""
INPUT_FILE_NAME=nuisance_10000.nii.gz
input_rs_image=$SBFC_DIR/$INPUT_FILE_NAME
INPUT_ROI_DIR=$ROI_DIR/reg_epi
FSF_TEMPL_FILE=$PROJ_SCRIPT_DIR/glm/templates/template_feat_roi.fsf

while [ ! -z "$1" ]
do
  case "$1" in
  
      -ifn) 	INPUT_FILE_NAME=$2
							input_rs_image=$SBFC_DIR/$INPUT_FILE_NAME;
      				shift;;

      -ifp) 	input_rs_image=$SUBJECT_DIR/$2
      				shift;;

      -idp)		INPUT_ROI_DIR=$2
      				if [ ! -d $INPUT_ROI_DIR ]; then echo "ERROR, input roi dir ($INPUT_ROI_DIR) does not exist.....exiting"; exit; fi
      				shift;;
      				      		
      -odn) 	OUTPUT_DIR_NAME=$2
							output_feat_dir=$SBFC_DIR/feat/$OUTPUT_DIR_NAME
							shift;;
					
      -model) FSF_TEMPL_FILE=$2
      				if [ ! -f $FSF_TEMPL_FILE.fsf ]; then echo "ERROR, input FSF template ($FSF_TEMPL_FILE.fsf) do not exist.....exiting"; exit; fi
      				shift;;
      		
      -son) 	SERIES_POSTFIX_NAME="_"$2;shift;;
      
      -ridn) 	ROI_INPUT_DIR_NAME="$2";
							INPUT_ROI_DIR=$SUBJECT_DIR/$ROI_INPUT_DIR_NAME
							shift;;
      
      *) 			break;;
  esac
  shift
done


if [ `$FSLDIR/bin/imtest $input_rs_image` = 0 ]; then echo "ERROR, input file name ($input_rs_image) do not exist.....exiting"; exit; fi



declare -a INPUT_ROI=( $@ )
declare -i NUM_ROIS=${#INPUT_ROI[@]}
declare -i NUM_CONTRASTS=2*$NUM_ROIS

init_data()
{
	for (( x=1; x<=$NUM_CONTRASTS; x++ ))
	do 
		for (( y=1; y<=$NUM_CONTRASTS; y++ ))
		do 
			if [ $x -ne $y ];	then echo "set fmri(conmask${x}_$y) 0" >> $DEST_FSF.fsf; fi
		done
	done
	
	for (( x=1; x<=$NUM_CONTRASTS; x++ ))
	do 
		for (( y=1; y<=$NUM_ROIS; y++ ))
		do 
			echo "set fmri(con_real${x}.$y) 0" >> $DEST_FSF.fsf
			echo "set fmri(con_orig${x}.$y) 0" >> $DEST_FSF.fsf
		done
	done
	
}


create_regressor_data()
{
	declare -i row=0
	declare -i col=0
	declare -i x=0
	echo "#-----------------------------------" >> $DEST_FSF.fsf
	ev=$1
	echo "set fmri(evtitle$ev) c$ev" >> $DEST_FSF.fsf
	echo "set fmri(shape$ev) 2" >> $DEST_FSF.fsf
	echo "set fmri(convolve$ev) 0" >> $DEST_FSF.fsf
	echo "set fmri(convolve_phase$ev) 0" >> $DEST_FSF.fsf
	echo "set fmri(tempfilt_yn$ev) 0" >> $DEST_FSF.fsf
	echo "set fmri(deriv_yn$ev) 0" >> $DEST_FSF.fsf
	
	for (( x=0; x<=$NUM_ROIS; x++ ))
	do
		if [ $x -eq $ev ]; then
			echo "set fmri(ortho$ev.$x) 0" >> $DEST_FSF.fsf
		else
			echo "set fmri(ortho$ev.$x) 1" >> $DEST_FSF.fsf
		fi
	done
	

	row=2*$ev-1
	col=$ev
	echo "set fmri(con_real$row.$col) 1" >> $DEST_FSF.fsf
	echo "set fmri(con_orig$row.$col) 1" >> $DEST_FSF.fsf
	echo "set fmri(conpic_real.$row) 1" >> $DEST_FSF.fsf
	echo "set fmri(conpic_orig.$row) 1" >> $DEST_FSF.fsf
	echo "set fmri(conname_real.$row) c${col}_pos" >> $DEST_FSF.fsf
	echo "set fmri(conname_orig.$row) c${col}_pos" >> $DEST_FSF.fsf

	row=2*$ev
	echo "set fmri(con_real$row.$col) -1" >> $DEST_FSF.fsf
	echo "set fmri(con_orig$row.$col) -1" >> $DEST_FSF.fsf
	echo "set fmri(conpic_real.$row) 1" >> $DEST_FSF.fsf
	echo "set fmri(conpic_orig.$row) 1" >> $DEST_FSF.fsf
	echo "set fmri(conname_real.$row) c${col}_neg" >> $DEST_FSF.fsf
	echo "set fmri(conname_orig.$row) c${col}_neg" >> $DEST_FSF.fsf

}
# ===============================================================================
# check inputs
if [ -z $OUTPUT_DIR_NAME ]; then echo "ERROR, OUTPUT dir name ($OUTPUT_DIR_NAME) is empty.....exiting"; exit; fi
# ===============================================================================
DEST_FSF=$SBFC_DIR/feat_$OUTPUT_DIR_NAME
output_series_path=$SBFC_DIR/series
TOT_VOL_NUM=`fslnvols $input_rs_image`

cp $FSF_TEMPL_FILE.fsf $DEST_FSF.fsf
if [ ! -f $DEST_FSF.fsf ]; then echo "ERROR in creating dest fsf file.....exiting"; exit; fi

echo "" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "# init parameters" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
init_data
echo "################################################################" >> $DEST_FSF.fsf
echo "# overriding parameters" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "set fmri(multiple) 1" >> $DEST_FSF.fsf
echo "set fmri(npts) $TOT_VOL_NUM" >> $DEST_FSF.fsf
echo "set feat_files(1) $input_rs_image" >> $DEST_FSF.fsf
echo "set highres_files(1) $T1_BRAIN_DATA" >> $DEST_FSF.fsf
echo "set fmri(outputdir) $output_feat_dir" >> $DEST_FSF.fsf
echo "set fmri(regstandard) $FSL_DATA_STANDARD/MNI152_T1_2mm_brain" >> $DEST_FSF.fsf

echo "set fmri(evs_orig) $NUM_ROIS" >> $DEST_FSF.fsf
echo "set fmri(evs_real) $NUM_ROIS" >> $DEST_FSF.fsf

echo "set fmri(ncon_orig) $NUM_CONTRASTS" >> $DEST_FSF.fsf
echo "set fmri(ncon_real) $NUM_CONTRASTS" >> $DEST_FSF.fsf


# extract ROI timeseries & add file 2 model
declare -i cnt=1
for ROI_NAME in ${INPUT_ROI[@]}
do
	create_regressor_data $cnt

	output_serie=$output_series_path/$ROI_NAME"_ts"$SERIES_POSTFIX_NAME".txt"
	$FSLDIR/bin/fslmeants -i $input_rs_image -o $output_serie -m $INPUT_ROI_DIR/$ROI_NAME
	echo "set fmri(custom$cnt) $output_serie" >> $DEST_FSF.fsf
	
	cnt=$cnt+1
done

echo "subj:$SUBJ_NAME, starting ROI FEAT: ${INPUT_ROI[@]}"
$FSLDIR/bin/feat $DEST_FSF.fsf
$FSLDIR/bin/featregapply $output_feat_dir.feat	

