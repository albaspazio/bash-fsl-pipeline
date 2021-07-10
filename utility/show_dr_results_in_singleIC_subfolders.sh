# I can filter according to:
# the sub-analysis wildcard  (e.g. analysisdir/RSNX/---->>>Fear_x_age<-------/...images....)
# the stat image  (e.g. analysisdir/RSNX/Fear_x_age/*image_root_name*)


INPUT_FOLDER=$1;shift
if [ ! -d $INPUT_FOLDER ]; then echo "ERROR: input dir ($INPUT_FOLDER) not present"; exit; fi

#RSN_LABEL=${PWD##*/}
RSN_LABEL=$(basename $INPUT_FOLDER)
parent_folder="$(dirname "$INPUT_FOLDER")"
mkdir -p $parent_folder/results

OUTPUT_MASK_RESULT_ROOT_PATH=""; 
result_file=$parent_folder/results/RSN_$RSN_LABEL"_results.txt"
subanalysis_wilcard=""  # e.g. "Fear"
image_root_name="corrp"
CALC_SIGN_VOL=0;
SHOW_IMAGE=0
WRITE_ONLY_SIGNIFICANT=0
THRESH_VALUE="0.95"

while [ ! -z "$1" ]
do
  case "$1" in
		-res)			result_file=$2; shift;;
		-ifn)			image_root_name=$2; shift;;
		-bgimg)		BACKGROUND_IMAGE=$2; shift;;
		-bgimg2)	BACKGROUND_IMAGE2=$2; shift;;
		-thr)			THRESH_VALUE="$2"; shift;;
		-omr)			OUTPUT_MASK_RESULT_ROOT_PATH=$2; 
							mkdir -p $OUTPUT_MASK_RESULT_ROOT_PATH; shift;;
		-vol)			CALC_SIGN_VOL=$2; shift;;
		-showimg)	SHOW_IMAGE=$2; shift;;
		-wrsign)	WRITE_ONLY_SIGNIFICANT=$2;shift;;		
		-saw)			subanalysis_wilcard=$2;shift;;
		*)  break;;
	esac
	shift
done
#=======================================================================================================
echo "Explored root folder:  $INPUT_FOLDER" > $result_file
echo "significance above : $THRESH_VALUE" >> $result_file
echo "RSN network: $RSN_label" >> $result_file
echo "all contrasts and all analysis subdirs" >> $result_file
echo "--------------------------------------------------------------------------------------" >> $result_file; 
echo "" >> $result_file; echo "" >> $result_file; echo "" >> $result_file

parse_image ()
{
  image_name=$(basename $image)		
	image_path=$(dirname $image)
	
	max=`fslstats $image -R | awk '{print $2}'`
	if [ -n "$THRESH_VALUE" -a -n "$max" ]; then
		result=$(awk -vn1="$THRESH_VALUE" -vn2="$max" 'BEGIN{print (n1<n2)?1:0 }')
		if [ "$result" -eq 1 ]; then
			IMAGES_LIST="$IMAGES_LIST $image -b $THRESH_VALUE,1 -l Red-Yellow"
			echo "--------------------------------------------------------------------------------------" >> $result_file
			echo "IC label:$RSN_label, image:$image_name, --------> max:$max*" >> $result_file
			echo "--------------------------------------------------------------------------------------" >> $result_file
			raw_tstats=${image/_tfce_corrp/}				# take access to raw_tstats image
			raw_image_name=$(basename $raw_tstats)	# get its name
			if [ -f $raw_tstats ]; then
				# calculate cluster info over uncorrected stat image, but spatially masked as the corrected thresholded
				# hence I create a temporary copy: masked as the significant corrected map, binarized and multiplied by the raw values of the uncorrected map
				$FSLDIR/bin/fslmaths $image -thr $THRESH_VALUE -bin -mul $raw_tstats $image_path/temp_$raw_image_name	
				$FSLDIR/bin/cluster -i $image_path/temp_$raw_image_name -t 0.0001 -o cluster_index --olmax=$image"_"localmax.txt --mm >> $result_file
				echo "--------------------------------------------------------------------------------------" >> $result_file
				cat $image"_"localmax.txt >> $result_file
				echo "" >> $result_file;
				rm $image"_"localmax.txt
				rm $image_path/temp_$raw_image_name
			fi
#				echo "@@@@@$OUTPUT_MASK_RESULT_ROOT_PATH - $image"			
			if [ ! -z $OUTPUT_MASK_RESULT_ROOT_PATH ]; then
				image_label=${image_name/mult_cov_/}
				image_label=${image_label/_tfce_corrp_tstat/}
		
				$FSLDIR/bin/fslmaths $image -thr $THRESH_VALUE -bin $OUTPUT_MASK_RESULT_ROOT_PATH/$image_name
			fi 	
			
			if [ $CALC_SIGN_VOL -eq 1 ]; then				
				gigi=`$FSLDIR/bin/fslstats $image -l $THRESH_VALUE -V`
				echo "volume of supra-threshold voxels: $gigi"	>> $result_file			
			fi
			echo "" >> $result_file; echo "" >> $result_file

		else
			if [[ $WRITE_ONLY_SIGNIFICANT -eq 0 ]]; then
				echo "IC label:$RSN_label, image:image_root_name$ncon, max:$max" >> $result_file
			fi
		fi
	fi
}
# ====================================================================================================================================
# ====================================================================================================================================
# ====================================================================================================================================
# ====================================================================================================================================
IMAGES_LIST=""
MERGE_LIST=""
 
for image in $INPUT_FOLDER/*$image_root_name*
do
	parse_image;
done

for sub_dir in $INPUT_FOLDER/*$subanalysis_wilcard*
do
	if [ -d $sub_dir ]; then	
		echo "--------------------------------------------------------------------------------------" >> $result_file
		echo " - analysis subfolder: $(basename $sub_dir)" >> $result_file
		echo "--------------------------------------------------------------------------------------" >> $result_file;echo "" >> $result_file
		for image in $(ls $sub_dir/*$image_root_name*)
		do
			parse_image
		done	
	fi
done
		
if [[ $IMAGES_LIST != "" ]]; then
  if [ $SHOW_IMAGE -eq 1 ]; then
    echo "displaying folder $INPUT_FOLDER"
    
    if [ -f $FSLDIR/bin/fslview_deprecated ]; then $FSLDIR/bin/fslview_deprecated $BACKGROUND_IMAGE $IMAGES_LIST & 
    else  fslview_deprecated $BACKGROUND_IMAGE $IMAGES_LIST & 
    fi
    
    echo "--------------------------------------------------------------------------------------" >> $result_file
    echo "fslview $BACKGROUND_IMAGE $BACKGROUND_IMAGE2 $IMAGES_LIST &" >> $result_file
    echo "--------------------------------------------------------------------------------------" >> $result_file
  fi
else
  rm $result_file
fi

