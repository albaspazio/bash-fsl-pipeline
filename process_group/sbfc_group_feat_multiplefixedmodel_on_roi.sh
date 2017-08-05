#!/bin/bash
# ==================================================================================

Usage() {
    cat <<EOF
    
usage:	. $GLOBAL_GROUP_SCRIPT_DIR/sbfc_group_feat_multiplefixedmodel_on_roi.sh  path_to_fsf   /media/data/MRI/projects/colegios  -odp output_dir_root_path -ncope num_copes 1stlevel_feat_dirs

input:
1       		fsf model		 
2       		proj_dir	
-odp    		output root dir
-ncope  		num copes
-stdimg 		standard or study template
$X,$Y,$Z		input 1stlevel feat full path : contains the single subject feat folder for a specific roi(s)

output:
outputdir		output root dir/feat_ 1stlevel_feat_name _ fsfname	  
EOF
    exit 1
}

[ $# -lt 3 ] && Usage

# ====== set init params =============================================================================
FSF_TEMPLATE=$1; shift
PROJ_DIR=$1; shift


declare -i NUM_COPES=1
OUTPUT_ROOT_DIR=$PROJ_GROUP_ANALYSIS_DIR/sbfc/feat
STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
while [ ! -z "$1" ]
do
  case "$1" in
  
      -ncope) 	NUM_COPES=$2
      					shift;;
      						
      -odp) 		OUTPUT_ROOT_DIR=$2
								shift;;
									
      -stdimg) 	STANDARD_IMAGE=$2
      					if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit
								shift;;					
									
      *) 				break;;
  esac
  shift
done


#--------------------------------------------------------------------------------------------------------------------------
# remaining parameters are 1st_level_FEAT_SOURCEs...check them !
erroneous_sources=""
for FEAT_SOURCE in $@
do	
	if [ -d $FEAT_SOURCE.feat ]; then
		src=folder
	elif [ `$FSLDIR/bin/imtest $FEAT_SOURCE` = 1 ]; then 
		src=cope
	else
		erroneous_sources="$erroneous_sources::$FEAT_SOURCE"
	fi
done
if [ ! -z $erroneous_sources ]; then echo "the following input feat folders are missing: $erroneous_sources"; exit; fi

# get feat folder name, to create the output dir name
if [ $src == "folder" ]; then
	ROI_FEAT_FOLDER_NAME=$(basename $1)
	ROI_FEAT_FOLDER_NAME=$(remove_ext $ROI_FEAT_FOLDER_NAME)
else
	ROI_FEAT_FOLDER_NAME=$(dirname $1)
	ROI_FEAT_FOLDER_NAME=$(dirname $ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME=$(basename $ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME="${ROI_FEAT_FOLDER_NAME%.*}"
fi
#===================================================================================================================================================================================
templ_name=$(basename $FSF_TEMPLATE)

OUTPUT_DIR=$OUTPUT_ROOT_DIR/${ROI_FEAT_FOLDER_NAME}_${templ_name}
cp $FSF_TEMPLATE.fsf $OUTPUT_DIR.fsf	
	

echo "" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "# overriding parameters" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "set fmri(analysis) 2" >> $OUTPUT_DIR.fsf
echo "set fmri(ncopeinputs) $NUM_COPES" >> $OUTPUT_DIR.fsf
echo "set fmri(outputdir) $OUTPUT_DIR" >> $OUTPUT_DIR.fsf

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $OUTPUT_DIR.fsf; done
	
echo "set fmri(regstandard) $STANDARD_IMAGE" >> $OUTPUT_DIR.fsf

declare -i cnt=0
for FEAT_DIR in $@
do	
	cnt=$cnt+1
	echo "set feat_files($cnt) $FEAT_DIR.feat" >> $OUTPUT_DIR.fsf
done
echo "set fmri(npts) $cnt" >> $OUTPUT_DIR.fsf
echo "set fmri(multiple) $cnt" >> $OUTPUT_DIR.fsf


echo "starting GROUP FEAT with model: $templ_name on output $OUTPUT_DIR "
feat $OUTPUT_DIR.fsf

echo " finished rsfc_multiple_model_group_feat with template $FSF_TEMPLATE and output dir $OUTPUT_DIR"
