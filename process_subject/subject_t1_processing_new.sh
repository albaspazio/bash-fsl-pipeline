#!/bin/sh
#
# General FSL anatomical processing pipeline
# modified to receive the SUBJ_NAME and the PROJ_DIR
#
. $GLOBAL_SCRIPT_DIR/utility_functions.sh

export LC_NUMERIC=C

set -e


# The following is a debugging line (displays all commands as they are executed)
# set -x

Usage() {
    echo "Usage: `basename $0` SUBJ_NAME PROJ_DIR [options]"
    echo "       `basename $0` SUBJ_NAME PROJ_DIR [options] -odn <existing anat directory>"
    echo "called with these parameters: $@"
    #echo "       `basename $0` [options] --list=<list of image names OR a text file>"
    echo " "
    echo "Arguments (You may specify one or more of):"
    echo "  -odn <output directory>      basename of directory for output (default is 'anat')"
    echo "  --overwrite                  overwrite each step of the pipeline, otherwise do a step only if requested and if the output is absent"
    echo "  --weakbias                   used for images with little and/or smooth bias fields"
    #echo "  --nobet                      turn off step that does brain extraction (BET or registration) - to use this the input image must already brain extracted"
    echo "  --nobias                     turn off steps that do bias field correction (via FAST)"
    echo "  --noreg                      turn off steps that do registration to standard (FLIRT and FNIRT)"
    echo "  --nononlinreg                turn off step that does non-linear registration (FNIRT)"
    echo "  --noseg                      turn off step that does tissue-type segmentation (FAST)"
    echo "  --nosubcortseg               turn off step that does sub-cortical segmentation (FIRST)"
    echo "  -s <value>                   specify the value for bias field smoothing (the -l option in FAST)"
    echo "  -t <type>                    specify the type of image (choose one of T1 T2 PD - default is T1)"
    #echo "  -m <lesion mask>             use the mask image to exclude areas (e.g. lesions) -  voxels=1 in mask are excluded/deweighted"
    echo "  --nosearch                   specify that linear registration uses the -nosearch option (FLIRT)"
    echo "  --betfparam                  specify f parameter for BET (only used if not running non-linear reg and also wanting brain extraction done)"
    echo "  --nocleanup                  do not remove intermediate files"
    echo "  --strongcleanup              remove copies and duplicates"
    echo " "
}

# default values
outputname=anat
type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

lesionmask=
imagelist=

strongbias=yes;
do_reorient=yes;
do_crop=yes;
do_bet=yes;
do_biasrestore=yes;
do_reg=yes;
do_nonlinreg=yes;
do_seg=yes;
do_subcortseg=yes;
do_cleanup=yes;
do_strongcleanup=no;
do_overwrite=no;
multipleimages=no;
use_lesionmask=no;

nosearch=
niter=5;
smooth=10;
betfparam=0.1;

# Parse! Parse! Parse!
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

LOGFILE=log.txt

while [ $# -ge 1 ] ; do
    iarg=`get_opt1 $1`;
    case "$iarg"	in

			-odn)				outputname=`get_arg2 $1 $2`; shift;;
			-t)					typestr=`get_arg2 $1 $2`;
								if [ $typestr = T1 ] ; then type=1; fi
								if [ $typestr = T2 ] ; then type=2; fi
								if [ $typestr = PD ] ; then type=3; fi;	shift;;	
			-s)					smooth=`get_arg2 $1 $2`; shift;;
			-m)					use_lesionmask=yes; lesionmask=`get_arg2 $1 $2`; shift;;
			--overwrite)		do_overwrite=yes;; 
			--nobet)			do_bet=no;;
			--noreg)			do_reg=no;;
			--nononlinreg)  	do_nonlinreg=no;;
			--noseg)			do_seg=no;;
			--nosubcortseg) 	do_subcortseg=no;;
			--nobias)			do_biasrestore=no;;
			--weakbias)			strongbias=no; niter=10; smooth=20;;
			--nosearch)		  	nosearch=-nosearch;;
			--betfparam)		betfparam=`get_arg1 $1`; shift;;
			--nocleanup)	  	do_cleanup=no;;
			--strongcleanup)	do_strongcleanup=yes;;
			-v)					verbose=yes;;
			-h)					Usage; exit 0;;
			*)					echo "Unrecognised option $1" 1>&2
								exit 1
    esac
    shift;
