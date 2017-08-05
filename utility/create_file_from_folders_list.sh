#!/bin/bash


#==================================================================================
# usage  .../create_subjects_file_from_filesystem.sh PROJ_DIR OUTPUT_FILE_NAME
#==================================================================================

if [ $# -lt 2 -o $# -gt 3 ]
then 
	echo "error in $0"
	echo "usage  .../create_subjects_file_from_filesystem.sh SUBJECTS_DIR OUTPUT_FILE_NAME wildcard_filter ...."
	echo "exiting...."
  exit
elif [ $# -eq 2 ]; then
	filter=*
fi

dir2scan=$1
output_file_path=$2
filter=$3

if [ ! -d $dir2scan ]
then
	echo "create_subjects_file_from_filesystem : input dir do not exist...exiting"
	exit
fi

outdir=$(dirname $output_file_path)
if [ ! -d  $outdir ]
then
	echo "create_subjects_file_from_filesystem : dir containing outfile do not exist...exiting"
	exit
fi
#-------------------------------------------------------------------------------------

cd $dir2scan

echo "subj	gender	age" > $output_file_path
for subj in ls $filter
do
	if [ -d $dir2scan/$subj ]
	then
		echo "$subj" >> $output_file_path
	fi
done





