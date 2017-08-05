# the first 4 parameters must be:
# number CPU used, script file name, array of subjects/conditions/events, project name
# the remaining parameters are passed "as-is"
# finally calls: call_multiple_process.sh passing: script name, thread num, project path, array of subj/cond/ev, the remaining parameters.
#===============================================================================================================
declare -i NUM_CPU=$1			# num of thread to use
EXECUTE_SH=$2							# execute_subject_... .sh
declare -a cases=( $3 )		# array containing cases
PROJ_PATH=$4							# proj name
EXTRA_PARAMS=${@:5:$#-4}	# array containing extra parameters (fsf path, num sessions, num events, etc..)
#===============================================================================================================
declare -i NUM_CASES=${#cases[@]}
declare -i CPU=$NUM_CPU-1

declare -i step
declare -i remaining
declare -i start_index

#---------------------------------------------------------------------------------------------------------------
echo "starting multicore processing of $NUM_CASES case(s) with $NUM_CPU core(s)"

declare -a arr_scripts=()
declare -i curr_thr=0
for cond in ${cases[@]}
do
  arr_scripts[$curr_thr]=${arr_scripts[$curr_thr]}$cond-
  curr_thr=$curr_thr+1
  if  [ $curr_thr -eq $NUM_CPU ]; then
    curr_thr=0
  fi
done

# eg 5 cpu & 9 cond:
#arr_scripts[0]=cond1-cond6
#arr_scripts[1]=cond2-cond7
#arr_scripts[2]=cond3-cond8
#arr_scripts[3]=cond4-cond9
#arr_scripts[4]=cond5-



for((thr=0; thr<$NUM_CPU; thr++)); 
do
  OLD_IFS=$IFS
  IFS="-"
  CASES_ARR=( ${arr_scripts[$thr]} )
  sarr=`echo ${CASES_ARR[@]}`
  IFS=$OLD_IFS
  echo call_thr$thr" processes:$sarr"
  . $MULTICORE_SCRIPT_DIR/call_multiple_process.sh $thr $EXECUTE_SH "$sarr" $PROJ_PATH "$EXTRA_PARAMS" &
done 
