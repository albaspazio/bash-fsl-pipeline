# do group melodic, after having checked the existence of each input file. create template file
check_input_file()
{
  while read line   
  do 
    if [ `$FSLDIR/bin/imtest $line` -eq 0 ]; then
      echo "ERROR: input file ($line) do not exist";
      ALL_OK=0;
    fi	
  done < $file2check
}

check_input_list()
{
	OLD_IFS=$IFS
	IFS=" "
	
	array_images=( $list2check )
	
	for img in ${array_images[@]}
  do 
    if [ `$FSLDIR/bin/imtest $img` -eq 0 ]; then
      echo "ERROR: input file ($img) do not exist";
      ALL_OK=0;
    fi	
  done
  IFS=$OLD_IFS
}

ALL_OK=1

OUTPUT_DIR=$1; shift
template_name=$(basename $OUTPUT_DIR) 

file2check=$1
check_input_file
filelist=$1; shift

list2check=$1
check_input_list
bglist=$1; shift

list2check=$1
check_input_list
masklist=$1; shift


if [ $ALL_OK -eq 0 ]; then
	echo "some input files are missing, group melodic aborted! exiting......."	
	exit
fi

echo "merging background image"
$FSLDIR/bin/fslmerge -t $OUTPUT_DIR/bg_image $bglist
$FSLDIR/bin/fslmaths $OUTPUT_DIR/bg_image -inm 1000 -Tmean $OUTPUT_DIR/bg_image -odt float
echo "merging mask image"
$FSLDIR/bin/fslmerge -t $OUTPUT_DIR/mask $masklist
 
echo "start group melodic !!"
$FSLDIR/bin/melodic -i $filelist -o $OUTPUT_DIR -v --nobet --bgthreshold=10 --tr=$TR_VALUE --report --guireport=$OUTPUT_DIR/report.html --bgimage=$OUTPUT_DIR/bg_image -d 0 --mmthresh=0.5 --Ostats -a concat

echo "creating template description file"
template_file=$GLOBAL_SCRIPT_DIR/melodic_templates/$template_name.sh

echo "template_name=$template_name" > $template_file
echo "TEMPLATE_MELODIC_IC=$OUTPUT_DIR/melodic_IC.nii.gz" >> $template_file
echo "TEMPLATE_MASK_IMAGE=$OUTPUT_DIR/mask.nii.gz" >> $template_file
echo "TEMPLATE_BG_IMAGE=$OUTPUT_DIR/bg_image.nii.gz" >> $template_file
echo "TEMPLATE_STATS_FOLDER=$OUTPUT_DIR/stats" >> $template_file
echo "TEMPLATE_MASK_FOLDER=$OUTPUT_DIR/stats" >> $template_file
echo "str_pruning_ic_id=() # valid RSN: you must set their id values removing 1: if in the html is the 6th RSN, you must write 5!!!!!!" >> $template_file
echo "str_arr_IC_labels=()" >> $template_file
echo "declare -a arr_IC_labels=()" >> $template_file
echo "declare -a arr_pruning_ic_id=()" >> $template_file
