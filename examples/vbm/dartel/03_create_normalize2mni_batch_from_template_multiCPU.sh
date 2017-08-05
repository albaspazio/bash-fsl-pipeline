# ==================================================================================
#!/bin/bash

GLOBAL_SCRIPT_DIR=/media/data/MRI/scripts
PROJ_DIR=/media/dados/MRI/projects/temperamento_murcia
. use_fsl 5

#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
. $PROJ_SCRIPT_DIR/subjects_list.sh


declare -a array_subject=${arr_all_subjects81[@]}

declare -i NUM_CPU=4

template_folder=baseline81_dartel
template_name=Template_baseline81
#=======================================================
template_batch_job=$PROJ_SCRIPT_DIR/vbm/input_spm_templates/singlesubj_dartel_normalize2mni_job.m
template_batch_start=$PROJ_SCRIPT_DIR/vbm/input_spm_templates/start_template.m

output_batch_job_rootname=job.m
output_batch_start_name=subjects_dartel_normalize2mni_start_


template_image=$PROJ_GROUP_ANALYSIS_DIR/vbm/$template_folder/$template_name"_6.nii"


if [ ! -f $template_image ]; then
	echo "template image ($template_image) is missing.....exiting"
	exit
fi

declare -a arr_files=()
declare -a arr_jobs=()
#=======================================================

mkdir -p $PROJ_SCRIPT_DIR/vbm/batch

JOBS_LIST=""
# create SUBJECTS jobs
for SUBJ_NAME in ${array_subject[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  echo "creating subject $SUBJ_NAME job"
  
  warp_image=$T1_DIR/u_rc1$SUBJ_NAME-t1_$template_name.nii
  RC1_image=$T1_DIR/rc1$SUBJ_NAME-t1.nii
  RC2_image=$T1_DIR/rc2$SUBJ_NAME-t1.nii
  RC3_image=$T1_DIR/rc3$SUBJ_NAME-t1.nii


	if [ ! -f $warp_image -o ! -f $RC1_image -o ! -f $RC2_image -o ! -f $RC3_image ]; then
		echo "some images are missing...either $warp_image or $RC1_image or $RC2_image or $RC3_image .....exiting"	
		exit
	fi

  output_batch_name=$PROJ_SCRIPT_DIR/vbm/batch/dartel_normalize2mni_$SUBJ_NAME"_"$output_batch_job_rootname
  sed -e "s@<TEMPLATE_IMAGE>@$template_image@g" -e "s@<SUBJ_FLOWFIELD_IMAGE>@$warp_image@g" -e "s@<RC1_IMAGE>@$RC1_image@g" -e "s@<RC2_IMAGE>@$RC2_image@g" -e "s@<RC3_IMAGE>@$RC3_image@g" $template_batch_job > $output_batch_name
  JOBS_LIST="$JOBS_LIST \'$output_batch_name\'"
done

# create start m file
JOBS_LIST=`echo $JOBS_LIST`

declare -a arr_jobs=($JOBS_LIST)

declare -i num_thr=0		# number of instances/start batch files
declare -i limit_passed=0	# indicate if $NUM_CPU limit is exceeded
declare -a arr_m_files=()	# array [instances] of subjects jobs files
declare -i curr_batch=0

for job in ${arr_jobs[@]}
do
  arr_m_files[$curr_batch]="${arr_m_files[$curr_batch]}$job "
  curr_batch=$curr_batch+1
  if [ $limit_passed -eq 0 ]; then num_thr=$curr_batch; fi

  if [ $curr_batch -eq $NUM_CPU ]; then 
    curr_batch=0
    limit_passed=1
    num_thr=$NUM_CPU
  fi
done

for((thr=0; thr<$num_thr; thr++)); 
do
  output_batch_start=$PROJ_SCRIPT_DIR/vbm/batch/$output_batch_start_name$thr.m
  jobs_list=`echo ${arr_m_files[thr]}`
  sed -e "s@X@1@g" -e "s@JOB_LIST@$jobs_list@g" $template_batch_start > $output_batch_start  

  cd $PROJ_SCRIPT_DIR/vbm/batch
  matlab -r $output_batch_start_name$thr &
done

 
