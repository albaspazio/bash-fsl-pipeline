#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/data/MRI/projects/ELA 									# <<<<@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
export FSLDIR=/usr/local/fsl																# change according to used PC
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================

. $PROJ_SCRIPT_DIR/subjects_list.sh

thrPvalue=20
OUTPUT_DIR_NAME_l=l_cst_ped2mi_2wp_1s
OUTPUT_DIR_NAME_r=r_cst_ped2mi_2wp_1s
mask_thrp_file_name_r=mask_$OUTPUT_DIR_NAME_r"_P"$thrPvalue.nii.gz
mask_thrp_file_name_l=mask_$OUTPUT_DIR_NAME_l"_P"$thrPvalue.nii.gz


tbss_dir=$PROJ_GROUP_ANALYSIS_DIR/tbss/34subj_tbss_1
mkdir -p $tbss_dir/stats/cst

mask_l=""
mask_r=""
declare -i num_subj=${#arr_ela_dti[@]}

for SUBJ_NAME in ${arr_ela_dti[@]}
do
	echo $SUBJ_NAME
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	
	# register CST mask to TBSS target for masked TBSS analysis
	$FSLDIR/bin/applywarp -i $ROI_DIR/reg_dti/$mask_thrp_file_name_l -o $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_l.nii.gz -r $tbss_dir/stats/mean_FA.nii.gz -w $tbss_dir/FA/$SUBJ_NAME-dtifit_to_target_warp.nii.gz
	mask_l="$mask_l $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_l.nii.gz"

	$FSLDIR/bin/applywarp -i $ROI_DIR/reg_dti/$mask_thrp_file_name_r -o $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_r.nii.gz -r $tbss_dir/stats/mean_FA.nii.gz -w $tbss_dir/FA/$SUBJ_NAME-dtifit_to_target_warp.nii.gz
	mask_r="$mask_r $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_r.nii.gz"
	
done

#===========================================================================================================================
# create group mask for restricted TBSS analysis
$FSLDIR/bin/fslmerge -t $tbss_dir/stats/cst/mask_cst_r $mask_r
$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/mask_cst_r -mul $num_subj -Tmean $tbss_dir/stats/cst/masksum_cst_r -odt short
$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_r -thr $num_subj -add $tbss_dir/stats/cst/masksum_cst_r $tbss_dir/stats/cst/masksum_cst_r
#$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_r -mul 0 $tbss_dir/stats/cst/maskunique_cst_r

$FSLDIR/bin/fslmerge -t $tbss_dir/stats/cst/mask_cst_l $mask_l
$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/mask_cst_l -mul $num_subj -Tmean $tbss_dir/stats/cst/masksum_cst_l -odt short
$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_l -thr $num_subj -add $tbss_dir/stats/cst/masksum_cst_l $tbss_dir/stats/cst/masksum_cst_l
#$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_l -mul 0 $tbss_dir/stats/cst/maskunique_cst_l

#declare -i cnt=1
#for SUBJ_NAME in ${arr_ela_dti_cst[@]}
#do
#	$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_l.nii.gz -mul -1 -add 1 -mul $cnt -add $tbss_dir/stats/cst/maskunique_cst_l $tbss_dir/stats/cst/maskunique_cst_l
#	$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/$SUBJ_NAME"_"$mask_thrp_file_name_r.nii.gz -mul -1 -add 1 -mul $cnt -add $tbss_dir/stats/cst/maskunique_cst_r $tbss_dir/stats/cst/maskunique_cst_r
#	cnt=$cnt+1
#done
#nsubj1=($num_subj-1)
#$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_r -thr $nsubj1 -uthr $nsubj1 -bin -mul $tbss_dir/stats/cst/maskunique_cst_r $tbss_dir/stats/cst/maskunique_cst_r
#$FSLDIR/bin/fslmaths $tbss_dir/stats/cst/masksum_cst_l -thr $nsubj1 -uthr $nsubj1 -bin -mul $tbss_dir/stats/cst/maskunique_cst_l $tbss_dir/stats/cst/maskunique_cst_l


