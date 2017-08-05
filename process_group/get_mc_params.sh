#!/bin/bash

PROJ_DIR=$1; shift;
arr_population=$1; shift;

while [ ! -z "$1" ]
do
  case "$1" in
      -hdr) hdr=$2;	shift;;
			-ofn)	output_file=$2;	shift;;
      *) break;;
  esac
  shift
done

declare -a arr_abs=();
declare -a arr_rel=();

declare -i cnt=0;
for SUBJ_NAME in ${arr_population[@]}
do
	echo "$SUBJ_NAME"
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
	
	abs_disp=$MC_ABS_DISPL
	rel_disp=$MC_REL_DISPL
	
	read line_abs < $abs_disp
	declare -i len=${#line_abs};    len=$len-1;    line_abs=${line_abs[@]:0:len}	# remove last character (/r)
	
	read line_rel < $rel_disp
	declare -i len=${#line_rel};    len=$len-1;    line_rel=${line_rel[@]:0:len}	# remove last character (/r)		

	line="$SUBJ_NAME	$hdr$line_abs	$line_rel"

	echo "$line" >> $output_file
	
	arr_abs[cnt]=$line_abs;
	arr_rel[cnt]=$line_rel;

	cnt=$cnt+1
done

sum_abs=0;
sum_rel=0;
for (( n=0; n<$cnt; n++ ))
do
		sum_abs=$(echo $sum_abs + ${arr_abs[n]} | bc)
		sum_rel=$(echo $sum_rel + ${arr_rel[n]} | bc)
done

mean_abs=$(echo "scale=3; $sum_abs/$cnt" | bc)
mean_rel=$(echo "scale=3; $sum_rel/$cnt" | bc)

echo "abs displ: $mean_abs"
echo "rel displ: $mean_rel"
#--------------------------------------------------------

