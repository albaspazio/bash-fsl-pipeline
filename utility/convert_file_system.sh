# full convert:
# from old (t1,rs) file system to new (mpr,resting) one
# from SBFC/roi => $ROI_DIR subfolders
# from SUBJ_NAME-rs.nii.gz/ica => resting.nii.gz/ica
# generally removing any reference to SUBJ_NAME in sources and processed (BET, FAST, FIRST, melodic folders, sbcf timeseries, roi, mat, warp) files.

SUBJ_NAME=$1
PROJ_DIR=$2

subject_dir=$PROJ_DIR/subjects/$SUBJ_NAME/s1

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

if [ ! -d $subject_dir ]; then
	mkdir -p $subject_dir
	mv $PROJ_DIR/subjects/$SUBJ_NAME/* $PROJ_DIR/subjects/$SUBJ_NAME/s1
fi

if [ -d $subject_dir/t1 ]; then mv $subject_dir/t1 $subject_dir/mpr; fi
if [ -d $subject_dir/rs ]; then mv $subject_dir/rs $subject_dir/resting; fi

#======= MPR ===================================================
cd $subject_dir/mpr
for img in *; do
	new_name=${img/$SUBJ_NAME-t1/$T1_IMAGE_LABEL}
	if [[ $img != $new_name ]]; then mv $img $new_name; fi
done

if [ -d $subject_dir/mpr/first ]; then
	cd $subject_dir/mpr/first
	for img in *; do
		new_name=${img/$SUBJ_NAME-t1/$T1_IMAGE_LABEL}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
	done
fi

if [ -d $subject_dir/sienax ]; then
	cd $subject_dir/mpr/sienax
	for img in *; do
		new_name=${img/$SUBJ_NAME-t1/$T1_IMAGE_LABEL}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
	done
fi

if [ -d $subject_dir/mpr/fast ]; then
	cd $subject_dir/mpr/fast
	for img in *; do
		new_name=${img/$SUBJ_NAME-t1/$T1_IMAGE_LABEL}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
	done

	if [ -d $FAST_DIR/reg_epi ];then	mv $FAST_DIR/reg_epi $ROI_DIR; fi
	if [ -d $FAST_DIR/reg_standard ]; then mv $FAST_DIR/reg_standard $ROI_DIR; fi
	if [ -d $FAST_DIR/reg_standard4 ]; then mv $FAST_DIR/reg_standard4 $ROI_DIR; fi

	[ -f $FAST_DIR/$SUBJ_NAME-t1_sgm.nii.gz ] && mv $FAST_DIR/$SUBJ_NAME-t1_sgm.nii.gz $ROI_DIR/reg_t1/t1_sgm.nii.gz
fi

#======= RESTING ===================================================
cd $subject_dir/resting
[ -f $SUBJ_NAME-rs.nii.gz ] && mv $SUBJ_NAME-rs.nii.gz resting.nii.gz
[ -d $SUBJ_NAME-rs.ica ] && mv $SUBJ_NAME-rs.ica resting.ica
[ -f model/$SUBJ_NAME-melodic.fsf ] && mv model/$SUBJ_NAME-melodic.fsf model/melodic.fsf

if [ -d $SBFC_DIR/roi ]; then
	cd $SBFC_DIR/roi
	mv standard2highres_warp.nii.gz $ROI_DIR/reg_t1
	mv highres2standard_warp.nii.gz $ROI_DIR/reg_standard
	mv *_epi.nii.gz $ROI_DIR/reg_epi
	mv *_epi1.nii.gz $ROI_DIR/reg_epi
	mv *_epi2.nii.gz $ROI_DIR/reg_epi
	
	mv *_hr.nii.gz $ROI_DIR/reg_t1
	mv *_hr_temp.nii.gz $ROI_DIR/reg_t1	
	
	mv *_std2.nii.gz $ROI_DIR/reg_standard	
	
	mv * $ROI_DIR
	rm -rf $SBFC_DIR/roi	
fi	

cd $SBFC_DIR/series
for img in *
do
	new_name=${img/$SUBJ_NAME"_"/}
	if [[ $img != $new_name ]]; then mv $img $new_name; fi
done 

if [ -d $SBFC_DIR/feat/motion.feat ]; then mv $SBFC_DIR/feat/motion.feat/stats/res4d_10000.nii.gz $SBFC_DIR/motion_10000.nii.gz; rm -rf $SBFC_DIR/feat/motion.feat; fi
if [ -d $SBFC_DIR/feat/nuisance.feat ]; then mv $SBFC_DIR/feat/nuisance.feat/stats/res4d_10000.nii.gz $SBFC_DIR/nuisance_10000.nii.gz; rm -rf $SBFC_DIR/feat/nuisance.feat; fi
if [ -d $SBFC_DIR/feat/denoised_nuisance.feat ]; then mv $SBFC_DIR/feat/denoised_nuisance.feat/stats/res4d_10000.nii.gz $SBFC_DIR/nuisance_denoised_10000.nii.gz; rm -rf $SBFC_DIR/feat/denoised_nuisance.feat; fi

#======= DTI ===================================================
if [ -d $subject_dir/dti ]; then
	cd $subject_dir/dti
	for img in *; do
		new_name=${img/$SUBJ_NAME-dti/$DTI_IMAGE_LABEL}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
	done
fi


#======= ROI ===================================================
mkdir -p $ROI_DIR/reg_epi
mkdir -p $ROI_DIR/reg_t1
mkdir -p $ROI_DIR/reg_dti
mkdir -p $ROI_DIR/reg_standard
mkdir -p $ROI_DIR/reg_standard4


if [ -d $ROI_DIR/reg_epi ];then
	cd $ROI_DIR/reg_epi
	for img in *
	do
		new_name=${img/$SUBJ_NAME-/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
		new_name=${img/$SUBJ_NAME"_"/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi		
	done
	[ -f $ROI_DIR/reg_epi/t1_sgm.nii.gz ] && mv $ROI_DIR/reg_epi/t1_sgm.nii.gz $ROI_DIR/reg_epi/t1_sgm_epi.nii.gz
fi

if [ -d $ROI_DIR/reg_standard ];then
	cd $ROI_DIR/reg_standard
	for img in *
	do
		new_name=${img/$SUBJ_NAME-/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
		new_name=${img/$SUBJ_NAME"_"/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi		
		new_name=${img/_std2/_standard}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi				
	done
	[ -f $ROI_DIR/reg_standard/t1_sgm.nii.gz ] && mv $ROI_DIR/reg_standard/t1_sgm.nii.gz $ROI_DIR/reg_standard/t1_sgm_standard.nii.gz
fi

if [ -d $ROI_DIR/reg_standard4 ];then
	cd $ROI_DIR/reg_standard4
	for img in *
	do
		new_name=${img/$SUBJ_NAME-/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
		new_name=${img/$SUBJ_NAME"_"/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi		
	done
	[ -f $ROI_DIR/reg_standard4/t1_sgm.nii.gz ] && mv $ROI_DIR/reg_standard4/t1_sgm.nii.gz $ROI_DIR/reg_standard4/t1_sgm_standard4.nii.gz  
fi

if [ -d $ROI_DIR/reg_t1 ];then
	cd $ROI_DIR/reg_t1
	for img in *
	do
		new_name=${img/_hr/_highres}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
	done
fi

if [ -d $ROI_DIR/reg_dti ];then
	cd $ROI_DIR/reg_dti
	for img in *
	do
		new_name=${img/$SUBJ_NAME-/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi
		new_name=${img/$SUBJ_NAME"_"/}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi	
		new_name=${img/_to_dti/2dti}
		if [[ $img != $new_name ]]; then mv $img $new_name; fi			
	done
fi

[ -d $T1_DIR/OT ] && rm -rf $T1_DIR/OT
[ -f $T1_DIR/co* ] && rm -r $T1_DIR/co*
[ -f $T1_DIR/o* ] && rm -r $T1_DIR/o*



