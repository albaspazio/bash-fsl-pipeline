# possible call: sh remove_subj_from_dualregr.sh /home/data/MRI/projects/colegios/group_analysis/melodic/19subj_dualregr2.gica/dual_regr/pruned 19 12 /home/data/MRI/projects/colegios/group_analysis/melodic/19subj_dualregr2.gica/dual_regr/pruned17 "5 8 12"
dr2_folder=$1
num_subj=$2
num_ic=$3
output_dir=$4
declare -a subj2remove=( $5 ) # 0 based array

declare -i removed_subject=0
declare -i removed_subject_ic=0
declare -i new_subj_num=0

if [ ! -d $output_dir ]; then 
  mkdir $output_dir
fi


# remove volumes from dr_stage2_icXXXX
cd $output_dir
for (( ic=0; ic<$num_ic; ic++ ))
do
  removed_subject=0
  n_ic=`$FSLDIR/bin/zeropad $ic 4`
  
  fslsplit $dr2_folder/dr_stage2_ic$n_ic splitted_$n_ic"_"

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
      mv $output_dir/splitted_$n_ic"_"$orig_subj.nii.gz $output_dir/splitted_$n_ic"_"$new_subj.nii.gz
    fi
  done
  fslmerge -t dr_stage2_ic$n_ic splitted_$n_ic"_"*
done 


# remove dr_stage2_pruned_subjectsXXXXX
removed_subject=0
do_remove=0
for (( s=0; s<$num_subj; s++ ))
do
  do_remove=0
  for rs in ${subj2remove[@]}
  do    					# echo "rs:"$rs"|s:"$s
    if [[ $rs = $s ]]; then
      removed_subject=($removed_subject+1)	# echo removed_subject:$removed_subject"|with subj:$s"
      do_remove=1
      break
    fi
  done
  new_subj_num=$(echo "$s-$removed_subject" | bc); #  echo "removed_subject:$removed_subject|new_subj_num:"$new_subj_num"|s:"$s
  if [ $do_remove -eq 0 ]; then
    orig_subj=`$FSLDIR/bin/zeropad $s 5`
    new_subj=`$FSLDIR/bin/zeropad $new_subj_num 5`
    cp $dr2_folder/dr_stage2_pruned_subject$orig_subj.nii.gz $output_dir/dr_stage2_pruned_subject$new_subj.nii.gz
  fi
done

cp $dr2_folder/mask.nii.gz $output_dir/mask.nii.gz
cp $dr2_folder/melodic_pruned_IC.nii.gz $output_dir/melodic_pruned_IC.nii.gz

rm -rf $output_dir/splitted*