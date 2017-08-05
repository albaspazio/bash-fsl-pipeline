#!/bin/bash

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

IN_TYPE=""
IN=$T1_BRAIN_DATA
OUTPUT_DIR_PATH=""
OUTPUT_FILE_NAME=""
REF_BRAIN_MASK=""
REF_MASK_STRING=""
while [ ! -z "$1" ]
do
  case "$1" in
			-in)			IN_TYPE=$2; shift;;    #  -t1 , -t1_brain
      -ref) 		REF_BRAIN=$2; shift;;
			-refmask)	REF_BRAIN_MASK=$2; 
								REF_MASK_STRING=" --refmask=$REF_BRAIN_MASK"; shift;;
			-ofn)			OUTPUT_FILE_NAME=$SUBJ_NAME$2; shift;;
			-odp)			OUTPUT_DIR_PATH=$2; 
								if [ ! -d $OUTPUT_DIR_PATH ]; then 
									echo "===================================>> subject_fnirt: output dir path does not exist....creating it !!"
									mkdir -p $OUTPUT_DIR_PATH
								fi
								shift;;
      *) break;;
  esac
  shift
done

if [ ! -z $IN_TYPE ]; then 
	case "$IN_TYPE" in
			-t1)				IN=$T1_DATA; shift;;    
			-t2_brain)	IN=$T2_BRAIN_DATA; shift;;
			-t2)				IN=$T2_DATA; shift;;
		  *) break;;
	esac
fi

[ -z $OUTPUT_DIR_PATH ] && OUTPUT_DIR_PATH=$(dirname $REF_BRAIN)

s=${IN##*/}
in_name=${s%.txt}

s=${REF_BRAIN##*/}
ref_name=${s%.txt}

[ -z $OUTPUT_FILE_NAME ] && OUTPUT_FILE_NAME=$in_name"_2_"$ref_name

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
$FSLDIR/bin/flirt -in $IN -ref $REF_BRAIN -omat $OUTPUT_DIR_PATH/$OUTPUT_FILE_NAME.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear
$FSLDIR/bin/fnirt --iout=$OUTPUT_DIR_PATH/$OUTPUT_FILE_NAME --in=$IN --aff=$OUTPUT_DIR_PATH/$OUTPUT_FILE_NAME.mat --ref=$REF_BRAIN $REF_MASK_STRING
