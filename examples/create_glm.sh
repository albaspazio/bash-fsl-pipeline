# ==================================================================================
#!/bin/bash

GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_script_new
PROJ_DIR=/gnappo/home1/dati/BELGRADO_1.5Philips/DYT
. use_fsl 5.0.9											
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1


OUTPUT_ROOT_GLM_FOLDER=$PROJ_GROUP_ANALYSIS_DIR/glm_models
SCRIPT_NAME=$GLOBAL_GLM_SCRIPT_DIR/create_Ncov_Xnuisance_glm_file.sh  # 


# ==================================================================================
#VARIABLE

input_variables_file=$PROJ_DIR/data.txt

#1		2		3				4							5									6						7			8				9				10					11						12					13						14					15						16						17
#subj	age	gender	PT_vocab_kbit	PT_matrices_kbit	PT_CI_kbit	CSOT	FW_DIG	BW_DIG	edadestc_TM	cursoestc_TM	edadestf_TM	cursoestf_TM	edadestp_TM	cursoestp_TM	edadestcom_TM	cursoestcon_TM


population_name=ttest
input_template_file_name=test_2subj.fsf

# ==================================================================================
#DERIVED

OUTPUT_GLM_FOLDER=$OUTPUT_ROOT_GLM_FOLDER/$population_name
INPUT_TEMPLATE_FILE=$PROJ_SCRIPT_DIR/glm/templates/$input_template_file_name

mkdir -p $OUTPUT_GLM_FOLDER
# ==================================================================================

nuisance_columns="2,3"
covariate_columns="4,5"; . $SCRIPT_NAME $PROJ_DIR -covids $covariate_columns -nuisids $nuisance_columns -isubjf $input_variables_file -model $INPUT_TEMPLATE_FILE -odp $OUTPUT_GLM_FOLDER


