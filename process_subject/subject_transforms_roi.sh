#!/bin/bash

# functions used to convert a set of images (string array locate at the end of the parameters) )from/to different reference system.
# it accepts images name (default) or fullpath (-absp)
# it perform linear (default) or non-linear (-nlin) registration
. $GLOBAL_SCRIPT_DIR/utility_functions.sh

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

standard_image=$FSL_DATA_STANDARD/MNI152_T1_2mm_brain
do_linear=1
roi_threshold=0.2

mask_image=""
path_type=standard #  "standard": a roi name, located in the default folder (subjectXX/s1/roi/reg_YYY/INPUTPATH), 
									 #	"rel"			: a path relative to SUBJECT_DIR (subjectXX/s1/INPUTPATH)
									 #  "abs"			: a full path (INPUTPATH)
OUTPUT_REPORT_FILE=""

while [ ! -z "$1" ]
do
  case "$1" in
		-regtype)		registration_type=$2;shift;;

		-thresh)		roi_threshold=$2;shift;;

		-mask)			mask_image=$2; shift;  # post-registration masking
			 					if [ ! -f $mask_image ]; then echo "ERROR: mask image file ($mask_image) do not exist......exiting"; exit; fi;;
			 	
		-nlin)			do_linear=0;;				

		-pathtype)	path_type=$2;shift;;

		-orf)				OUTPUT_REPORT_FILE=$2; shift;;

		*)  break;;
	esac
	shift
done

declare -a ROI=( "$@" )


echo "registration_type $registration_type  do_linear = $do_linear"

#==============================================================================================================
if [ -z $registration_type ]; then
	echo "error in reg_roi parameters..... you did not select any known registration"	
fi
#==============================================================================================================

HAS_T2=0
if [ -f $T2_DATA.nii.gz ]; then HAS_T2=1; fi

for roi in ${ROI[@]};	do

	roi_name=$(basename $roi)
	echo "converting $roi_name"
	if [ $do_linear -eq 0 ]; then

		# is non linear
		case "$registration_type" in
		
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			std2hr)		
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
							  $FSLDIR/bin/applywarp -i $input_roi -r $T1_BRAIN_DATA -o $output_roi --warp=$ROI_DIR/reg_t1/standard2highres_warp;;
								
			std42hr) 	
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard4/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $standard_image -out $ROI_DIR/reg_t1/$roi_name"_standard" -applyisoxfm 2;
								$FSLDIR/bin/applywarp -i $ROI_DIR/reg_t1/$roi_name"_standard" -r $T1_BRAIN_DATA -o $output_roi --warp=$ROI_DIR/reg_t1/standard2highres_warp;
								$FSLDIR/bin/imrm $ROI_DIR/reg_t1/$roi_name"_standard";;

			epi2hr)		
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
								$FSLDIR/bin/flirt -in $input_roi -ref $T1_BRAIN_DATA -out $output_roi -applyxfm -init $ROI_DIR/reg_dti/epi2highres.mat -interp trilinear;;
			
			dti2hr)		
								output_roi=$ROI_DIR/reg_dti/$roi"_dti"
								if [ "$path_type" = abs ]; then
									input_roi=$roi
								else
									input_roi=$ROI_DIR/reg_dti/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
								if [ $HAS_T2 -eq 1 ]; then 
									$FSLDIR/bin/applywarp -i $input_roi -r $T1_BRAIN_DATA -o $output_roi --warp=$ROI_DIR/reg_t1/dti2highres_warp
								else
									$FSLDIR/bin/flirt -in $input_roi -ref $T1_BRAIN_DATA -out $output_roi -applyxfm -init $ROI_DIR/reg_t1/dti2highres.mat -interp trilinear
								fi;;
								
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
			std2epi) 	
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $RS_EXAMPLEFUNC -o $output_roi --warp=$ROI_DIR/reg_epi/standard2epi_warp;;

			std42epi) 
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard4/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $standard_image -out $ROI_DIR/reg_epi/$roi_name"_standard" -applyisoxfm 2;
								$FSLDIR/bin/applywarp -i $ROI_DIR/reg_epi/$roi_name"_standard" -r $RS_EXAMPLEFUNC -o $output_roi --warp=$ROI_DIR/reg_epi/standard2epi_warp;
								$FSLDIR/bin/imrm $ROI_DIR/reg_epi/$roi_name"_standard";;

			hr2epi) 	
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								echo "the hr2epi NON linear transformation does not exist.....using the linear one"
								$FSLDIR/bin/flirt -in $input_roi -ref $RS_EXAMPLEFUNC -out $output_roi -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -interp trilinear;;
								
			dti2epi)	
								echo "registration type: dti2epi NOT SUPPORTED...exiting";exit;;
								
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			hr2std) 	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $output_roi --warp=$ROI_DIR/reg_t1/highres2standard_warp;;
								
			epi2std)	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $output_roi --warp=$ROI_DIR/reg_standard/epi2standard_warp;;
			
			dti2std)	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_dti/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $output_roi --warp=$ROI_DIR/reg_standard/dti2standard_warp;;

			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			std2std4)	
								output_roi=$ROI_DIR/reg_standard4/$roi_name"_standard4"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								${FSLDIR}/bin/flirt -in $input_roi -ref $standard_image -out $output_roi -applyisoxfm 4;;
								
			epi2std4)	
								output_roi=$ROI_DIR/reg_standard4/$roi_name"_standard"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $ROI_DIR/reg_standard4/$roi_name"_standard2" --warp=$ROI_DIR/reg_standard/epi2standard_warp;
								${FSLDIR}/bin/flirt  -in $ROI_DIR/reg_standard4/$roi_name"_standard2" -ref $standard_image -out $output_roi -applyisoxfm 4
								$FSLDIR/bin/imrm $ROI_DIR/reg_standard4/$roi_name"_standard2";;								
																
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			hr2dti) 	
								output_roi=$ROI_DIR/reg_dti/$roi_name"_dti"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								if [ $HAS_T2 -eq 1 -a `$FSLDIR/bin/imtest $ROI_DIR/reg_t1/highres2dti_warp` = 1 ]; then 
									$FSLDIR/bin/applywarp -i $input_roi -r $ROI_DIR/reg_dti/nobrain_diff -o $output_roi --warp=$ROI_DIR/reg_t1/highres2dti_warp
								else
									echo "did not find the non linear registration from HR 2 DTI, I used a linear one"
									$FSLDIR/bin/flirt -in $input_roi -ref $ROI_DIR/reg_dti/nobrain_diff -out $output_roi -applyxfm -init $ROI_DIR/reg_dti/highres2dti.mat -interp trilinear
								fi;;

			epi2dti)	
