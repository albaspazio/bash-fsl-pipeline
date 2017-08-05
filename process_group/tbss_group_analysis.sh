# ==================================================================================
#!/bin/sh
# ==================================================================================

# -j PROJ_DIR
# -i tbss folder
# -r reg type: [T / ]
# -p post reg [S /  ]
# -s pre stats: 0.3
# -m design file
# -f fa
# -d md
# -l l1


while getopts ":i:r:p:s:m:fdl" opt; do

	if [[ ${OPTARG:0:1} = "-" ]]; then echo "ERROR in params $opt....exiting"; echo $usage_string; exit ; fi;
	
	case $opt in
		j)	PROJ_DIR=$OPTARG
				;; 
		i)	ANALYSIS_FOLDER_NAME=$OPTARG
				;;
		r)  REG_TYPE=$OPTARG
				;;
		p)  POST_REG=$OPTARG
				;;
		s)  PRE_STATS=$OPTARG
				;;
		m)	MODEL_PATH=$OPTARG
				;;
		d)	DO_MD=1
				;;
		f)	DO_FA=1
				;;
		l)	DO_L1=1
				;;
		?)	echo "invalid option -$OPTARG"
				echo $usage_string
				exit;
				;;
		:)  echo "option -$OPTARG requires a param"
				;;
	esac
done

shift $(( OPTIND - 1 ));
declare -a array_subject=( "$@" )

. $GLOBAL_SCRIPT_DIR/init_vars.sh $PROJ_DIR

ANALYSIS_FOLDER=$PROJ_GROUP_ANALYSIS_DIR/tbss/$ANALYSIS_FOLDER_NAME
mkdir -p $ANALYSIS_FOLDER/stats

cp $0 $ANALYSIS_FOLDER # copy this script to subject folder
cp $MODEL_PATH* $ANALYSIS_FOLDER/stats
#----------------------------------------------------
echo copying files to GROUP ANALYSIS folder
for SUBJ_NAME in ${array_subject[@]}
do
	. $GLOBAL_SCRIPT_DIR/subject_init_vars.sh
  	cp $DTI_DIR/dtifit_FA.nii.gz $ANALYSIS_FOLDER
done

#----------------------------------------------------
echo start TBSS group analysis

cd $ANALYSIS_FOLDER
$FSLDIR/bin/tbss_1_preproc *nii.gz
echo "co-registrating images to MNI template"
$FSLDIR/bin/tbss_2_reg -$REG_TYPE
echo "postreg"
$FSLDIR/bin/tbss_3_postreg -$POST_REG
$FSLDIR/bin/tbss_4_prestats 0.3

echo "performing statistic"
#randomise -i all_FA_skeletonised -o tbss -m mean_FA_skeleton_mask -d design.mat -t design.con -n 500 --T2 -V
$FSLDIR/bin/randomise -i all_FA_skeletonised -o tbss -m mean_FA_skeleton_mask -d $DESIGN_DIR/design.mat -t $DESIGN_DIR/design.con -c 1.5 -V
