. $GLOBAL_SCRIPT_DIR/utility_functions.sh


SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

mri_convert $T1_DATA.nii.gz $T1_DATA.mgz

OLD_SUBJECTS_DIR=$SUBJECTS_DIR

SUBJECTS_DIR=$T1_DIR
recon-all -subject freesurfer$SUBJ_NAME -i $T1_DATA.mgz -all


mri_convert $T1_DIR/freesurfer$SUBJ_NAME/mri/aparc+aseg.mgz $T1_DIR/freesurfer$SUBJ_NAME/aparc+aseg.nii.gz
mri_convert $T1_DIR/freesurfer$SUBJ_NAME/mri/aseg.mgz $T1_DIR/freesurfer$SUBJ_NAME/aseg.nii.gz

SUBJECTS_DIR=$OLD_SUBJECTS_DIR

rm $T1_DATA.mgz
