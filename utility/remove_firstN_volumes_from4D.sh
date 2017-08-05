input_dir=$1
image_name=$2
num_vol2remove=$3

cd $input_dir
fslsplit $image_name temp

for (( vol=0; vol<$num_vol2remove; vol++ ))
do
  nvol=`$FSLDIR/bin/zeropad $vol 4`
  rm temp$nvol.nii.gz
done

image_name=$(`echo remove_ext $image_name`)
rm $image_name.nii.gz
fslmerge -t $image_name temp*
gzip -d $image_name.nii.gz

rm *.gz