#								output_roi=$ROI_DIR/reg_dti/$roi_name"_dti"
#								if [ "$path_type" = abs ]; then
#									input_roi=$roi
#								else
#									input_roi=$ROI_DIR/reg_epi/$roi
#								fi
#								$FSLDIR/bin/applywarp -i $input_roi -r $ROI_DIR/reg_dti/nobrain_diff -o $ROI_DIR/reg_standard4/$roi_name"_standard2" --premat $ROI_DIR/reg_t1/epi2highres.mat --warp=$ROI_DIR/reg_standard/highres2standard_warp --postmat $ROI_DIR/reg_dti/standard2dti.mat;
								echo "registration type: epi2dti NOT SUPPORTED...exiting";exit;;

			std2dti) 	
								output_roi=$ROI_DIR/reg_dti/$roi_name"_dti"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $ROI_DIR/reg_dti/nodif_brain -o $output_roi --warp=$ROI_DIR/reg_dti/standard2dti_warp;;
								
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		esac
	else		# is linear
	
		case $registration_type in

			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			std2hr)		
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
							  $FSLDIR/bin/applywarp -i $input_roi -r $T1_BRAIN_DATA -o $ROI_DIR/reg_t1/$roi_name"_highres" --warp=$ROI_DIR/reg_t1/standard2highres_warp;;
								
			std42hr) 	
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard4/$roi
								fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $standard_image -out $ROI_DIR/reg_t1/$roi_name"_standard" -applyisoxfm 2;
								$FSLDIR/bin/applywarp -i $ROI_DIR/reg_t1/$roi_name"_standard" -r $T1_BRAIN_DATA -o $ROI_DIR/reg_epi/$roi_name"_highres" --warp=$ROI_DIR/reg_t1/standard2highres_warp;
								rm $ROI_DIR/reg_t1/$roi"_standard";;

			epi2hr)		
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								$FSLDIR/bin/flirt -in $input_roi -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/$roi_name"_highres" -applyxfm -init $ROI_DIR/reg_dti/epi2highres.mat -interp trilinear;;
		
			dti2hr)		
								output_roi=$ROI_DIR/reg_t1/$roi_name"_highres"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_dti/$roi
								fi
								if [ $HAS_T2 -eq 1 ]; then 
									$FSLDIR/bin/applywarp -i $input_roi -r $T1_BRAIN_DATA -o $ROI_DIR/reg_t1/$roi"_highres" --warp=$ROI_DIR/reg_t1/dti2highres_warp
								else
									$FSLDIR/bin/flirt -in $input_roi -ref $T1_BRAIN_DATA -out $ROI_DIR/reg_t1/$roi"_highres" -applyxfm -init $ROI_DIR/reg_dti/dti2highres.mat -interp trilinear
								fi;;
								
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			std2epi) 	
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								elsegaz
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $RS_EXAMPLEFUNC -out $output_roi -applyxfm -init $ROI_DIR/reg_epi/standard2epi.mat;;
								
			std42epi) 
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard4/$roi
								fi
								if [ `$FSLDIR/bin/imtest $input_roi` = 0 ]; then echo "error......input_roi ($input_roi) is missing....exiting"; exit; fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $standard_image -out $ROI_DIR/reg_epi/$roi_name"_standard" -applyisoxfm 2;
								$FSLDIR/bin/applywarp -i $ROI_DIR/reg_epi/$roi_name"_standard" -r $RS_EXAMPLEFUNC -o $ROI_DIR/reg_epi/$roi_name"_epi" --warp=$ROI_DIR/reg_epi/standard2epi_warp;
								$FSLDIR/bin/imrm $ROI_DIR/reg_epi/$roi_name"_standard";;

			hr2epi) 	
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"			
								output_roi=$ROI_DIR/reg_epi/$roi_name"_epi"
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								$FSLDIR/bin/flirt -in $input_roi -ref $RS_EXAMPLEFUNC -out $output_roi -applyxfm -init $ROI_DIR/reg_epi/highres2epi.mat -interp trilinear;;
			
			dti2epi)	echo "registration type: dti2epi NOT SUPPORTED...exiting";exit;;

			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			hr2std) 	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $ROI_DIR/reg_standard/$roi_name"_standard" --warp=$ROI_DIR/reg_t1/highres2standard_warp;;
								
			epi2std)	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $ROI_DIR/reg_standard/$roi_name"_standard" --warp=$ROI_DIR/reg_standard/epi2standard_warp;;
								
			dti2std)	
								output_roi=$ROI_DIR/reg_standard/$roi_name"_standard"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_dti/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $standard_image -o $ROI_DIR/reg_standard/$roi_name"_standard" --warp=$ROI_DIR/reg_standard/epi2standard_warp;;

			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			
			epi2std4)	
								output_roi=$ROI_DIR/reg_standard4/$roi_name"_standard"			
								if [ "$path_type" = abs ]; then
									input_roi=$roi
								else
									input_roi=$ROI_DIR/reg_epi/$roi
								fi
								$FSLDIR/bin/flirt -in $input_roi -ref $RS_EXAMPLEFUNC -out $ROI_DIR/reg_standard4/$roi_name"_standard2" -applyxfm -init $ROI_DIR/reg_standard/epi2standard.mat -interp trilinear
								${FSLDIR}/bin/flirt  -in $ROI_DIR/reg_standard4/$roi_name"_standard2" -ref $standard_image -out $output_roi -applyisoxfm 4
								$FSLDIR/bin/imrm $ROI_DIR/reg_standard4/$roi_name"_standard2";;
									
			std2std4)	
								output_roi=$ROI_DIR/reg_standard4/$roi_name"_standard"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								${FSLDIR}/bin/flirt  -in $input_roi -ref $standard_image -out $output_roi -applyisoxfm 4;;
								
			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
								
			hr2dti) 	
								output_roi=$ROI_DIR/reg_dti/$roi_name"_dti"			
								if [ "$path_type" = abs ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi									
								else
									input_roi=$ROI_DIR/reg_t1/$roi
								fi
								if [ $HAS_T2 -eq 1 ]; then 
									$FSLDIR/bin/applywarp -i $input_roi -r $ROI_DIR/reg_dti/nobrain_diff -o $ROI_DIR/reg_dti/$roi_name"_dti" --warp=$ROI_DIR/reg_t1/highres2dti_warp
								else
									$FSLDIR/bin/flirt -in $input_roi -ref $ROI_DIR/reg_dti/nobrain_diff -out $ROI_DIR/reg_dti/$roi_name"_dti" -applyxfm -init $ROI_DIR/reg_dti/highres2dti.mat -interp trilinear
								fi;;
								
			epi2dti)	
								echo "registration type: epi2dti NOT SUPPORTED...exiting";exit;;
	
			std2dti) 	
								output_roi=$ROI_DIR/reg_dti/$roi_name"_dti"			
								if [ "$path_type" = "abs" ]; then
									input_roi=$roi
								elif [ "$path_type" == "rel" ]; then
									input_roi=$SUBJECT_DIR/$roi
								else
									input_roi=$ROI_DIR/reg_standard/$roi
								fi
								$FSLDIR/bin/applywarp -i $input_roi -r $ROI_DIR/reg_dti/nodif_brain -o $ROI_DIR/reg_dti/$roi_name"_dti" --warp=$ROI_DIR/reg_dti/standard2dti_warp;;

			#-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		esac
	fi # if linear

	if [ $(echo "$roi_threshold > 0" | bc) -gt 0 ]; then
		output_roi_name=$(basename $output_roi)
		output_input_roi=$(dirname $output_roi)
		
		$FSLDIR/bin/fslmaths $output_roi -thr $roi_threshold -bin $output_input_roi/mask_$output_roi_name
	
		v1=`$FSLDIR/bin/fslstats $output_input_roi/mask_$output_roi_name -V | awk '{printf($1)}'`
		if [ $v1 -eq 0 ]; then
			if [ ! -z $OUTPUT_REPORT_FILE ]; then
				echo "subj: $SUBJ_NAME, roi: $roi_name ... is empty, thr: $roi_threshold" >> $OUTPUT_REPORT_FILE
			fi
		fi
	fi
done # for roi

echo "=====================> finished processing $0"

