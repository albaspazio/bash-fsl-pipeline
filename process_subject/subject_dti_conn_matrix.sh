#!/bin/bash

# input:
#
# output:	
#
# task:		

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

ATLAS_NAME=$1; shift  # located in $ROI_DIR/reg_dti/
NUM_ROI=$1; shift
recon_params= " -b 1000 -b0 1 -p 3 -sn 1 -ot nii"

ATLAS_PATH=$ROI_DIR/reg_dti/${ATLAS_NAME}_dti

if [ `$FSLDIR/bin/imtest $ATLAS_PATH` = 0]; then
	echo "error subject_dti_conn_matrix: Subj $SUBJ_NAME, Atlas file is missing ($ATLAS_PATH)"
fi

CURR_DIR=`pwd`

main()
{
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh


	usage="type: connectome_dti35_e -s [SCAN folder] -m [MATRICES folder] "


	while getopts ":h:s:l:m:p" flag; do
		case $flag in
			h) echo $usage; exit ;;
			s) scan=$OPTARG;;
			m) matrices_dir=$OPTARG;;
			p) recon_params=$OPTARG;;
		esac
	done


	mkdir -p $TRACKVIS_DIR
	
	'cp' $DTI_DIR/bvals* $DTI_DIR/bvecs* $TRACKVIS_DIR
	gunzip -f $TRACKVIS_DIR/bvecs* $TRACKVIS_DIR/bvals*

	awk -f $VTK_TRANSPOSE_FILE $TRACKVIS_DIR/bvecs > $TRACKVIS_DIR/$TRACKVIS_TRANSPOSED_BVECS

	if [ -f $TRACKVIS_DIR/dti.trk ];	then
		echo dtk tractography already performed
	else
		mkdir -p $TRACKVIS_DIR/tmp
		
		cd $TRACKVIS_DIR
		
		$TRACKVIS_BIN/dti_recon "$DTI_DIR/$DTI_EC_IMAGE_LABEL.nii.gz" "dti" -gm "$TRACKVIS_DIR/$TRACKVIS_TRANSPOSED_BVECS" $recon_params #-b 1000 -b0 1 -p 3 -sn 1 -ot nii 
		$TRACKVIS_BIN/dti_tracker "dti" "$TRACKVIS_DIR/tmp/track_tmp.trk" -at 45 -iz -m "$DTI_DIR/$DTI_FIT_LABEL"_"fa.nii" 0.15 1 -m2 "$DTI_DIR/nodif_brain_mask.nii" -fact -it nii 
		$TRACKVIS_BIN/spline_filter "$TRACKVIS_DIR/tmp/track_tmp.trk" 1 "$TRACKVIS_DIR/dti.trk"

		cd $CURR_DIR
		
		'rm' -r $TRACKVIS_DIR/tmp

		gzip -f $TRACKVIS_DIR/*nii*
		$FSLDIR/bin/fslmaths $TRACKVIS_DIR/dti_e2 -add $TRACKVIS_DIR/dti_e3 -div 2 $TRACKVIS_DIR/dti_e23; 
	fi

	if [ `$FSLDIR/bin/imtest ${ATLAS_PATH}_$NUM_ROI` = 0 ]; then
		for (( roi=1; roi<=$NUM_ROI; roi++ ))
		do 
			echo $roi; 
			$FSLDIR/bin/fslmaths $ATLAS_PATH -thr $roi ${ATLAS_PATH}_${roi}; 
			$FSLDIR/bin/fslmaths ${ATLAS_PATH}_${roi} -uthr $roi ${ATLAS_PATH}_${roi}; 
		done
	fi

	mkdir $TV_MATRICES_DIR
	declare -i jj=1
	if [ -f $TV_MATRICES_DIR/fa_AM.mat ]; then 
		echo trackvis matrices already calculated
	else
		for (( i=1; i<=$NUM_ROI; i++ ))
		do
			for (( j=1; j<= $NUM_ROI; j++ ))
			do 
				res[jj]=`$TRACKVIS_BIN/track_vis $TRACKVIS_DIR/dti.trk -roi ${ATLAS_PATH}_${i}.nii.gz -roi2 ${ATLAS_PATH}_${j}.nii.gz -o $TRACKVIS_DIR/currTract.trk -ov $TRACKVIS_DIR/currTract.img -nr | grep "Number of tracks to render" | awk '{printf($6)}'`
				if [ ${res[jj]} -gt 0 ];then
					fa[jj]=`$FSLDIR/bin/fslstats $TRACKVIS_DIR/dti_fa -k $TRACKVIS_DIR/currTract -M` 
				else
					fa[jj]=NaN  
				fi

				if [ ${res[jj]} -gt 0 ];then
					md[jj]=`$FSLDIR/bin/fslstats $TRACKVIS_DIR/dti_adc -k $TRACKVIS_DIR/currTract -M` 
				else
					md[jj]=NaN  
				fi
	
				if [ ${res[jj]} -gt 0 ];then
					axd[jj]=`$FSLDIR/bin/fslstats $TRACKVIS_DIR/dti_e1 -k $TRACKVIS_DIR/currTract -M` 
				else
					axd[jj]=NaN  
				fi
	
				if [ ${res[jj]} -gt 0 ];then
					radd[jj]=`$FSLDIR/bin/fslstats $TRACKVIS_DIR/dti_e23 -k $TRACKVIS_DIR/currTract -M` 
				else
					radd[jj]=NaN
				fi
	
				$FSLDIR/bin/imrm $TRACKVIS_DIR/currTract
				'rm' $TRACKVIS_DIR/currTract.trk
				jj=$jj+1
			done 
			echo ${res[*]} >> $TV_MATRICES_DIR/AM.mat
			echo ${fa[*]} >> $TV_MATRICES_DIR/fa_AM.mat
			echo ${md[*]} >> $TV_MATRICES_DIR/md_AM.mat
			echo ${axd[*]} >> $TV_MATRICES_DIR/axd_AM.mat
			echo ${radd[*]} >> $TV_MATRICES_DIR/radd_AM.mat
		done
	fi
}

main $@
