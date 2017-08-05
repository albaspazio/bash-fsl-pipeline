declare -a subj2remove=(4 7 13)
declare -i num_cope=6
declare -i num_subj=13
SECOND_LEVEL_DIR=/home/data/MRI/projects/sassi/group_analysis/2nd_fixed_12gng_13ev_6con.gfeat

declare -i next_id=0
declare -i curr_id=0
declare -i new_id=0
declare -i idremoved=0

for(( c=1; c<=$num_cope;c++ ))
do
  idremoved=0
  for subj in ${subj2remove[@]}
  do
    curr_id=$subj
    curr_id=$curr_id-$idremoved
    echo "removing subject num $subj (currently renamed to $curr_id)"
    rm $SECOND_LEVEL_DIR/cope$c.feat/cluster_mask_zstat$curr_id.nii.gz
    rm $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$curr_id"_"std.html
    rm $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$curr_id"_"std.txt
    rm $SECOND_LEVEL_DIR/cope$c.feat/lmax_zstat$curr_id"_"std.txt
    rm $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$curr_id.nii.gz
    rm $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$curr_id.png
    rm $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$curr_id.nii.gz
    rm $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$curr_id.vol
    rm $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$curr_id.nii.gz
    next_id=$curr_id+1
    curr_num_subj=$num_subj-$idremoved
    for (( g=next_id; g<=curr_num_subj; g++))
    do
      new_id=$g-1
      echo " renaming elements to $new_id"
      mv $SECOND_LEVEL_DIR/cope$c.feat/cluster_mask_zstat$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/cluster_mask_zstat$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$g"_"std.html $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$new_id"_"std.html
      mv $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$g"_"std.txt $SECOND_LEVEL_DIR/cope$c.feat/cluster_zstat$new_id"_"std.txt
      mv $SECOND_LEVEL_DIR/cope$c.feat/lmax_zstat$g"_"std.txt $SECOND_LEVEL_DIR/cope$c.feat/lmax_zstat$new_id"_"std.txt
      mv $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$g.png $SECOND_LEVEL_DIR/cope$c.feat/rendered_thresh_zstat$new_id.png
      mv $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$g.vol $SECOND_LEVEL_DIR/cope$c.feat/thresh_zstat$new_id.vol
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/pe$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/tdof_t$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/tstat$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/varcope$new_id.nii.gz
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/zstat$new_id.nii.gz    
      mv $SECOND_LEVEL_DIR/cope$c.feat/stats/cope$g.nii.gz $SECOND_LEVEL_DIR/cope$c.feat/stats/zflame1uppertstat$new_id.nii.gz    
  done
    idremoved=$idremoved+1
  done
done

 