done
#=================================================================================
#=================================================================================
# CHECK INPUT TYPE
if [ $type != 1 ] ; then 
    if [ $do_nonlinreg = yes ] ; then 
			echo "ERROR: Cannot do non-linear registration with non-T1 images, please re-run with --nononlinreg" ; 
			exit 1;
    fi; 

    if [ $do_subcortseg = yes ] ; then 
			echo "ERROR: Cannot perform subcortical segmentation (with FIRST) on a non-T1 image, please re-run with --nosubcortseg"
			exit 1;
    fi ;
fi

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
#=================================================================================
#=================================================================================
main()
{
	if [ -f $anatdir/$LOGFILE ]; then
		echo "******************************************************************" >> $anatdir/$LOGFILE
		echo "updating directory" >> $anatdir/$LOGFILE
	else
		# some initial reporting for the log file
		echo "Script invoked from directory = `pwd`" >> $anatdir/$LOGFILE
		echo "Output directory = $anatdir" >> $anatdir/$LOGFILE

		$FSLDIR/bin/fslmaths ${inputimage} $anatdir/${T1}
		echo "Input image is ${inputimage}" >> $anatdir/$LOGFILE

		if [ $use_lesionmask = yes ] ; then
				$FSLDIR/bin/fslmaths $lesionmask $anatdir/lesionmask
				echo "Lesion mask is ${lesionmask}" >> $anatdir/$LOGFILE
		fi
	fi

	cd $anatdir
	echo " " >> $LOGFILE

	#==================================================================================================================================================================
	#==================================================================================================================================================================
	# now the real work
	#==================================================================================================================================================================
	#==================================================================================================================================================================

	# these 3 steps are now done in subject_t1_prepare.sh	
	#### FIXING NEGATIVE RANGE
	#### REORIENTATION 2 STANDARD
	#### AUTOMATIC CROPPING


	### LESION MASK
	if [ `$FSLDIR/bin/imtest lesionmask` = 0 -o $do_overwrite = yes ]; then
		# make appropriate (reoreinted and cropped) lesion mask (or a default blank mask to simplify the code later on)
		if [ $use_lesionmask = yes ] ; then
				if [ -f ${T1}_orig2std.mat ] ; then transform=${T1}_orig2std.mat ; fi
				if [ -f ${T1}_orig2roi.mat ] ; then transform=${T1}_orig2roi.mat ; fi   # this takes precedence if both exist
				if [ X$transform != X ] ; then
					$FSLDIR/bin/fslmaths lesionmask lesionmask_orig
					$FSLDIR/bin/flirt -in lesionmask_orig -ref ${T1} -applyxfm -interp nearestneighbour -init ${transform} -out lesionmask
				fi
		else
				$FSLDIR/bin/fslmaths ${T1} -mul 0 lesionmask
		fi
		$FSLDIR/bin/fslmaths lesionmask -bin lesionmask
		$FSLDIR/bin/fslmaths lesionmask -binv lesionmaskinv
	fi


	#### BIAS FIELD CORRECTION (main work, although also refined later on if segmentation run)
	# required input: ${T1}
	# output: ${T1}_biascorr  [ other intermediates to be cleaned up ]
	if [ `$FSLDIR/bin/imtest ${T1}_biascorr` = 0 -o $do_overwrite = yes ]; then
		if [ $do_biasrestore = yes ] ; then
				if [ $strongbias = yes ] ; then
					date; echo "$SUBJ_NAME :Estimating and removing field (stage 1 - large-scale fields)"
					# for the first step (very gross bias field) don't worry about the lesionmask
					# the following is a replacement for : run $FSLDIR/bin/fslmaths ${T1} -s 20 ${T1}_s20
					quick_smooth ${T1} ${T1}_s20
					run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_s20 ${T1}_hpf
					if [ $do_bet = yes ] ; then
				  	# get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
						run $FSLDIR/bin/bet ${T1}_hpf ${T1}_hpf_brain -m -f 0.1
					else
						run $FSLDIR/bin/fslmaths ${T1}_hpf ${T1}_hpf_brain
						run $FSLDIR/bin/fslmaths ${T1}_hpf_brain -bin ${T1}_hpf_brain_mask
					fi
					run $FSLDIR/bin/fslmaths ${T1}_hpf_brain_mask -mas lesionmaskinv ${T1}_hpf_brain_mask
				  # get a smoothed version without the edge effects
					run $FSLDIR/bin/fslmaths ${T1} -mas ${T1}_hpf_brain_mask ${T1}_hpf_s20
					quick_smooth ${T1}_hpf_s20 ${T1}_hpf_s20
					quick_smooth ${T1}_hpf_brain_mask ${T1}_initmask_s20
					run $FSLDIR/bin/fslmaths ${T1}_hpf_s20 -div ${T1}_initmask_s20 -mas ${T1}_hpf_brain_mask ${T1}_hpf2_s20
					run $FSLDIR/bin/fslmaths ${T1} -mas ${T1}_hpf_brain_mask -div ${T1}_hpf2_s20 ${T1}_hpf2_brain
					# make sure the overall scaling doesn't change (equate medians)
					med0=`$FSLDIR/bin/fslstats ${T1} -k ${T1}_hpf_brain_mask -P 50`;
					med1=`$FSLDIR/bin/fslstats ${T1}_hpf2_brain -k ${T1}_hpf_brain_mask -P 50`;
					run $FSLDIR/bin/fslmaths ${T1}_hpf2_brain -div $med1 -mul $med0 ${T1}_hpf2_brain
					date; echo "$SUBJ_NAME :Estimating and removing bias field (stage 2 - detailed fields)"
					run $FSLDIR/bin/fslmaths ${T1}_hpf2_brain -mas lesionmaskinv ${T1}_hpf2_maskedbrain
					run $FSLDIR/bin/fast -o ${T1}_initfast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_hpf2_maskedbrain
					run $FSLDIR/bin/fslmaths ${T1}_initfast_restore -mas lesionmaskinv ${T1}_initfast_maskedrestore
					run $FSLDIR/bin/fast -o ${T1}_initfast2 -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast_maskedrestore
					run $FSLDIR/bin/fslmaths ${T1}_hpf_brain_mask ${T1}_initfast2_brain_mask
				else
					if [ $do_bet = yes ] ; then
				  	# get a rough brain mask - it can be *VERY* rough (i.e. missing huge portions of the brain or including non-brain, but non-background) - use -f 0.1 to err on being over inclusive
						run $FSLDIR/bin/bet ${T1} ${T1}_initfast2_brain -m -f 0.1
					else
						run $FSLDIR/bin/fslmaths ${T1} ${T1}_initfast2_brain
						run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain -bin ${T1}_initfast2_brain_mask
					fi
					run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain ${T1}_initfast2_restore
				fi
				# redo fast again to try and improve bias field
				run $FSLDIR/bin/fslmaths ${T1}_initfast2_restore -mas lesionmaskinv ${T1}_initfast2_maskedrestore
				run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} --nopve --fixed=0 -v ${T1}_initfast2_maskedrestore
				
				date; echo "$SUBJ_NAME :Extrapolating bias field from central region"
				# use the latest fast output
				run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_restore -mas ${T1}_initfast2_brain_mask ${T1}_fast_totbias
				run $FSLDIR/bin/fslmaths ${T1}_initfast2_brain_mask -ero -ero -ero -ero -mas lesionmaskinv ${T1}_initfast2_brain_mask2
				run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias 
				run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_initfast2_brain_mask2 -o ${T1}_fast_bias
				run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias 
				run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias 
				# run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_initfast2_brain_mask -dilall -add 1 ${T1}_fast_bias  # alternative to fslsmoothfill
				run $FSLDIR/bin/fslmaths ${T1} -div ${T1}_fast_bias ${T1}_biascorr
		else
				run $FSLDIR/bin/fslmaths ${T1} ${T1}_biascorr
		fi
	fi


	#### REGISTRATION AND BRAIN EXTRACTION
	# required input: ${T1}_biascorr
	# output: ${T1}_biascorr_brain ${T1}_biascorr_brain_mask ${T1}_to_MNI_lin ${T1}_to_MNI [plus transforms, inverse transforms, jacobians, etc.]
	if [ `$FSLDIR/bin/imtest ${T1}_biascorr_brain` = 0 -o $do_overwrite = yes ]; then
		if [ $do_reg = yes ] ; then
				if [ $do_bet != yes ] ; then
					echo "$SUBJ_NAME :Skipping registration, as it requires a non-brain-extracted input image"
				else
					date; echo "$SUBJ_NAME :Registering to standard space (linear)"
					flirtargs="$flirtargs $nosearch"
					if [ $use_lesionmask = yes ] ; then flirtargs="$flirtargs -inweight lesionmaskinv" ; fi
					run $FSLDIR/bin/flirt -interp spline -dof 12 -in ${T1}_biascorr -ref $FSLDIR/data/standard/MNI152_${T1}_2mm -dof 12 -omat ${T1}_to_MNI_lin.mat -out ${T1}_to_MNI_lin $flirtargs
	
					if [ $do_nonlinreg = yes ] ; then
						date; echo "Registering to standard space (non-linear)"
						#refmask=$FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask_dil1
						refmask=MNI152_${T1}_2mm_brain_mask_dil1
						fnirtargs=""
						if [ $use_lesionmask = yes ] ; then fnirtargs="$fnirtargs --inmask=lesionmaskinv" ; fi
						run $FSLDIR/bin/fslmaths $FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask -fillh -dilF $refmask
					 	run $FSLDIR/bin/fnirt --in=${T1}_biascorr --ref=$FSLDIR/data/standard/MNI152_${T1}_2mm --fout=${T1}_to_MNI_nonlin_field --jout=${T1}_to_MNI_nonlin_jac --iout=${T1}_to_MNI_nonlin --logout=${T1}_to_MNI_nonlin.txt --cout=${T1}_to_MNI_nonlin_coeff --config=$FSLDIR/etc/flirtsch/${T1}_2_MNI152_2mm.cnf --aff=${T1}_to_MNI_lin.mat --refmask=$refmask $fnirtargs
					
						date; echo "$SUBJ_NAME :Performing brain extraction (using FNIRT)"
						run $FSLDIR/bin/invwarp --ref=${T1}_biascorr -w ${T1}_to_MNI_nonlin_coeff -o MNI_to_${T1}_nonlin_field
						run $FSLDIR/bin/applywarp --interp=nn --in=$FSLDIR/data/standard/MNI152_${T1}_2mm_brain_mask --ref=${T1}_biascorr -w MNI_to_${T1}_nonlin_field -o ${T1}_biascorr_brain_mask
						run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -fillh ${T1}_biascorr_brain_mask
						run $FSLDIR/bin/fslmaths ${T1}_biascorr -mas ${T1}_biascorr_brain_mask ${T1}_biascorr_brain
					fi
				  ## In the future, could check the initial ROI extraction here
				fi
		else
				if [ $do_bet = yes ] ; then
					date; echo "$SUBJ_NAME :Performing brain extraction (using BET)"
					run $FSLDIR/bin/bet ${T1}_biascorr ${T1}_biascorr_brain -m $betopts  ## results sensitive to the f parameter
				else
					run $FSLDIR/bin/fslmaths ${T1}_biascorr ${T1}_biascorr_brain
					run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -bin ${T1}_biascorr_brain_mask
				fi
		fi
	fi

	#### TISSUE-TYPE SEGMENTATION
	# required input: ${T1}_biascorr ${T1}_biascorr_brain ${T1}_biascorr_brain_mask
	# output: ${T1}_biascorr ${T1}_biascorr_brain (modified) ${T1}_fast* (as normally output by fast) ${T1}_fast_bias (modified)
	if [ `$FSLDIR/bin/imtest ${T1}_fast_pve_1` = 0 -o $do_overwrite = yes ]; then
		if [ $do_seg = yes ] ; then
				date; echo "$SUBJ_NAME :Performing tissue-type segmentation"
				run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain -mas lesionmaskinv ${T1}_biascorr_maskedbrain
				run $FSLDIR/bin/fast -o ${T1}_fast -l ${smooth} -b -B -t $type --iter=${niter} ${T1}_biascorr_maskedbrain 
				run $FSLDIR/bin/immv ${T1}_biascorr ${T1}_biascorr_init
				run $FSLDIR/bin/fslmaths ${T1}_fast_restore ${T1}_biascorr_brain
				# extrapolate bias field and apply to the whole head image
				run $FSLDIR/bin/fslmaths ${T1}_biascorr_brain_mask -mas lesionmaskinv ${T1}_biascorr_brain_mask2
				run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_restore -mas ${T1}_biascorr_brain_mask2 ${T1}_fast_totbias
				run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 ${T1}_fast_totbias
				run $FSLDIR/bin/fslsmoothfill -i ${T1}_fast_totbias -m ${T1}_biascorr_brain_mask2 -o ${T1}_fast_bias
				run $FSLDIR/bin/fslmaths ${T1}_fast_bias -add 1 ${T1}_fast_bias
				run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -add 1 ${T1}_fast_totbias
				# run $FSLDIR/bin/fslmaths ${T1}_fast_totbias -sub 1 -mas ${T1}_biascorr_brain_mask2 -dilall -add 1 ${T1}_fast_bias # alternative to fslsmoothfill
				run $FSLDIR/bin/fslmaths ${T1}_biascorr_init -div ${T1}_fast_bias ${T1}_biascorr
				
				if [ $do_nonlinreg = yes ] ; then
					# regenerate the standard space version with the new bias field correction applied
					run $FSLDIR/bin/applywarp -i ${T1}_biascorr -w ${T1}_to_MNI_nonlin_field -r $FSLDIR/data/standard/MNI152_${T1}_2mm -o ${T1}_to_MNI_nonlin --interp=spline
				fi
		fi
	fi

	#### SKULL-CONSTRAINED BRAIN VOLUME ESTIMATION (only done if registration turned on, and segmentation done, and it is a T1 image)
	# required inputs: ${T1}_biascorr
	# output: ${T1}_vols.txt
	if [ ! -f ${T1}_vols.txt -o $do_overwrite = yes ]; then
		if [ $do_reg = yes ] && [ $do_seg = yes ] && [ $T1 = T1 ] ; then 
				echo "$SUBJ_NAME :Skull-constrained registration (linear)"
				run ${FSLDIR}/bin/bet ${T1}_biascorr ${T1}_biascorr_bet -s -m $betopts
				run ${FSLDIR}/bin/pairreg ${FSLDIR}/data/standard/MNI152_T1_2mm_brain ${T1}_biascorr_bet ${FSLDIR}/data/standard/MNI152_T1_2mm_skull ${T1}_biascorr_bet_skull ${T1}2std_skullcon.mat
				
				if [ $use_lesionmask = yes ] ; then
					run ${FSLDIR}/bin/fslmaths lesionmask -max ${T1}_fast_pve_2 ${T1}_fast_pve_2_plusmask -odt float
				  # ${FSLDIR}/bin/fslmaths lesionmask -bin -mul 3 -max ${T1}_fast_seg ${T1}_fast_seg_plusmask -odt int
				fi
				
				vscale=`${FSLDIR}/bin/avscale ${T1}2std_skullcon.mat | grep Determinant | awk '{ print $3 }'`;
				ugrey=`$FSLDIR/bin/fslstats ${T1}_fast_pve_1 -m -v | awk '{ print $1 * $3 }'`;
				ngrey=`echo "$ugrey * $vscale" | bc -l`;
				uwhite=`$FSLDIR/bin/fslstats ${T1}_fast_pve_2 -m -v | awk '{ print $1 * $3 }'`;
				nwhite=`echo "$uwhite * $vscale" | bc -l`;
				ubrain=`echo "$ugrey + $uwhite" | bc -l`;
				nbrain=`echo "$ngrey + $nwhite" | bc -l`;
				echo "Scaling factor from ${T1} to MNI (using skull-constrained linear registration) = $vscale" > ${T1}_vols.txt
				echo "Brain volume in mm^3 (native/original space) = $ubrain" >> ${T1}_vols.txt
				echo "Brain volume in mm^3 (normalised to MNI) = $nbrain" >> ${T1}_vols.txt
		fi
	fi

