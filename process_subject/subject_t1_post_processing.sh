#!/bin/sh

. $GLOBAL_SCRIPT_DIR/utility_functions.sh

#
# copy files created by subject_fsl_anat to the proper folders
#

Usage() {
    echo "Usage: `basename $0` SUBJ_NAME PROJ_DIR"
    echo "       `basename $0` SUBJ_NAME PROJ_DIR -odn <existing anat directory>"
    echo " "
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi
if [ $# -lt 2 ] ; then Usage; exit 1; fi

# ====== subject dependant variables ==================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

if [ -z $INIT_VARS_DEFINED ]; then 
  . $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
# =====================================================================================================

LOGFILE=$T1_DIR/log.txt

# default values
outputname=anat
type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD


while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"	in
			-odn)						outputname=`get_arg2 $1 $2`; shift;;
			-t)							typestr=`get_arg2 $1 $2`;
											if [ $typestr = T1 ] ; then type=1; fi
											if [ $typestr = T2 ] ; then type=2; fi
											if [ $typestr = PD ] ; then type=3; fi;	shift;;	
			-h)							Usage; exit 0;;
			*)							echo "Unrecognised option $1" 1>&2
											exit 1
    esac
    shift;
done

if [ $type = 1 ]; then
	T1=T1;
	inputimage=$T1_DATA
	anatdir=$T1_DIR/$outputname
fi

if [ $type = 2 ] ; then 
	T1=T2; 
	inputimage=$T2_DATA
	anatdir=$T2_DIR/$outputname	
fi

if [ $type = 3 ] ; then 
		echo "ERROR: PD input format is not supported"
		exit 1;
fi

#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#### move and rename files according to myMRI system

run echo "----------------------------------- starting t1_post_processing of subject $SUBJ_NAME"
cd $anatdir

run_notexisting_img $T1_DATA"_orig" run $FSLDIR/bin/immv $T1_DATA $T1_DATA"_orig"

run_notexisting_img $T1_DATA run $FSLDIR/bin/imcp ${T1}_biascorr $T1_DATA
run_notexisting_img $T1_BRAIN_DATA run $FSLDIR/bin/imcp ${T1}_biascorr_brain $T1_BRAIN_DATA
run_notexisting_img $T1_BRAIN_DATA"_mask" run $FSLDIR/bin/imcp ${T1}_biascorr_brain_mask $T1_BRAIN_DATA"_mask"

mkdir -p $FAST_DIR

run $FSLDIR/bin/immv *fast* $FAST_DIR
run_notexisting_img ./${T1}_fast_pve_1 run $FSLDIR/bin/imcp $FAST_DIR/${T1}_fast_pve_1 ./  # this file is tested by subject_t1_processing to skip the fast step. so by copying it back, I allow such skip.

run_notexisting_img $T1_SEGMENT_CSF_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_seg -thr 1 -uthr 1 $T1_SEGMENT_CSF_PATH
run_notexisting_img $T1_SEGMENT_GM_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_seg -thr 2 -uthr 2 $T1_SEGMENT_GM_PATH
run_notexisting_img $T1_SEGMENT_WM_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_seg -thr 3 $T1_SEGMENT_WM_PATH

run_notexisting_img $T1_SEGMENT_WM_BBR_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_pve_2 -thr 0.5 -bin $T1_SEGMENT_WM_BBR_PATH
run_notexisting_img $T1_SEGMENT_CSF_ERO_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_pve_0 -ero $T1_SEGMENT_CSF_ERO_PATH
run_notexisting_img $T1_SEGMENT_WM_ERO_PATH run $FSLDIR/bin/fslmaths $FAST_DIR/${T1}_fast_pve_2 -ero $T1_SEGMENT_WM_ERO_PATH

run $FSLDIR/bin/immv *_to_MNI* $ROI_DIR/reg_standard
run $FSLDIR/bin/immv *_to_T1* $ROI_DIR/reg_t1

run_notexisting_img $ROI_DIR/reg_t1/standard2highres_warp run $FSLDIR/bin/immv $ROI_DIR/reg_t1/MNI_to_T1_nonlin_field $ROI_DIR/reg_t1/standard2highres_warp
run_notexisting_img $ROI_DIR/reg_standard/highres2standard_warp run $FSLDIR/bin/immv $ROI_DIR/reg_standard/T1_to_MNI_nonlin_field $ROI_DIR/reg_standard/highres2standard_warp


# first has been removed from the standard t1_processing pipeline
#mkdir -p $FIRST_DIR
#run mv first_results $FIRST_DIR
#run $FSLDIR/bin/immv ${T1}_subcort_seg $FIRST_DIR




