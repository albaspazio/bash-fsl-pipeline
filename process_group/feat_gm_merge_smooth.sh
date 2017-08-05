#!/bin/sh

OUT=$1
GMlist_std2=$2
GMlist_std4=$3

# concatenate and de-mean GM images
echo Running concatenation of all standard space GM images

if [ ! -f $OUT"_standard" ]; then 
	${FSLDIR}/bin/fslmerge -t $OUT"_standard" $GMlist_std2
	${FSLDIR}/bin/fslmaths $OUT"_standard" -Tmean -mul -1 -add $OUT"_standard" $OUT"_standard"
fi

if [ ! -f $OUT"_standard4" ]; then 
	${FSLDIR}/bin/fslmerge -t $OUT"_standard4" $GMlist_std4
	${FSLDIR}/bin/fslmaths $OUT"_standard4" -Tmean -mul -1 -add $OUT"_standard4" $OUT"_standard4"
fi
