#!/bin/bash
#   Automated probabilistic tractography plugin for FSL; tractography script.
#
#   Performs tractography as used in De Groot et al., NeuroImage 2013.
#   2013, Marius de Groot
#
#   LICENCE
#
#   AutoPtx, plugin for FSL, Release 0.1 (c) 2013, Erasmus MC, University
#   Medical Center (the "Software")
#
#   The Software remains the property of the Erasmus MC, University Medical
#   Center ("the University").
#
#   The Software is distributed "AS IS" under this Licence solely for
#   non-commercial use in the hope that it will be useful, but in order
#   that the University as a charitable foundation protects its assets for
#   the benefit of its educational and research purposes, the University
#   makes clear that no condition is made or to be implied, nor is any
#   warranty given or to be implied, as to the accuracy of the Software, or
#   that it will be suitable for any particular purpose or for use under
#   any specific conditions.  Furthermore, the University disclaims all
#   responsibility for the use which is made of the Software.  It further
#   disclaims any liability for the outcomes arising from using the
#   Software.
#
#   The Licensee agrees to indemnify the University and hold the University
#   harmless from and against any and all claims, damages and liabilities
#   asserted by third parties (including claims for negligence) which arise
#   directly or indirectly from the use of the Software or the sale of any
#   products based on the Software.
#
#   No part of the Software may be reproduced, modified, transmitted or
#   transferred in any form or by any means, electronic or mechanical,
#   without the express permission of the University.  The permission of
#   the University is not required if the said reproduction, modification,
#   transmission or transference is done without financial return, the
#   conditions of this Licence are imposed upon the receiver of the
#   product, and all original and amended source code is included in any
#   transmitted product.  You may be held legally responsible for any
#   copyright infringement that is caused or encouraged by your failure to
#   abide by these terms and conditions.
#
#   You are not permitted under this Licence to use this Software
#   commercially.  Use for which any financial return is received shall be
#   defined as commercial use, and includes (1) integration of all or part
#   of the source code or the Software into a product for sale or license
#   by or on behalf of Licensee to third parties or (2) use of the Software
#   or any derivative of it for research with the final aim of developing
#   software products for sale or license to a third party or (3) use of
#   the Software or any derivative of it for research with the final aim of
#   developing non-software products for sale or license to a third party,
#   or (4) use of the Software to provide any service to an external
#   organisation for which payment is received.  If you are interested in
#   using the Software commercially, please contact the technology transfer
#   company of the University to negotiate a licence.  Contact details are:
#   tto@erasmusmc.nl quoting reference SOPHIA #2013-012 and the
#   accompanying paper DOI: 10.1016/j.neuroimage.2013.03.015.
#

Usage() {
    cat << EOF

Usage: execute_subject_autoPtx_subject_struct <SUBJ_NAME> <PROJ_DIR> <structure> <seedMultiplier>

    Specification of seedMultiplier is optional.
    Expects directory structure as prepared by autoPtx_1_preproc.
    This script is called by autoPtx_2_launchTractography.

EOF
    exit 1
}

[ "$3" = "" ] && Usage
[ "$5" != "" ] && Usage


SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh

struct=$1; shift
nSeed=1000

# apply seed multiplier if set
if [ "$1" != "" ]; then
  nSeed=$(echo "scale=0; $nSeed * ${1} / 1"|bc)
fi

run echo "running automated tractography of subject ${SUBJ_NAME}, structure ${struct}, using $nSeed seeds per voxel."

# sources
masks=$AUTOPTX_SCRIPT_PATH/protocols/$struct
data=$DTI_DIR
warp=$ROI_DIR/reg_dti/std2dti_warp
bpdata=$BEDPOSTX_DIR
# output
tracts=$PROBTRACKX_DIR/$struct

run mkdir -p $tracts

# cleanup possible previous run
\rm -f $tracts/tracts/waytotal
imrm $tracts/tracts/tractsNorm
\rm -rf $tracts/tracts

