#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/data/MRI/projects/ELA 									#<<<<@@@@@@@@@@@@@@@
export FSLDIR=/usr/local/fsl																# change according to used PC
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
. $PROJ_SCRIPT_DIR/subjects_list.sh

thrPvalue=40
tbss_dir=$PROJ_GROUP_ANALYSIS_DIR/tbss/55subj_1

OUTPUT_DIR_NAME_l=l_cst_ped2mi_2wp_1s
OUTPUT_DIR_NAME_r=r_cst_ped2mi_2wp_1s
mask_thrp_file_name_r=mask_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.nii.gz
mask_thrp_file_name_l=mask_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.nii.gz

mkdir -p $tbss_dir/stats/cst/masks

mask_l=""; mask_r=""
declare -i num_subj=${#arr_ela_dti[@]}

for SUBJ_NAME in ${arr_ela_dti[@]}
do
	echo $SUBJ_NAME
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	
	# create mask of subjects' CST
	[ ! -f $ROI_DIR/reg_dti/$mask_thrp_file_name_l ] && $FSLDIR/bin/fslmaths $PROBTRACKX_DIR/$OUTPUT_DIR_NAME_l/fdt_paths_norm.nii.gz -thrP $thrPvalue $ROI_DIR/reg_dti/$mask_thrp_file_name_l

	[ ! -f $ROI_DIR/reg_dti/$mask_thrp_file_name_r ] && $FSLDIR/bin/fslmaths $PROBTRACKX_DIR/$OUTPUT_DIR_NAME_r/fdt_paths_norm.nii.gz -thrP $thrPvalue $ROI_DIR/reg_dti/$mask_thrp_file_name_r

	echo "calculating $SUBJ_NAME mean FA/MD/L1/L23 in CST"
	# calculate mean FA/MD/L1/L23 in CST
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_FA.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_l -o $ROI_DIR/reg_dti/FA_meants_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.txt
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_MD.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_l -o $ROI_DIR/reg_dti/MD_meants_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.txt
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_L1.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_l -o $ROI_DIR/reg_dti/L1_meants_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.txt
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_L23.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_l -o $ROI_DIR/reg_dti/L23_meants_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.txt
	
	
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_FA.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_r -o $ROI_DIR/reg_dti/FA_meants_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.txt
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_MD.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_r -o $ROI_DIR/reg_dti/MD_meants_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.txt	
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_L1.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_r -o $ROI_DIR/reg_dti/L1_meants_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.txt
	$FSLDIR/bin/fslmeants -i $DTI_DIR/$SUBJ_NAME-dtifit_L23.nii -m $ROI_DIR/reg_dti/$mask_thrp_file_name_r -o $ROI_DIR/reg_dti/L23_meants_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.txt	
	
done

#===========================================================================================================================
# collect subjects' FA & MD means and store in a single file for statistical analysis
mkdir -p $PROJ_GROUP_ANALYSIS_DIR/results
group_fa_means=$PROJ_GROUP_ANALYSIS_DIR/results/group_fa_means_P$thrPvalue.txt
group_md_means=$PROJ_GROUP_ANALYSIS_DIR/results/group_md_means_P$thrPvalue.txt
group_l1_means=$PROJ_GROUP_ANALYSIS_DIR/results/group_l1_means_P$thrPvalue.txt
group_l23_means=$PROJ_GROUP_ANALYSIS_DIR/results/group_l23_means_P$thrPvalue.txt

echo "subj	r_fa	l_fa" > $group_fa_means
echo "subj	r_md	l_md" > $group_md_means
echo "subj	r_l1	l_l1" > $group_l1_means
echo "subj	r_l23	l_l23" > $group_l23_means

for SUBJ_NAME in ${arr_ela_dti[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	wr=$(cat $ROI_DIR/reg_dti/FA_meants_$OUTPUT_DIR_NAME_l"_P$thrPvalue".txt | tr -d ' ') 
	wl=$(cat $ROI_DIR/reg_dti/FA_meants_$OUTPUT_DIR_NAME_r"_P$thrPvalue".txt | tr -d ' ') 
	echo "$SUBJ_NAME	$wr	$wl" >> $group_fa_means
	
	wr=$(cat $ROI_DIR/reg_dti/MD_meants_$OUTPUT_DIR_NAME_r"_P$thrPvalue".txt | tr -d ' ') 
	wl=$(cat $ROI_DIR/reg_dti/MD_meants_$OUTPUT_DIR_NAME_l"_P$thrPvalue".txt | tr -d ' ') 
	echo "$SUBJ_NAME	$wr	$wl" >> $group_md_means

	wr=$(cat $ROI_DIR/reg_dti/L1_meants_$OUTPUT_DIR_NAME_r"_P$thrPvalue".txt | tr -d ' ') 
	wl=$(cat $ROI_DIR/reg_dti/L1_meants_$OUTPUT_DIR_NAME_l"_P$thrPvalue".txt | tr -d ' ') 
	echo "$SUBJ_NAME	$wr	$wl" >> $group_l1_means

	wr=$(cat $ROI_DIR/reg_dti/L23_meants_$OUTPUT_DIR_NAME_r"_P$thrPvalue".txt | tr -d ' ') 
	wl=$(cat $ROI_DIR/reg_dti/L23_meants_$OUTPUT_DIR_NAME_l"_P$thrPvalue".txt | tr -d ' ') 
	echo "$SUBJ_NAME	$wr	$wl" >> $group_l23_means

done
#===========================================================================================================================


