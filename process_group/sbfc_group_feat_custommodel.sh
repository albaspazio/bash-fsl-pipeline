#!/bin/bash
# ==================================================================================

Usage() {
    cat <<EOF
    
usage:	. $GLOBAL_GROUP_SCRIPT_DIR/sbfc_group_feat_multiplefilecolumnsmodel_on_roi.sh  path_to_fsf   /media/data/MRI/projects/colegios -odp output_dir_root_path -ncope num_copes -isubjf input_subject_variable_file_path 1stlevel_feat_dirs

what it does: 	do sbfc group analysis. you can provide a file containing several columns with various variables. 
				you can select which of them are covariate (having the corresponding contrasts) or nuisance variables (no contrasts associated)
				if you don't provide a subject file, it will create a group comparison stat model..but needs the -groupslastids input parameter

input:
1             	columnsids		 "c1,c2,c3|n1,n2,n3" | separated string....left side are covariates, right side are nuisance
2             	proj_dir	
-odp          	output root dir
-ncope        	num copes
-model        	path to fsf model
-isubjf       	input subject file
-groupslastids	groupslastids   comma-separated string contaning the ID of the last subject of each group. eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group
-stdimg 		standard or study template
$X,$Y,$Z		input 1stlevel feat full path : contains the single subject feat folder for a specific roi(s)

output:
outputdir		output root dir/feat_ 1stlevel_feat_name _ fsfname	  
EOF
    exit 1
}

[ $# -lt 3 ] && Usage


# ====== set init params =============================================================================
COLUMNS_IDS=$1; shift
PROJ_DIR=$1; shift

#--------------------------------------------
if [[ $INIT_VARS_DEFINED != 1 ]]; then
  . /media/data/MRI/script/init/init_vars.sh
fi
#--------------------------------------------
OUTPUT_ROOT_DIR=$PROJ_GROUP_ANALYSIS_DIR/sbfc
SUBJECT_VARIABLE_FILE=""
groupslastids=""			# comma-separated string contaning the ID of the last subject of each group.
							# eg: 3 groups  "18,38,52" = 1-18: first group, 19-38: second group, 39-52: third group
declare -i NUM_GROUPS=1 	# derived from groupslastids, store the number of groups in the design. each group will have its regressor (EV). 
 							# covariates/nuisance regressors will be appended starting from the (NUM_GROUPS+1)th column_id													
multiple_groups_string=""	# string to be passed to create_Ncov_Xnuisance_glm_file that contain the -groupslastids option
STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
declare -i NUM_COPES=0

while [ ! -z "$1" ]
do
  case "$1" in
  
  	-model)			TEMPLATE_GLM_FSF=$2
  					shift;;
  		
    -ncope) 		NUM_COPES=$2
      				shift;;
      					
    -odp) 			OUTPUT_ROOT_DIR=$2
					shift;;
								
	-isubjf)		SUBJECT_VARIABLE_FILE=$2
					shift;;
										
	-groupslastids)	groupslastids=$2
					shift;;										
			
    -stdimg) 		STANDARD_IMAGE=$2
      				if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit; fi
					shift;;		
															
    *) 				break;;
  esac
  shift
done

if [ ! -z $SUBJECT_VARIABLE_FILE ]; then
	if [ -z $COLUMNS_IDS ]; then
		echo "error in $0 ....input subject file ($SUBJECT_VARIABLE_FILE) is filled, but COLUMNS_IDS ($COLUMNS_IDS) is empty"
	fi
fi


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
# STATS variables (EVs, contrasts, according to subjects file and covariate/nuisance ids/groupslastids)

# considering that several processes may attempt to use the same template file and append different combinations of stats and feat folder data..
# we create a random number and pass it to the create_Ncov_Xnuisance_glm_file.sh function in order to always create an unique GLM file
rndname=$(( $RANDOM % (100000 + 1 - 1) + 1 ))


if [ ! -z $SUBJECT_VARIABLE_FILE ]; then
	OUTPUT_GLM_FSF="" 											# name is written by create_Ncov_Xnuisance_glm_file
	if [ ! -z $groupslastids ]; then
		multiple_groups_string=" -groupslastids $groupslastids"
	fi
	. $GLOBAL_GLM_SCRIPT_DIR/create_Ncov_Xnuisance_glm_file.sh $PROJ_DIR -covids $COVARIATE_COLUMNS -nuisids $NUISANCE_COLUMNS -isubjf $SUBJECT_VARIABLE_FILE -model $TEMPLATE_GLM_FSF -odp $OUTPUT_ROOT_DIR -rndname $rndname $multiple_groups_string

	templ_name=$(basename $OUTPUT_GLM_FSF)
	templ_name=${templ_name%.fsf}
	new_templ_name=${templ_name/$rndname/};  # I remove the random number	
else
	OUTPUT_GLM_FSF=$TEMPLATE_GLM_FSF
	new_templ_name=$(basename $OUTPUT_GLM_FSF)
	new_templ_name=${new_templ_name%.fsf}
fi

FINAL_OUTPUT_DIR=$OUTPUT_ROOT_DIR/$feat_folder_name"_"$new_templ_name
DEST_FSF=$OUTPUT_ROOT_DIR/$feat_folder_name"_"$new_templ_name.fsf
mv $OUTPUT_GLM_FSF $DEST_FSF

# remove all GLM generated files
rm $OUTPUT_ROOT_DIR/*$templ_name*
#--------------------------------------------------------------------------------------------------------------------------


echo "" >> $DEST_FSF
echo "################################################################" >> $DEST_FSF
echo "# overriding parameters" >> $DEST_FSF
echo "################################################################" >> $DEST_FSF
echo "set fmri(analysis) 2" >> $DEST_FSF
echo "set fmri(ncopeinputs) $NUM_COPES" >> $DEST_FSF

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $DEST_FSF; done
	
echo "set fmri(regstandard) \"$STANDARD_IMAGE\"" >> $DEST_FSF

declare -i cnt=0
for FEAT_SOURCE in $@
do	
	cnt=$cnt+1
	echo "set feat_files($cnt) \"$FEAT_SOURCE\"" >> $DEST_FSF
done
echo "set fmri(npts) $cnt" >> $DEST_FSF
echo "set fmri(multiple) $cnt" >> $DEST_FSF
echo "set fmri(outputdir) \"$FINAL_OUTPUT_DIR\"" >> $DEST_FSF


echo "starting GROUP FEAT with model: $templ_name on output $FINAL_OUTPUT_DIR"
$FSLDIR/bin/feat $DEST_FSF

echo " finished rsfc_multiple_model_group_feat with template $FSF_TEMPLATE and output dir $FINAL_OUTPUT_DIR"
