# ==================================================================================
# usage:	. ./path/rsfc_multiple_roi_group_feat.sh 003 /media/data/MRI/projects/colegios 
# ==================================================================================
#!/bin/bash
# ==================================================================================
# input:
#		$1	roi_feat_dir		 
#	  $2	proj_dir	
#   -odn  output dir
#   -ncope  num copes
# 	-model	fsf file name
#   $5,$6...  input 1stlevel feat root folder ( /.../projX/subjects/$SUBJ_NAME/rs/rsfc/feat/  )

# ===== check parameters ==============================================================================

str_usage="Usage: $0 roi_feat_folder_name proj_dir -model fsf_template -odn output_dir_name -ncope num_copes 1stlevel_feat_dirs_root"


# ====== set init params =============================================================================
ROI_FEAT_FOLDER=$1; shift
PROJ_DIR=$1; shift

STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
declare -i NUM_COPES=0
OUTPUT_DIR_ROOT=$PROJ_GROUP_ANALYSIS_DIR/sbfc/feat
while [ ! -z "$1" ]
do
  case "$1" in
  		-model) FSF_TEMPLATE=$2
  				shift;;
      -ncope) NUM_COPES=$2
      		shift;;
      -odn) OUTPUT_DIR_ROOT=$2
					shift;;
      -stdimg) STANDARD_IMAGE=$2
      		if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit
					shift;;					
      *) break;;
  esac
  shift
done

# remaining parameters are 1st_level_feat_dirs
# ===============================================================================

templ_name=$(basename $FSF_TEMPLATE)



OUTPUT_DIR=$OUTPUT_DIR_ROOT/$ROI_FEAT_FOLDER"_"$templ_name

DEST_FSF=$OUTPUT_DIR_ROOT/$ROI_FEAT_FOLDER"_"$templ_name
cp $FSF_TEMPLATE.fsf $DEST_FSF.fsf	
	

echo "" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "# overriding parameters" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "set fmri(analysis) 2" >> $DEST_FSF.fsf
echo "set fmri(ncopeinputs) $NUM_COPES" >> $DEST_FSF.fsf
echo "set fmri(outputdir) $OUTPUT_DIR_ROOT/${ROI_FEAT_FOLDER}_${templ_name}" >> $DEST_FSF.fsf

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $DEST_FSF.fsf; done
	
echo "set fmri(regstandard) $STANDARD_IMAGE" >> $DEST_FSF.fsf

declare -i cnt=0
for FEAT_DIR in $@
do	
	cnt=$cnt+1
	echo "set feat_files($cnt) $FEAT_DIR/$ROI_FEAT_FOLDER.feat" >> $DEST_FSF.fsf
done
echo "set fmri(npts) $cnt" >> $DEST_FSF.fsf
echo "set fmri(multiple) $cnt" >> $DEST_FSF.fsf


echo "starting GROUP FEAT with model: $templ_name on output $OUTPUT_DIR "
feat $DEST_FSF.fsf

echo " finished rsfc_multiple_model_group_feat with template $FSF_TEMPLATE and output dir $OUTPUT_DIR"
