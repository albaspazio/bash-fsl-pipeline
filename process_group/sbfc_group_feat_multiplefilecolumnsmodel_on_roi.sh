#!/bin/bash
# ==================================================================================

Usage() {
    cat <<EOF
    
usage:	. $GLOBAL_GROUP_SCRIPT_DIR/sbfc_group_feat_multiplefilecolumnsmodel_on_roi.sh "1|3,4" /media/data/MRI/projects/XXXX 
								-odp output_dir_root_path -ncope num_copes -model path/2/fsf/file -isubjf input_subject_variable_file_path -groupslastids "18,38,52" -stdimg  /path/2/alternative/stdimg 1stlevel_feat_dirs

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
-stdimg 				standard or study template
-nofeat					does not start feat
$X,$Y,$Z				1stlevel feat full path : contains the single subject feat folder for a specific roi(s)

output:
outputdir		output root dir/feat_ 1stlevel_feat_name _ fsfname		  
EOF
    exit 1
}

[ $# -lt 3 ] && Usage

# echo $@
# ====== set init params =============================================================================
COLUMNS_IDS=$1; shift
PROJ_DIR=$1; shift


# echo $@
# exit
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
DOUBLE_MEAN_CONTRASTS=""	# to be passed to create_Ncov_Xnuisance_glm_file: if 1, create a -1 contrast for each 1 contrast of the mean.
ROI_FEAT_FOLDER_NAME=""
STANDARD_IMAGE=$FSL_STANDARD_MNI_2mm
MASK_IMAGE=""
declare -i NUM_COPES=0
DO_FEAT=1
while [ ! -z "$1" ]
do
  case "$1" in
  
  	-model)			TEMPLATE_GLM_FSF=$2
  					shift;;
  		
    -ncope) 		NUM_COPES=$2
      				shift;;
      					
    -odp) 			OUTPUT_ROOT_DIR=$2
					shift;;
												
	-odn)			ROI_FEAT_FOLDER_NAME=$2
					shift;;
								
	-isubjf)		SUBJECT_VARIABLE_FILE=$2
					shift;;
										
	-groupslastids)	groupslastids=$2
					shift;;							
												
	-dblcon)		DOUBLE_MEAN_CONTRASTS=$2
					shift;;			
			
    -stdimg) 		STANDARD_IMAGE=$2
      				if [ `$FSLDIR/bin/imtest $STANDARD_IMAGE` = 0 ]; then echo "custom standard image ($STANDARD_IMAGE) non present....exiting "; exit; fi
					shift;;		
			
    -maskimg)		MASK_IMAGE=$2
      				if [ `$FSLDIR/bin/imtest $MASK_IMAGE` = 0 ]; then echo "mask image ($MASK_IMAGE) specified but non present....exiting "; exit; fi
					shift;;													
			
	-nofeat)		DO_FEAT=0;;
															
      *) 			break;;
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
src="folder"
erroneous_sources=""
for FEAT_SOURCE in $@
do	

	if [ -d $FEAT_SOURCE.feat ]; then
		src="folder"
	elif [ `$FSLDIR/bin/imtest $FEAT_SOURCE` = 1 ]; then 
		src="cope"
	else
		erroneous_sources="$erroneous_sources::$FEAT_SOURCE"
	fi
done
if [ ! -z $erroneous_sources ]; then echo "the following input feat folders are missing: $erroneous_sources"; return; fi

# get feat folder name, to create the output dir name
if [ -z $ROI_FEAT_FOLDER_NAME ]; then
	if [ $src == "folder" ]; then
		ROI_FEAT_FOLDER_NAME=$(basename $1)
		ROI_FEAT_FOLDER_NAME=$(remove_ext $ROI_FEAT_FOLDER_NAME)
	else
		ROI_FEAT_FOLDER_NAME=$(dirname $1)
		ROI_FEAT_FOLDER_NAME=$(dirname $ROI_FEAT_FOLDER_NAME)
		ROI_FEAT_FOLDER_NAME=$(basename $ROI_FEAT_FOLDER_NAME)
		ROI_FEAT_FOLDER_NAME="${ROI_FEAT_FOLDER_NAME%.*}"
	fi
fi
#===================================================================================================================================================================================



#--------------------------------------------------------------------------------------------------------------------------
# split COLUMNS_IDS into two strings

NUISANCE_COLUMNS=""
COVARIATE_COLUMNS=""

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

if [ ! -z $groupslastids ]; then
	multiple_groups_string=" -groupslastids $groupslastids"
