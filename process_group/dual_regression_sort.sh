#!/bin/sh

Usage() {
    cat <<EOF

dual_regression v0.5 (beta)

***NOTE*** ORDER OF COMMAND-LINE ARGUMENTS IS DIFFERENT FROM PREVIOUS VERSION

Usage: dual_regression_sort <group_IC_maps> <des_norm> <output_directory> <input1> <input2> <input3> .........
e.g.   dual_regression_sort groupICA.gica/groupmelodic.ica/melodic_IC 1 grot \`cat groupICA.gica/.filelist\`

<group_IC_maps_4D>            4D image containing spatial IC maps (melodic_IC) from the whole-group ICA analysis
<des_norm>                    0 or 1 (1 is recommended). Whether to variance-normalise the timecourses used as the stage-2 regressors
<output_directory>            This directory will be created to hold all output and logfiles
<input1> <input2> ...         List all subjects' preprocessed, standard-space 4D datasets

EOF
    exit 1
}

############################################################################

[ "$3" = "" ] && Usage

ORIG_COMMAND=$*

if [ -f $1 ]; then
  ICA_MAPS=`${FSLDIR}/bin/remove_ext $1` ; shift
else
  echo "melodic_IC input file ($1) is absent" 
  exit
fi

DES_NORM=--des_norm
if [ $1 = 0 ] ; then
  DES_NORM=""
fi ; shift

OUTPUT=`${FSLDIR}/bin/remove_ext $1` ; shift

while [ _$1 != _ ] ; do
  if [ -f $1.nii.gz ]; then
    INPUTS="$INPUTS `${FSLDIR}/bin/remove_ext $1`"
  else
    echo "error: the subject's input file $1 is absent";
    exit
  fi
  shift
done

############################################################################

mkdir -p $OUTPUT
LOGDIR=${OUTPUT}/scripts+logs
mkdir -p $LOGDIR
echo $ORIG_COMMAND > $LOGDIR/command

echo "creating common mask"
j=0
for i in $INPUTS ; do
  echo "$FSLDIR/bin/fslmaths $i -Tstd -bin ${OUTPUT}/mask_`${FSLDIR}/bin/zeropad $j 5` -odt char" >> ${LOGDIR}/drA
  j=`echo "$j 1 + p" | dc -`
done
ID_drA=`$FSLDIR/bin/fsl_sub -T 10 -N drA -l $LOGDIR -t ${LOGDIR}/drA`
cat <<EOF > ${LOGDIR}/drB
#!/bin/sh
\$FSLDIR/bin/fslmerge -t ${OUTPUT}/maskALL \`\$FSLDIR/bin/imglob ${OUTPUT}/mask_*\`
\$FSLDIR/bin/fslmaths $OUTPUT/maskALL -Tmin $OUTPUT/mask
\$FSLDIR/bin/imrm $OUTPUT/mask_*
EOF
chmod a+x ${LOGDIR}/drB
ID_drB=`$FSLDIR/bin/fsl_sub -j $ID_drA -T 5 -N drB -l $LOGDIR ${LOGDIR}/drB`

echo "doing the dual regressions"
j=0
for i in $INPUTS ; do
  s=subject`${FSLDIR}/bin/zeropad $j 5`
  echo "$FSLDIR/bin/fsl_glm -i $i -d $ICA_MAPS -o $OUTPUT/dr_stage1_${s}.txt --demean -m $OUTPUT/mask ; \
        $FSLDIR/bin/fsl_glm -i $i -d $OUTPUT/dr_stage1_${s}.txt -o $OUTPUT/dr_stage2_$s --out_z=$OUTPUT/dr_stage2_${s}_Z --demean -m $OUTPUT/mask $DES_NORM ; \
        $FSLDIR/bin/fslsplit $OUTPUT/dr_stage2_$s $OUTPUT/dr_stage2_${s}_ic" >> ${LOGDIR}/drC
  j=`echo "$j 1 + p" | dc -`
done
ID_drC=`$FSLDIR/bin/fsl_sub -j $ID_drB -T 30 -N drC -l $LOGDIR -t ${LOGDIR}/drC`

echo "sorting maps"
j=0
Nics=`$FSLDIR/bin/fslnvols $ICA_MAPS`
while [ $j -lt $Nics ] ; do
  jj=`$FSLDIR/bin/zeropad $j 4`

  echo "$FSLDIR/bin/fslmerge -t $OUTPUT/dr_stage2_ic$jj \`\$FSLDIR/bin/imglob $OUTPUT/dr_stage2_subject*_ic${jj}.*\` ; \
        $FSLDIR/bin/imrm \`\$FSLDIR/bin/imglob $OUTPUT/dr_stage2_subject*_ic${jj}.*\` " >> ${LOGDIR}/drD
  j=`echo "$j 1 + p" | dc -`
done
ID_drD=`$FSLDIR/bin/fsl_sub -j $ID_drC -T 60 -N drD -l $LOGDIR -t ${LOGDIR}/drD`





