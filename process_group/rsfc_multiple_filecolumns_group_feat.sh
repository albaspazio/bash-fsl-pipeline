#!/bin/bash

# ==================================================================================
# usage:	. ./path/rsfc_multiple_model_group_feat.sh path/templ.fsf /path/proj_dir 
# ==================================================================================
# input:
#		$1					columnsids		 "c1,c2,c3|n1,n2,n3" | separated string....left side are covariates, right side are nuisance
#	  $2					proj_dir	
#   -odp  			output dir
#   -ncope  		num copes
# 	-isubjf			input subject file
#		-model			fsf template path

#   $5,$6...  input 1stlevel feat dir

# ===== check parameters ==============================================================================
#echo $@


str_usage="Usage: $0 columnsids proj_dir -odp output_dir_name -ncope num_copes -isubjf input_subject_variable_file_path 1stlevel_feat_dirs"

# ====== set init params =============================================================================
COLUMNS_IDS=$1; shift
PROJ_DIR=$1; shift

#--------------------------------------------
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#--------------------------------------------
OUTPUT_ROOT_DIR=$PROJ_GROUP_ANALYSIS_DIR/sbfc
INPUT_SUBJECT_VARIABLE_FILE=""
NUISANCE_COLUMNS=""
COVARIATE_COLUMNS=""
STANDARD_IMAGE=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain.nii.gz
declare -i NUM_COPES=0

while [ ! -z "$1" ]
do
  case "$1" in
  
  		-model)				TEMPLATE_GLM_FSF=$2
  									shift;;
  		
      -ncope) 			NUM_COPES=$2
      							shift;;
      					
      -odp) 				OUTPUT_ROOT_DIR=$2
										shift;;
								
			-isubjf)			INPUT_SUBJECT_VARIABLE_FILE=$2
										shift;;
			
      -stdimg) 			STANDARD_IMAGE=$2
      							if [ ! -f $STANDARD_IMAGE ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit; fi
										shift;;					
      *) break;;
  esac
  shift
done

if [ ! -z $INPUT_SUBJECT_VARIABLE_FILE ]; then
	if [ -z $COLUMNS_IDS ]; then
		echo "error in $0 ....input subject file ($INPUT_SUBJECT_VARIABLE_FILE) is filled, but COLUMNS_IDS ($COLUMNS_IDS) is empty"
	fi
fi


#--------------------------------------------------------------------------------------------------------------------------
# remaining parameters are 1st_level_feat_dirs...check them !
erroneous_folders=""
for FEAT_DIR in $@
do	
	if [ ! -d $FEAT_DIR.feat ]; then 
		erroneous_folders="$erroneous_folders::$FEAT_DIR.feat"
	fi
done
if [ ! -z $erroneous_folders ]; then echo "the following input feat folders are missing: $erroneous_folders"; return; fi

# get feat folder name, to create the output dir name
feat_folder_name=$(basename $1)
feat_folder_name=$(remove_ext $feat_folder_name)

#--------------------------------------------------------------------------------------------------------------------------
# split COLUMNS_IDS into two strings
OLDIFS=$IFS
IFS="|"
declare -a arr_col_ids=($COLUMNS_IDS)

COVARIATE_COLUMNS=${arr_col_ids[0]}
NUISANCE_COLUMNS=${arr_col_ids[1]}

if [ -z $COVARIATE_COLUMNS ]; then COVARIATE_COLUMNS="0"; fi
if [ -z $NUISANCE_COLUMNS ]; then NUISANCE_COLUMNS="0"; fi

IFS=$OLDIFS

#--------------------------------------------------------------------------------------------------------------------------
# first write STATS variables (EVs, contrasts, according to subjects file and covariate/nuisance ids)

# considering that several processes may attempt to use the same template file and append different combinations of stats and feat folder data..
# we create a random number and pass it to the create_Ncov_Xnuisance_glm_file.sh function in order to create an unique GLM file
rndname=$(( $RANDOM % (100000 + 1 - 1) + 1 ))


OUTPUT_GLM_FSF=""
if [ ! -z $INPUT_SUBJECT_VARIABLE_FILE ]; then
	. $GLOBAL_GLM_SCRIPT_DIR/create_Ncov_Xnuisance_glm_file.sh $PROJ_DIR -covids $COVARIATE_COLUMNS -nuisids $NUISANCE_COLUMNS -isubjf $INPUT_SUBJECT_VARIABLE_FILE -model $TEMPLATE_GLM_FSF -odp $OUTPUT_ROOT_DIR -rndname $rndname
fi

templ_name=$(basename $OUTPUT_GLM_FSF)
templ_name=${templ_name%.fsf}
new_templ_name=${templ_name/$rndname/};  # I remove the random number

FINAL_OUTPUT_DIR=$OUTPUT_ROOT_DIR/$feat_folder_name"_"$new_templ_name

DEST_FSF=$OUTPUT_ROOT_DIR/$feat_folder_name"_"$new_templ_name.fsf


mv $OUTPUT_GLM_FSF $DEST_FSF

# remove all GLM generated files
rm $OUTPUT_ROOT_DIR/*$templ_name*


echo "" >> $DEST_FSF
echo "################################################################" >> $DEST_FSF
echo "# overriding parameters" >> $DEST_FSF
echo "################################################################" >> $DEST_FSF
echo "set fmri(analysis) 2" >> $DEST_FSF
echo "set fmri(ncopeinputs) $NUM_COPES" >> $DEST_FSF

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $DEST_FSF; done
	
echo "set fmri(regstandard) \"$STANDARD_IMAGE\"" >> $DEST_FSF

declare -i cnt=0
for FEAT_DIR in $@
do	
	cnt=$cnt+1
	echo "set feat_files($cnt) \"$FEAT_DIR.feat\"" >> $DEST_FSF
done
echo "set fmri(npts) $cnt" >> $DEST_FSF
echo "set fmri(multiple) $cnt" >> $DEST_FSF



echo "set fmri(outputdir) \"$FINAL_OUTPUT_DIR\"" >> $DEST_FSF


echo "starting GROUP FEAT with model: $templ_name on output $FINAL_OUTPUT_DIR"
$FSLDIR/bin/feat $DEST_FSF

echo " finished rsfc_multiple_model_group_feat with template $FSF_TEMPLATE and output dir $FINAL_OUTPUT_DIR"
