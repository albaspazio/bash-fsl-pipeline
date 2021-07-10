
# take a folder and remove the i-th volume (1-based) from all the images contained within the folder


INPUT_FOLDER=$1; shift
if [ ! -d $INPUT_FOLDER ]; then echo "ERROR: input dir ($INPUT_FOLDER) not present"; exit; fi

declare -i volume_to_remove=$1; shift

#=======================================================================================================
echo "input folder: $INPUT_FOLDER" 

declare -i nv=0
declare -i length1=$volume_to_remove-1


remove_vol(){
	nv=$(echo `fslnvols $1`)
	if [ $nv -gt 1 -a $nv -gt $2 ]; then	
		
		ff=$(echo `remove_ext $1`)
		
		mv $ff".nii.gz" $ff"_copy.nii.gz"
		cp $ff"_copy.nii.gz" $ff"_old.nii.gz"
		fslroi $ff"_copy" $ff"_temp1" 0 $length1
		fslroi $ff"_copy" $ff"_temp2" $2 -1
		fslmerge -t $ff *temp*
		rm $INPUT_FOLDER/*temp*
		rm $INPUT_FOLDER/*copy*
		mv $INPUT_FOLDER/*old* $INPUT_FOLDER/old
	fi
}

mkdir -p $INPUT_FOLDER/old

for f in $INPUT_FOLDER/*
do
	remove_vol $f $volume_to_remove
done