#	#### SUB-CORTICAL STRUCTURE SEGMENTATION (done in subject_t1_first)
#	# required input: ${T1}_biascorr
#	# output: ${T1}_first*
#	if [ `$FSLDIR/bin/imtest ${T1}_subcort_seg` = 0 -o $do_overwrite = yes ]; then
#		if [ $do_subcortseg = yes ] ; then
#				date; echo "$SUBJ_NAME :Performing subcortical segmentation"
#				# Future note, would be nice to use ${T1}_to_MNI_lin.mat to initialise first_flirt
#				ffopts=""
#				if [ $use_lesionmask = yes ] ; then ffopts="$ffopts -inweight lesionmaskinv" ; fi
#				run $FSLDIR/bin/first_flirt ${T1}_biascorr ${T1}_biascorr_to_std_sub $ffopts
#				run mkdir -p first_results
#				run $FSLDIR/bin/run_first_all $firstreg -i ${T1}_biascorr -o first_results/${T1}_first -a ${T1}_biascorr_to_std_sub.mat
#				# rather complicated way of making a link to a non-existent file or files (as FIRST may run on the cluster) - the alernative would be fsl_sub and job holds...
#				names=`$FSLDIR/bin/imglob -extensions ${T1}`;
#				for fn in $names; 
#				do 
#					ext=`echo $fn | sed "s/${T1}.//"`;
#				  run cp -r first_results/${T1}_first_all_fast_firstseg.${ext} ${T1}_subcort_seg.${ext}
#				done
#		fi
#	fi

	#### CLEANUP
	if [ $do_cleanup = yes ] ; then
	#  date; echo "$SUBJ_NAME :Cleaning up intermediate files"
		run $FSLDIR/bin/imrm ${T1}_biascorr_bet_mask ${T1}_biascorr_bet ${T1}_biascorr_brain_mask2 ${T1}_biascorr_init ${T1}_biascorr_maskedbrain ${T1}_biascorr_to_std_sub ${T1}_fast_bias_idxmask ${T1}_fast_bias_init ${T1}_fast_bias_vol2 ${T1}_fast_bias_vol32 ${T1}_fast_totbias ${T1}_hpf* ${T1}_initfast* ${T1}_s20 ${T1}_initmask_s20
	fi


	#### STRONG CLEANUP
	if [ $do_strongcleanup = yes ] ; then
	#  date; echo "$SUBJ_NAME :Cleaning all unnecessary files "
		run $FSLDIR/bin/imrm ${T1} ${T1}_orig ${T1}_fullfov
	fi
}
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
betopts="-f ${betfparam}"


if [ `$FSLDIR/bin/imtest ${T1_DATA}` = 0 ]; then
	return 0
fi

mkdir -p $anatdir


if [ `$FSLDIR/bin/imtest ${T1}` = 0 ]; then
	$FSLDIR/bin/imcp $T1_DATA $anatdir/$T1
fi


main


