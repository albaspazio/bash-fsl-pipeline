#!/bin/bash

# ====== init params ===========================
GLOBAL_SCRIPT_DIR=/homer/home/dati/fsl_global_scripts  
PROJ_DIR=/gnappo/home3/dati/BELGRADO_1.5Philips/PROVA_STE
. $GLOBAL_SCRIPT_DIR/use_fsl 5
#===============================================
. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR
#===============================================
SESS_ID=1
. $PROJ_SCRIPT_DIR/subjects_list.sh

declare -i NUM_CPU=1

EXECUTE_SH=$GLOBAL_SUBJECT_SCRIPT_DIR/subject_t1_prepare.sh
# DO THE FOLLOWING OPS:
#### FIXING NEGATIVE RANGE
#### REORIENTATION 2 STANDARD
#### AUTOMATIC CROPPING
# params:
# "  -odn <output directory>      basename of directory for output (default is 'anat')"
# "  --overwrite                  overwrite each step of the pipeline, otherwise do a step only if requested and if the output is absent"
# "  --noreorient                 turn off step that does reorientation 2 standard (fslreorient2std)"
# "  --nocrop                     turn off step that does automated cropping (robustfov)"
# "  --nocleanup			      do not delete IMG_orig IMG_fullfov"

. $MULTICORE_SCRIPT_DIR/define_thread_processes.sh $NUM_CPU $EXECUTE_SH "$str_arr_all_subjects80" $PROJ_DIR 
wait

echo "=================>>>>  End processing"
