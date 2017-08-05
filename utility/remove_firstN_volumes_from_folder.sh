folder=$1
num_vol2remove=$2

cd $folder

declare -i start=0
declare -i new_vol=0

for image in ls *.nii
do
  if [[ $image = "ls" || $image = "*.nii" ]]; then continue; fi

  image_name=$(`echo remove_ext $image`)
  num_char=${#image_name}
  start=($num_char-4)
  orig_vol=${image_name:$start:4}		# last 4 chars

  if [ $orig_vol -lt $num_vol2remove ]; then
    echo "removing $image"
    rm $image
  else
    base_name=${image_name:0:$start}
    new_vol=$(echo $orig_vol-$num_vol2remove | bc)
    nvol=`$FSLDIR/bin/zeropad $new_vol 4`
    echo "renaming $image in $base_name$nvol.nii"
    mv $image $base_name$nvol.nii
  fi
done