fi

if [ ! -z $DOUBLE_MEAN_CONTRASTS ]; then
	double_mean_contrasts_string=" -dblcon"
fi	

# considering that several processes may attempt to use the same template file and append different combinations of stats and feat folder data..
# we create a random number and pass it to the create_Ncov_Xnuisance_glm_file.sh function in order to always create an unique GLM file
rndname=$(( $RANDOM % (100000 + 1 - 1) + 1 ))
OUTPUT_GLM_FSF="" 											# this variable is written by glm script

# if i have the subjects file, fill covariate and nuisance values, otherwise create a simple group comparisons
if [ ! -z $SUBJECT_VARIABLE_FILE ]; then
	. $GLOBAL_GLM_SCRIPT_DIR/create_Ncov_Xnuisance_glm_file.sh $PROJ_DIR -covids $COVARIATE_COLUMNS -nuisids $NUISANCE_COLUMNS -isubjf $SUBJECT_VARIABLE_FILE -model $TEMPLATE_GLM_FSF -odp $OUTPUT_ROOT_DIR -rndname $rndname $double_mean_contrasts_string $multiple_groups_string 
	
else

	if [ -z $groupslastids ]; then
		echo "ERROR in $0 : you didn't specify neither a subject file nor the composition of the group(s)...I cannot continue....exiting."
		exit
	fi
	. $GLOBAL_GLM_SCRIPT_DIR/create_Mgroups_glm.sh $PROJ_DIR -model $TEMPLATE_GLM_FSF -odp $OUTPUT_ROOT_DIR -rndname $rndname $double_mean_contrasts_string $multiple_groups_string 
	
fi
templ_name=$(basename $OUTPUT_GLM_FSF)
templ_name=${templ_name%.fsf}
new_templ_name=${templ_name/$rndname/};  # I remove the random number	

OUTPUT_DIR=$OUTPUT_ROOT_DIR/${ROI_FEAT_FOLDER_NAME}_${new_templ_name}
mv $OUTPUT_GLM_FSF $OUTPUT_DIR.fsf

# remove all GLM generated files
rm $OUTPUT_ROOT_DIR/*$rndname*
#--------------------------------------------------------------------------------------------------------------------------


echo "" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "# overriding parameters" >> $OUTPUT_DIR.fsf
echo "################################################################" >> $OUTPUT_DIR.fsf
echo "set fmri(analysis) 2" >> $OUTPUT_DIR.fsf
echo "set fmri(ncopeinputs) $NUM_COPES" >> $OUTPUT_DIR.fsf

if [ $src == "folder" ]; then
	echo "set fmri(inputtype) 1" >> $OUTPUT_DIR.fsf		# 1 : Inputs are lower-level FEAT directories
else
	echo "set fmri(inputtype) 2" >> $OUTPUT_DIR.fsf		# 2 : Inputs are cope images from FEAT directories
fi

for (( x=1; x<=$NUM_COPES; x++ )); do	echo "set fmri(copeinput.$x) 1" >> $OUTPUT_DIR.fsf; done
	
echo "set fmri(regstandard) \"$STANDARD_IMAGE\"" >> $OUTPUT_DIR.fsf

declare -i cnt=0
for FEAT_SOURCE in $@
do	
	cnt=$cnt+1
	if [ $src == "folder" ]; then
		echo "set feat_files($cnt) \"$FEAT_SOURCE.feat\"" >> $OUTPUT_DIR.fsf
	else
		echo "set feat_files($cnt) \"$FEAT_SOURCE\"" >> $OUTPUT_DIR.fsf
	fi
done
echo "set fmri(npts) $cnt" >> $OUTPUT_DIR.fsf
echo "set fmri(multiple) $cnt" >> $OUTPUT_DIR.fsf
echo "set fmri(outputdir) \"$OUTPUT_DIR\"" >> $OUTPUT_DIR.fsf

if [ ! -z $MASK_IMAGE ]; then
	echo "set fmri(threshmask) 	\"$MASK_IMAGE\"" >> $OUTPUT_DIR.fsf
fi

echo "starting GROUP FEAT with model: ${ROI_FEAT_FOLDER_NAME}_${new_templ_name} on output $OUTPUT_DIR"
if [ $DO_FEAT -eq 1 ]; then $FSLDIR/bin/feat $OUTPUT_DIR.fsf; fi

echo " finished rsfc_multiple_model_group_feat with template ${ROI_FEAT_FOLDER_NAME}_${new_templ_name} and output dir $OUTPUT_DIR"