# is there a stop criterion defined in the protocol for this struct?
if [ -e $masks/stop.nii.gz ]; then
  useStop=1
else
  useStop=0
fi
# does the protocol defines a second run with inverted seed / target masks
if [ -e $masks/invert ]; then
  symtrack=1
  rm -f $tracts/tractsInv/waytotal
else
  symtrack=0
fi

# transform masks
run $FSLDIR/bin/applywarp -r $data/refVol -w $warp -i $masks/seed -o $tracts/seed -d float
run $FSLDIR/bin/fslmaths $tracts/seed -thr 0.1 -bin $tracts/seed -odt char
run $FSLDIR/bin/applywarp -r $data/refVol -w $warp -i $masks/target -o $tracts/target -d float
run $FSLDIR/bin/fslmaths $tracts/target -thr 0.1 -bin $tracts/target -odt char
run $FSLDIR/bin/applywarp -r $data/refVol -w $warp -i $masks/exclude -o $tracts/exclude -d float
run $FSLDIR/bin/fslmaths $tracts/exclude -thr 0.1 -bin $tracts/exclude -odt char
if [ "$useStop" -eq "1" ]; then
  run $FSLDIR/bin/applywarp -r $data/refVol -w $warp -i $masks/stop -o $tracts/stop -d float
  run $FSLDIR/bin/fslmaths $tracts/stop -thr 0.1 -bin $tracts/stop -odt char
fi

# process structure
if [ "$useStop" -eq "1" ]; then
  run $FSLDIR/bin/probtrackx -s $bpdata/merged -m $data/nodif_brain_mask -x $tracts/seed -o density --waypoints=$tracts/target --stop=$tracts/stop --nsamples=${nSeed} --opd --dir=$tracts/tracts --avoid=$tracts/exclude -l --forcedir
  if [ "$symtrack" -eq "1" ]; then
    run $FSLDIR/bin/probtrackx -s $bpdata/merged -m $data/nodif_brain_mask -x $tracts/target -o density --waypoints=$tracts/seed --stop=$tracts/stop --nsamples=${nSeed} --opd --dir=$tracts/tractsInv --avoid=$tracts/exclude -l --forcedir
  fi
else
  run $FSLDIR/bin/probtrackx -s $bpdata/merged -m $data/nodif_brain_mask -x $tracts/seed -o density --waypoints=$tracts/target --nsamples=${nSeed} --opd --dir=$tracts/tracts --avoid=$tracts/exclude -l --forcedir
  if [ "$symtrack" -eq "1" ]; then
    run $FSLDIR/bin/probtrackx -s $bpdata/merged -m $data/nodif_brain_mask -x $tracts/target -o density --waypoints=$tracts/seed --nsamples=${nSeed} --opd --dir=$tracts/tractsInv --avoid=$tracts/exclude -l --forcedir
  fi
fi

# merge runs for forward and inverted tractography runs
if [ "$symtrack" = "1" ]; then
  run $FSLDIR/bin/immv $tracts/tracts/density $tracts/tractsInv/fwDensity
  run $FSLDIR/bin/fslmaths $tracts/tractsInv/fwDensity -add $tracts/tractsInv/density $tracts/tracts/density
  way1=`cat $tracts/tracts/waytotal | sed 's/e/\\*10^/' | tr -d '+' `
  \rm -f $tracts/tracts/waytotal
  way2=`cat $tracts/tractsInv/waytotal | sed 's/e/\\*10^/' | tr -d '+' `
  way=$(echo "scale=5; $way1 + $way2 "|bc)
  echo $way > $tracts/tracts/waytotal 
fi

# perform normalisation for waytotal
run waytotal=`cat $tracts/tracts/waytotal`
run $FSLDIR/bin/fslmaths $tracts/tracts/density -div $waytotal -range $tracts/tracts/tractsNorm -odt float
