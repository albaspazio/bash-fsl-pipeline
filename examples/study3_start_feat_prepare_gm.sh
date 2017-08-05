#!/bin/bash

WORK_IN_CAB=0
# ====== init params ===========================
if [ $WORK_IN_CAB -eq 0 ]
then
	GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
	PROJ_DIR=/media/data/MRI/projects/CAB/STUDY_AD_FTD
else
	GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts
	PROJ_DIR=/media/Iomega_HDD/CAB/STUDY_AD_FTD
fi


#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================


#===============================================
analysis_name=controls_AD_FTD

. $PROJ_SCRIPT_DIR/subjects_list.sh

FEAT_GM_OUTPUT_DIR=$PROJ_GROUP_ANALYSIS_DIR/feat_gm 
filelist=$FEAT_GM_OUTPUT_DIR/.filelist_$analysis_name
SUBJECTS_INPUT_DIR_NAME=rs
SUBJECTS_INPUT_NAME=rs

mkdir -p $FEAT_GM_OUTPUT_DIR


if [ $WORK_IN_CAB -eq 0 ]
then
	CTRL_SUBJECTS_DIR=/media/data/MRI/projects/CAB/controls_cab/subjects
	AD_SUBJECTS_DIR=/media/data/MRI/projects/CAB/AD/subjects
	FTD_SUBJECTS_DIR=/media/data/MRI/projects/CAB/FTD/subjects
else
	SUBJECTS_DIR=/media/data/MRI/projects/CAB/controls_cab/subjects
	SUBJECTS_DIR=/media/data/MRI/projects/CAB/AD/subjects
	SUBJECTS_DIR=/media/Iomega_HDD/CAB/projects/FTD/subjects
fi


GMlist_std4=""
GMlist_std2=""
#=============================================================================================================================
for subj in ${arr_controls30[@]}
do
	GMlist_std4="$GMlist_std4 $CTRL_SUBJECTS_DIR/$subj/roi/reg_standard4/t1_sgm_standard4.nii.gz"
	GMlist_std2="$GMlist_std2 $CTRL_SUBJECTS_DIR/$subj/roi/reg_standard/t1_sgm_standard.nii.gz"
done

for subj in ${arr_ad_corr[@]}
do
	GMlist_std4="$GMlist_std4 $AD_SUBJECTS_DIR/$subj/roi/reg_standard4/t1_sgm_standard4.nii.gz"
	GMlist_std2="$GMlist_std2 $AD_SUBJECTS_DIR/$subj/roi/reg_standard/t1_sgm_standard.nii.gz"
done

for subj in ${arr_ftd_corr[@]}
do
	GMlist_std4="$GMlist_std4 $FTD_SUBJECTS_DIR/$subj/roi/reg_standard4/t1_sgm_standard4.nii.gz"
	GMlist_std2="$GMlist_std2 $FTD_SUBJECTS_DIR/$subj/roi/reg_standard/t1_sgm_standard.nii.gz"
done
#=============================================================================================================================

echo $GMlist_std4
echo $GMlist_std2

. $GLOBAL_GROUP_SCRIPT_DIR/feat_gm_merge_smooth.sh $FEAT_GM_OUTPUT_DIR/$analysis_name "$GMlist_std2" "$GMlist_std4"


echo "=================>>>>  End processing"
