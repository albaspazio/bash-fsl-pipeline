#!/bin/sh
# ==================================================================================
# input:
#		$1	subject label  	:
#	  $2	proj_dir				:
# 	$3	structures			:
#		$4	t1 brain				:

usage_string="Usage: $0 subj_label proj_dir -s \"R_Thal,L_Thal\" -b /.../brain_image.nii.gz"
# ====== set init params =============================================================================
SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

t1_image=$T1_BRAIN_DATA
output_dir_name=""
structs=""
output_reg_dir_name=""
reg_type=""

while [ ! -z "$1" ]
do
  case "$1" in
      -structs) 	STRUCTURES=$2
      						structs="-s $STRUCTURES";		shift;;
      -mpr) 			t1_image=$2;								shift;;
      -odn)				output_dir_name=$2/; 				shift;;
      *) 					break;;
  esac
  shift
done

t1_image_label=`${FSLDIR}/bin/remove_ext $t1_image`
t1_image_label=${t1_image_label##*/}

mkdir -p $FIRST_DIR
echo "$SUBJ_NAME: FIRST (of $t1_image_label  $structs $output_dir_name)"

$FSLDIR/bin/first_flirt $t1_image $FIRST_DIR/$t1_image_label"_to_std_sub"
$FSLDIR/bin/run_first_all -i $t1_image -o $FIRST_DIR/$t1_image_label -d -a $FIRST_DIR/$t1_image_label"_to_std_sub.mat" -b $structs 

mkdir -p $ROI_DIR/reg_t1

OLD_IFS=$IFS; IFS=","
declare -a arr_struct=( $STRUCTURES )	
IFS=$OLD_IFS

mkdir -p $ROI_DIR/reg_t1/$output_dir_name
for struct in ${arr_struct[@]}
do
	mv $FIRST_DIR/$t1_image_label-$struct"_first.nii.gz" $ROI_DIR/reg_t1/$output_dir_name"mask_"$struct"_highres.nii.gz"
done


