#!/bin/bash

# take a 4D image (2xS images) and create S images according to DIFF_MODE:
#  		-time:		difference between => for ((s=0, s<S, s++));  (2*s+1) - 2*s 
# 		-subj:		difference between => (s + S) - s 
# 
# call them as the subjects label list passed as input
# outputs
# 	-4d):		return one 4D [with S volumes]
#   -3d):		return S * 3D images

INPUT_IMAGE=$1; shift

fname=$(basename $INPUT_IMAGE)

OUTPUT_MODE=4d
DIFF_MODE=subj
verbose=0

POSTFIX_NAME=""
OUTPUT_FILE_NAME=${fname%.*}

while [ ! -z "$1" ]
do
  case "$1" in
    	-diffmode)	DIFF_MODE=$2; shift;;	
    	-opfn)		POSTFIX_NAME=$2; shift;;	
    	-omode)		OUTPUT_MODE=$2; shift;;
    	-ofn) 		OUTPUT_FILE_NAME=$2; shift;;
    	-v)			verbose=1;;
    	*)			break;;
	esac
	shift
done

declare -a SUBJECTS_LABEL=( $@ )
declare -i num_labels=${#SUBJECTS_LABEL[@]}

OUTPUT_FILE_NAME=$OUTPUT_FILE_NAME$POSTFIX_NAME
CURR_DIR=`pwd`

# ------------------------------------------------------------------
# CHECKS
if [ `$FSLDIR/bin/imtest $INPUT_IMAGE` = 0 ]; then
	echo "error in create_longitudinal_diff_images:  input file ($INPUT_IMAGE) does not exist....exiting"
	exit;
fi

declare -i num_vol=`$FSLDIR/bin/fslnvols $INPUT_IMAGE`
declare -i num_subj=$num_vol/2

if [ $num_subj -ne $num_labels ]; then 
	echo "ERROR in create_longitudinal_diff_images: num input labels does not coincide with half image's volumes number"
	exit
fi
# ------------------------------------------------------------------
input_dir=${INPUT_IMAGE%/*}

rndname=$(( $RANDOM % (100000 + 1 - 1) + 1 ))
temp_dir=$input_dir/temp$rndname
mkdir $temp_dir
cd $temp_dir

$FSLDIR/bin/fslsplit $INPUT_IMAGE "temp_"

declare -i vol=0
declare -i nextvol=1
declare -i s=0

for (( s=0; s<$num_subj ; s++ ))
do
	outimg=${SUBJECTS_LABEL[s]}$POSTFIX_NAME

	if [ "$DIFF_MODE" == "time" ]; then   # (2*s+1) - 2*s 
#		echo time
		vol=2*$s
		nextvol=2*$s+1
	else				
#		echo subj											# (s + S) - s 
		vol=$s+$num_subj
		nextvol=$s
	fi	

	if [ $verbose -eq 1 ];then
		echo "subtracting  $nextvol - $vol"	
	fi
	nvol=`$FSLDIR/bin/zeropad $vol 4`
	img1=temp_$nvol
	
	nnextvol=`$FSLDIR/bin/zeropad $nextvol 4`
	img2=temp_$nnextvol
	
	$FSLDIR/bin/fslmaths $img2 -sub $img1 subj_$s
done

case "$OUTPUT_MODE" in

	4d)		$FSLDIR/bin/fslmerge -t $input_dir/$OUTPUT_FILE_NAME subj*
			rm -rf $temp_dir;;

	3d)		for (( s=0;s<$num_subj; s++ ));
			do
				mv subj_$s.nii.gz ${SUBJECTS_LABEL[s]}"_"$OUTPUT_FILE_NAME.nii.gz 
			done
			rm temp*;;
	*)		echo "unrecognized option: $OUTPUT_MODE";;
	
esac

cd $CURR_DIR

