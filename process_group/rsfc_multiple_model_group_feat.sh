# ==================================================================================
# usage:	. ./path/rsfc_confounds_feat.sh 003 /media/data/MRI/projects/colegios 
# ==================================================================================
#!/bin/bash
# ==================================================================================
# input:
#		$1	fsf model		 
#	  $2	proj_dir	
#   $3  output dir
#   $4  num copes
#   $5,$6...  input 1stlevel feat dir

# ===== check parameters ==============================================================================

str_usage="Usage: $0 fsf_model proj_dir -o output_dir_name -c num_copes 1stlevel_feat_dirs"

# ====== set init params =============================================================================
FSF_TEMPLATE=$1; shift
PROJ_DIR=$1; shift

STANDARD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain.nii.gz
declare -i NUM_COPES=0

while [ ! -z "$1" ]
do
  case "$1" in
      -ncope) NUM_COPES=$2
      		shift;;
      -odp) OUTPUT_DIR=$2
					shift;;
      -stdimg) STANDARD_IMAGE=$2
      		if [ ! -f $STANDARD_IMAGE ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit
					shift;;					
      *) break;;
  esac
  shift
done

# remaining parameters are 1st_level_feat_dirs
#===================================================================================================================================================================================
# extract ROI timeseries

templ_name=$(basename $FSF_TEMPLATE)
DEST_FSF=$PROJ_GROUP_ANALYSIS_DIR/rsfc/$templ_name
cp $FSF_TEMPLATE.fsf $DEST_FSF.fsf	
	

echo "" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "# overriding parameters" >> $DEST_FSF.fsf
echo "################################################################" >> $DEST_FSF.fsf
echo "set fmri(analysis) 6" >> $DEST_FSF.fsf
echo "set fmri(ncopeinputs) $NUM_COPES" >> $DEST_FSF.fsf
echo "set fmri(outputdir) $OUTPUT_DIR"_"$templ_name" >> $DEST_FSF.fsf

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $DEST_FSF.fsf; done
	
echo "set fmri(regstandard) $STANDARD_IMAGE" >> $DEST_FSF.fsf

declare -i cnt=0
for FEAT_DIR in $@
do	
	cnt=$cnt+1
	echo "set feat_files($cnt) $FEAT_DIR.feat" >> $DEST_FSF.fsf
done
echo "set fmri(npts) $cnt" >> $DEST_FSF.fsf
echo "set fmri(multiple) $cnt" >> $DEST_FSF.fsf


echo "starting GROUP FEAT with model: $templ_name on output $OUTPUT_DIR "
feat $DEST_FSF.fsf

echo " finished rsfc_multiple_model_group_feat with template $FSF_TEMPLATE and output dir $OUTPUT_DIR"
