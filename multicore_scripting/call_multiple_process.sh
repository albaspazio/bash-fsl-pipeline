# called by define_thread_process:
# call the final script with the following parameters: proj_name, cond_name, extra_param

THR_NUM=$1
EXECUTE_SH=$2		# /home/data/MRI/script/1st_level/execute_subject_... .sh
CASE_ARR2=( $3 )
PROJ_PATH=$4
EXTRA_PARAMS=$5



declare -i cond=0
declare -i NUM_CASE=${#CASE_ARR2[@]}
echo "thr$THR_NUM, processing $NUM_CASE conditions" # : ${CASE_ARR2[@]}"
# for SUBJ_NAME in "${SUBJ_ARR[@]}"

for (( cond=0; cond<$NUM_CASE; cond++ )) 
do
  SCRIPT_BASE_NAME=`basename $EXECUTE_SH`
  CASE_NAME=${CASE_ARR2[cond]}
  
  if [ -d $CASE_NAME ]; then CN=$(basename $CASE_NAME); fi;
  
  echo "thr$THR_NUM, cond:$cond with case name $CASE_NAME"
  . $EXECUTE_SH $CASE_NAME $PROJ_PATH $EXTRA_PARAMS
  echo "##############################################terminated script: $SCRIPT_BASE_NAME $CASE_NAME ${EXTRA_PARAMS:1:300}"
done
