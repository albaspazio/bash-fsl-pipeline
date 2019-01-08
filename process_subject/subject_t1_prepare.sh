#!/bin/sh
#
# script preceeding any pipeline operations. 
# It performs the following operations:

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
    echo "  --noreorient                 turn off step that does reorientation 2 standard (fslreorient2std)"
    echo "  --nocrop                     turn off step that does automated cropping (robustfov)"
	echo "  --nocleanup					 do not delete IMG_orig IMG_fullfov"
    echo " "
}

# default values
outputname=anat
type=1  # For FAST: 1 = T1w, 2 = T2w, 3 = PD

do_reorient=yes;
do_crop=yes;
do_overwrite=no;
do_cleanup=yes;

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

			-odn)			outputname=`get_arg2 $1 $2`; shift;;
			-t)				typestr=`get_arg2 $1 $2`;
							if [ $typestr = T1 ] ; then type=1; fi
							if [ $typestr = T2 ] ; then type=2; fi
							if [ $typestr = PD ] ; then type=3; fi;	shift;;	
			--overwrite)	do_overwrite=yes;; 
			--noreorient)  	do_reorient=no;;
			--nocrop)		do_crop=no;;
			--nocleanup)	do_cleanup=no;;		
			-v)				verbose=yes;;
			-h)				Usage; exit 0;;
			*)				echo "Unrecognised option $1" 1>&2
							exit 1
    esac
    shift;
done

#=================================================================================
# CHECK INPUT TYPE
#=================================================================================
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
# CHECK INPUT & PREPATE FILES
#=================================================================================
if [ `$FSLDIR/bin/imtest ${T1_DATA}` = 0 ]; then
	return 0
fi

mkdir -p $anatdir

if [ `$FSLDIR/bin/imtest ${T1}` = 0 ]; then
	$FSLDIR/bin/imcp $T1_DATA $anatdir/$T1
fi
#=================================================================================
#=================================================================================

main()
{
	if [ -f $anatdir/$LOGFILE ]; then
		echo "******************************************************************" >> $anatdir/$LOGFILE
		echo "Preparing T1" >> $anatdir/$LOGFILE
	else
		$FSLDIR/bin/fslmaths ${inputimage} $anatdir/${T1}
		echo "Input image is ${inputimage}" >> $anatdir/$LOGFILE
	fi

	cd $anatdir
	echo " " >> $LOGFILE
	#==================================================================================================================================================================
	#==================================================================================================================================================================
	# now the real work
	#==================================================================================================================================================================
	#==================================================================================================================================================================
	
	#### FIXING NEGATIVE RANGE
	# required input: ${T1}
	# output: ${T1}
	minval=`$FSLDIR/bin/fslstats ${T1} -p 0`;
	maxval=`$FSLDIR/bin/fslstats ${T1} -p 100`;
	if [ X`echo "if ( $minval < 0 ) { 1 }" | bc -l` = X1 ] ; then
		  if [ X`echo "if ( $maxval > 0 ) { 1 }" | bc -l` = X1 ] ; then
				# if there are just some negative values among the positive ones then reset zero to the min value
				run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval ${T1} -odt float
		  else
				# if all values are negative then make them positive, but retain any zeros as zeros
				run ${FSLDIR}/bin/fslmaths ${T1} -bin -binv zeromask
				run ${FSLDIR}/bin/fslmaths ${T1} -sub $minval -mas zeromask ${T1} -odt float
		  fi
	fi


	#### REORIENTATION 2 STANDARD
	# required input: ${T1}
	# output: ${T1} (modified) [ and ${T1}_orig and .mat ]

	if [ ! -f ${T1}_orig2std.mat -o $do_overwrite = yes ]; then
		if [ $do_reorient = yes ] ; then
			date; echo "$SUBJ_NAME :Reorienting to standard orientation"
		  	run $FSLDIR/bin/fslmaths ${T1} ${T1}_orig
			run $FSLDIR/bin/fslreorient2std ${T1} > ${T1}_orig2std.mat
			run $FSLDIR/bin/convert_xfm -omat ${T1}_std2orig.mat -inverse ${T1}_orig2std.mat
			run $FSLDIR/bin/fslreorient2std ${T1} ${T1} 
		fi
	fi


	#### AUTOMATIC CROPPING
	# required input: ${T1}
	# output: ${T1} (modified) [ and ${T1}_fullfov plus various .mats ]
	if [ `$FSLDIR/bin/imtest ${T1}_fullfov` = 0 -o $do_overwrite = yes ]; then
		if [ $do_crop = yes ] ; then
		  date; echo "$SUBJ_NAME :Automatically cropping the image"
		  run $FSLDIR/bin/immv ${T1} ${T1}_fullfov
		  run $FSLDIR/bin/robustfov -i ${T1}_fullfov -r ${T1} -m ${T1}_roi2nonroi.mat | grep [0-9] | tail -1 > ${T1}_roi.log
		  # combine this mat file and the one above (if generated)
		  if [ $do_reorient = yes ] ; then
				run $FSLDIR/bin/convert_xfm -omat ${T1}_nonroi2roi.mat -inverse ${T1}_roi2nonroi.mat
				run $FSLDIR/bin/convert_xfm -omat ${T1}_orig2roi.mat -concat ${T1}_nonroi2roi.mat ${T1}_orig2std.mat 
				run $FSLDIR/bin/convert_xfm -omat ${T1}_roi2orig.mat -inverse ${T1}_orig2roi.mat
		  fi
		fi
	fi

	####  CLEANUP
	if [ $do_cleanup = yes ] ; then
	#  date; echo "$SUBJ_NAME :Cleaning all unnecessary files "
		run $FSLDIR/bin/imrm ${T1}_orig ${T1}_fullfov
	fi
}
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
#==================================================================================================================================================================
main


