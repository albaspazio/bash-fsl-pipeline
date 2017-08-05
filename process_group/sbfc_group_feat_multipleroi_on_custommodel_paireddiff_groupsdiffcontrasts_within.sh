#!/bin/bash
# ==================================================================================

Usage() {
    cat <<EOF
    
usage:	. $GLOBAL_GROUP_SCRIPT_DIR/sbfc_group_feat_multipleroi_on_custommodel_paireddiff.sh  feat_folder_name   /media/data/MRI/projects/colegios -odp output_dir_root_path -ncope num_copes -nsubj num_subj 1stlevel_feat_dirs

input:
1       	1st level feat folder name	
2         proj_dir	
-odp      output root dir
-odn			output dir name
-ncope    num copes
-model    path to fsf model
-nsubj    input subject file
-stdimg 	standard or study template
$X,$Y,$Z	input 1stlevel feat root path : contains single-subject feat root folder of several roi(s) analysis

output:
outputdir		output root dir/feat_ 1stlevel_feat_name _ fsfname	  
EOF
    exit 1
}

[ $# -lt 3 ] && Usage


# ====== set init params =============================================================================
ROI_FEAT_FOLDER_NAME=$1; shift
PROJ_DIR=$1; shift

#--------------------------------------------
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#--------------------------------------------
OUTPUT_ROOT_DIR=$PROJ_GROUP_ANALYSIS_DIR/sbfc
declare -i NUM_SUBJ=0 		# if 0, accept the input fsf as is, otherwise call the glm script to create a new one according to subject number
STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
declare -i NUM_COPES=1
GROUPSLASTSIDS=""					# comma-separated string contaning the ID of the last subject of each group.
													# eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group		
OUTPUT_DIR_NAME=""													

while [ ! -z "$1" ]
do
  case "$1" in
  
  		-model)						TEMPLATE_GLM_FSF=$2
  											shift;;
  		
      -ncope) 					NUM_COPES=$2
      									shift;;
      					
      -odp) 						OUTPUT_ROOT_DIR=$2
												shift;;
												
      -odn) 						OUTPUT_DIR_NAME=$2
												shift;;												
								
			-groupslastids)		GROUPSLASTSIDS=$2  # cannot be empty
												shift;;	
										
      -stdimg) 					STANDARD_IMAGE=$2
      									if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit; fi
												shift;;		
															
      *) 								break;;
  esac
  shift
done

#--------------------------------------------------------------------------------------------------------------------------
# remaining parameters are 1st_level_FEAT_SOURCEs...check them !
erroneous_sources=""
for FEAT_SOURCE in $@
do	
	if [ -d $FEAT_SOURCE$ROI_FEAT_FOLDER_NAME.feat ]; then
		src=folder
	elif [ `$FSLDIR/bin/imtest $FEAT_SOURCE$ROI_FEAT_FOLDER_NAME` = 1 ]; then 
		src=cope
	else
		erroneous_sources="$erroneous_sources::$FEAT_SOURCE$ROI_FEAT_FOLDER_NAME"
	fi
done
if [ ! -z $erroneous_sources ]; then echo "the following input feat folders are missing: $erroneous_sources"; exit; fi

# get feat folder name, to create the output dir name
if [ "$src" == "folder" ]; then
	ROI_FEAT_FOLDER_NAME=$(basename $1$ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME=$(remove_ext $ROI_FEAT_FOLDER_NAME)
else
	ROI_FEAT_FOLDER_NAME=$(dirname $1$ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME=$(dirname $ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME=$(basename $ROI_FEAT_FOLDER_NAME)
	ROI_FEAT_FOLDER_NAME="${ROI_FEAT_FOLDER_NAME%.*}"
fi
#===================================================================================================================================================================================
templ_name=$(basename $TEMPLATE_GLM_FSF)

#echo ======================= $ROI_FEAT_FOLDER_NAME

#--------------------------------------------------------------------------------------------------------------------------
# STATS variables (EVs, contrasts, according to subjects file and covariate/nuisance ids/groupslastids)

# considering that several processes may attempt to use the same template file and append different combinations of stats and feat folder data..
# we create a random number and pass it to the create_Ncov_Xnuisance_glm_file.sh function in order to always create an unique GLM file
rndname=$(( $RANDOM % (100000 + 1 - 1) + 1 ))


if [ ! -z $GROUPSLASTSIDS ]; then
	OUTPUT_GLM_FSF="" 											# name is written by glm script
	. $GLOBAL_GLM_SCRIPT_DIR/create_2group_2sessions_paired_diff_within_glm.sh $PROJ_DIR -groupslastids $GROUPSLASTSIDS -model $TEMPLATE_GLM_FSF -odp $OUTPUT_ROOT_DIR -rndname $rndname

	templ_name=$(basename $OUTPUT_GLM_FSF)
	templ_name=${templ_name%.fsf}
	new_templ_name=${templ_name/$rndname/};  # I remove the random number	
	new_templ_name=${new_templ_name}_s$NUM_SUBJ
else
	OUTPUT_GLM_FSF=$TEMPLATE_GLM_FSF
	new_templ_name=$(basename $OUTPUT_GLM_FSF)
	new_templ_name=${new_templ_name%.fsf}
fi

OUTPUT_DIR=$OUTPUT_ROOT_DIR/${ROI_FEAT_FOLDER_NAME}_${new_templ_name}$OUTPUT_DIR_NAME
mv $OUTPUT_GLM_FSF $OUTPUT_DIR.fsf

# remove all GLM generated files
rm $OUTPUT_ROOT_DIR/*$rndname*

#--------------------------------------------------------------------------------------------------------------------------


echo "" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "# overriding parameters" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "set fmri(analysis) 2" >> $OUTPUT_DIR.fsf
echo "set fmri(mixed_yn) 2" >> $OUTPUT_DIR.fsf   # FIXED EFFECT ANALYSIS
echo "set fmri(ncopeinputs) $NUM_COPES" >> $OUTPUT_DIR.fsf

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $OUTPUT_DIR.fsf; done
	
echo "set fmri(regstandard) \"$STANDARD_IMAGE\"" >> $OUTPUT_DIR.fsf

declare -i cnt=0
for FEAT_SOURCE in $@
do	
	cnt=$cnt+1
	if [ "$src" == "folder" ]; then
		echo "set feat_files($cnt) \"$FEAT_SOURCE$ROI_FEAT_FOLDER_NAME.feat\"" >> $OUTPUT_DIR.fsf
	else
		echo "set feat_files($cnt) \"$FEAT_SOURCE$ROI_FEAT_FOLDER_NAME\"" >> $OUTPUT_DIR.fsf
	fi
		
done
echo "set fmri(npts) $cnt" >> $OUTPUT_DIR.fsf
echo "set fmri(multiple) $cnt" >> $OUTPUT_DIR.fsf
echo "set fmri(outputdir) \"$OUTPUT_DIR\"" >> $OUTPUT_DIR.fsf


echo "starting GROUP FEAT with model: ${ROI_FEAT_FOLDER_NAME}_${new_templ_name} on output $OUTPUT_DIR"
$FSLDIR/bin/feat $OUTPUT_DIR.fsf

echo " finished rsfc_multiple_model_group_feat with template ${ROI_FEAT_FOLDER_NAME}_${new_templ_name} and output dir $OUTPUT_DIR"
