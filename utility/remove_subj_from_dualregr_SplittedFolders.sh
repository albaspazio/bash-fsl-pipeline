# possible call: sh remove_subj_from_dualregr.sh /home/data/MRI/projects/colegios/group_analysis/melodic/19subj_dualregr2.gica/dual_regr/pruned 19 12 /home/data/MRI/projects/colegios/group_analysis/melodic/19subj_dualregr2.gica/dual_regr/pruned17 "5 8 12"
DR_ROOT_FOLDER=$1
declare -i num_subj=$2

OLDIFS=$IFS; IFS=","
declare -a commasep_IC_list=( $3 )   #  "DMN,ATN,EXEC, ...etc"
IFS=$OLDIFS

output_dir=$4
declare -a subj2remove=( $@ ) # 0 based array

declare -i removed_subject=0
declare -i removed_subject_ic=0
declare -i new_subj_num=0

if [ ! -d $output_dir ]; then 
  mkdir $output_dir
fi

echo "remove_subj_from_dualregr_SplittedFolders:"
echo DR_ROOT_FOLDER: $DR_ROOT_FOLDER
echo num_subj: $num_subj
echo commasep_IC_list: ${commasep_IC_list[@]}
echo output_dir: $output_dir
echo subj2remove:  ${subj2remove[@]}
# remove volumes from dr_stage2_ic0000 within each RSN subfolder of $DR_ROOT_FOLDER

for ic in ${commasep_IC_list[@]}
do
	echo "processing $ic"
  removed_subject=0
  
	cd $output_dir; mkdir -p $ic; cd $ic;
	
	input_image=$DR_ROOT_FOLDER/$ic/dr_stage2_ic0000
	declare -i NVOL=`$FSLDIR/bin/fslval $input_image dim4`
	if [ $NVOL -ne $num_subj ]; then
		echo "ERROR in remove_subj_from_dualregr_SplittedFolders....inputted subj num does not coincide with MRI image volumes....exiting"	
		exit
	fi
		  
  fslsplit $input_image splitted"_"		# files go to : $output_dir/$ic/splitted_****

  for (( s=0; s<$num_subj; s++ ))
  do
		  do_remove=0
		  for rs in ${subj2remove[@]}
		  do    					# echo "rs:"$rs"|s:"$s
		    if [[ $rs = $s ]]; then
					removed_subject=($removed_subject+1)     	# echo removed_subject:$removed_subject
					do_remove=1
					break
		    fi
		  done
		  new_subj_num=$(echo "$s-$removed_subject" | bc);
		  if [ $do_remove -eq 0 -a $s -ne $new_subj_num ]; then
		    orig_subj=`$FSLDIR/bin/zeropad $s 4`
		    new_subj=`$FSLDIR/bin/zeropad $new_subj_num 4`
		    mv $output_dir/$ic/splitted_$orig_subj.nii.gz $output_dir/$ic/splitted_$new_subj.nii.gz
		  fi
  done
  fslmerge -t dr_stage2_ic0000 splitted_*
	cp $DR_ROOT_FOLDER/$ic/mask.nii.gz $output_dir/$ic/mask.nii.gz
	cp $DR_ROOT_FOLDER/$ic/melodic_IC.nii.gz $output_dir/$ic/melodic_IC.nii.gz
  rm -rf $output_dir/$ic/splitted*
done 



