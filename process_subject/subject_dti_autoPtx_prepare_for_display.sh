#!/bin/bash
#   Automated probabilistic tractography plugin for FSL; visualisation script.
#
#   Performs tractography as used in De Groot et al., NeuroImage 2013.
#   2013, Marius de Groot
#

Usage() 
{
cat << EOF

Usage: execute_subject_autoPtx_prepare_for_display <SUBJ_NAME> <PROJ_DIR> <threshold>

    generates binary masks for each structure, and prepares a call to display the tracts in FSLView.
    <threshold> is used to binarise the normalised tract density images. As a first test try e.g. 0.005.

EOF
    exit 1
}

SUBJ_NAME=$1; shift
PROJ_DIR=$1; shift

if [ -z "${INIT_VARS_DEFINED}" ]; then
  . $GLOBAL_SCRIPT_DIR/init_vars.sh
fi
. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh


[ "$1" = "" ] && Usage

thresh=$1

tractSrc=tracts
data=preproc

structures=$AUTOPTX_SCRIPT_PATH/structureList
command=$PROBTRACKX_DIR/visualise_autoPtx/viewAll_${thresh}

dest=$PROBTRACKX_DIR/visualise_autoPtx/th_${thresh}
mkdir -p $dest
# the individual luts for each tract, combined with the intentcode in the nifti
# header allow each tract to be displayed in FSLView with some spatial smoothing
if [ ! -e $dest/luts ]; then
		ln -s $AUTOPTX_SCRIPT_PATH/luts $dest/luts
fi

# function based on fsledithd script
setIntentCode() {
    tmpbase=`${FSLDIR}/bin/tmpnam`;
    tmpbase2=`${FSLDIR}/bin/tmpnam`;

    # generate the xml-style header with fslhd
    ${FSLDIR}/bin/fslhd -x $1 | grep -v '/>' | grep -v 'intent_code' | grep -v '_filename' | grep -v '[^t]_name' | grep -v 'nvox' | grep -v 'to_ijk' | grep -v 'form_.*orientation' | grep -v 'qto_' > ${tmpbase}
    # exit if the above didn't generate a decent file
    if [ `cat ${tmpbase} | wc -l` -le 1 ] ; then
    echo "==ERROR== Header not recognized. Exiting..."
    exit 0;
    fi

    # append intent_code to header
    echo "  intent_code = '"$2"'  " >> ${tmpbase}
    # close the xml-style part
    echo "/>" >> ${tmpbase}

    cat ${tmpbase} | grep -v '^[ 	]*#' | grep -v '^[ 	]*$' > ${tmpbase2}
    ${FSLDIR}/bin/fslcreatehd ${tmpbase2} $1

    \rm -f ${tmpbase} ${tmpbase2}
}

echo "#!/bin/bash" > $command
chmod +x $command

comIt=0
$FSLDIR/bin/applywarp --in=$DTI_DIR/$SUBJ_NAME-dtifit_FA --out=$dest/$SUBJ_NAME-dtifit_FA --ref=$DTI_DIR/refVol --premat=$FSLDIR/etc/flirtsch/ident.mat
$FSLDIR/bin/fslmaths $dest/$SUBJ_NAME-dtifit_FA -mul 1000 -range $dest/$SUBJ_NAME-dtifit_FA
viewstr=fslview\ $dest/$SUBJ_NAME-dtifit_FA

while read line; do
    struct=`echo $line | awk '{print $1}'`
    comIt=$(( $comIt + 1 ))
    
    tracts=$PROBTRACKX_DIR/$struct/tracts/$struct"_norm.nii.gz"
    tracts_thr=$dest/${struct}_tract
    
    if [ -e $tracts_thr.nii.gz ]; then
		  $FSLDIR/bin/fslmaths $tracts -thr $thresh -bin -mul $comIt -range $tracts_thr
		  setIntentCode $tracts_thr 3
		  viewstr=$viewstr\ $tracts_thr\ -b\ 0.1,${comIt}.01\ -l\ $dest/luts/c${comIt}.lut
		fi
		  
done < $structures
echo $viewstr >> $command

