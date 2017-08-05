#===============================================================================================================================
# BBR  LINEAR
# highres, highres_head, standard
#===============================================================================================================================
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1_brain highres
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1  highres_head
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain standard

# ---- EPI <--> HIGHRES
# BBR => epi2highres.mat & epi2highres.nii.gz
/usr/share/fsl/5.0/bin/epi_reg --epi=example_func --t1=highres_head --t1brain=highres --out=example_func2highres
# => highres2epi.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat

# ---- HIGHRES <--> STANDARD
/usr/share/fsl/5.0/bin/flirt -in highres -ref standard -out highres2standard -omat highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

# ---- EPI <--> STANDARD
# => epi2standard.mat (as concat)
/usr/share/fsl/5.0/bin/convert_xfm -omat example_func2standard.mat -concat highres2standard.mat example_func2highres.mat
# => epi2standard.nii.gz
/usr/share/fsl/5.0/bin/flirt -ref standard -in example_func -out example_func2standard -applyxfm -init example_func2standard.mat -interp trilinear
# => standard2example_func.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat


#===============================================================================================================================
# 6DOF  LINEAR
# highres, standard
#===============================================================================================================================
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1_brain highres
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain standard

# ---- EPI <--> HIGHRES
# => example_func2highres.nii.gz & example_func2highres.mat
/usr/share/fsl/5.0/bin/flirt -in example_func -ref highres -out example_func2highres -omat example_func2highres.mat -cost corratio -dof 6 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
# => highres2epi.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat

# ---- HIGHRES <--> STANDARD
/usr/share/fsl/5.0/bin/flirt -in highres -ref standard -out highres2standard -omat highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

# ---- EPI <--> STANDARD
# => epi2standard.mat (as concat)
/usr/share/fsl/5.0/bin/convert_xfm -omat example_func2standard.mat -concat highres2standard.mat example_func2highres.mat
# => epi2standard.nii.gz
/usr/share/fsl/5.0/bin/flirt -ref standard -in example_func -out example_func2standard -applyxfm -init example_func2standard.mat -interp trilinear
# => standard2example_func.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat

#===============================================================================================================================
# BBR  NON LINEAR
# highres, highres_head, standard, standard_head, standard_mask
#===============================================================================================================================
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1_brain highres
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1  highres_head
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain standard
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm standard_head
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain_mask_dil standard_mask

# ---- EPI <--> HIGHRES
# BBR => epi2highres.mat & epi2highres.nii.gz
/usr/share/fsl/5.0/bin/epi_reg --epi=example_func --t1=highres_head --t1brain=highres --out=example_func2highres
# highres2epi.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat

# ---- HIGHRES <--> STANDARD
# => highres2standard.mat
/usr/share/fsl/5.0/bin/flirt -in highres -ref standard -out highres2standard -omat highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
# => highres2standard_warp
/usr/share/fsl/5.0/bin/fnirt --iout=highres2standard_head --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=highres2standard --jout=highres2highres_jac --config=T1_2_MNI152_2mm --ref=standard_head --refmask=standard_mask --warpres=10,10,10
# => highres2standard.nii.gz
/usr/share/fsl/5.0/bin/applywarp -i highres -r standard -o highres2standard -w highres2standard_warp
# => standard2highres.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

# ---- EPI <--> STANDARD
# => example_func2standard.mat (as concat)
/usr/share/fsl/5.0/bin/convert_xfm -omat example_func2standard.mat -concat highres2standard.mat example_func2highres.mat
# => example_func2standard_warp (as : example_func2highres.mat + highres2standard_warp)
/usr/share/fsl/5.0/bin/convertwarp --ref=standard --premat=example_func2highres.mat --warp1=highres2standard_warp --out=example_func2standard_warp
# => example_func2standard.nii.gz
/usr/share/fsl/5.0/bin/applywarp --ref=standard --in=example_func --out=example_func2standard --warp=example_func2standard_warp
# =>standard2example_func.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat

#===============================================================================================================================
# 6DOF  NON LINEAR
# highres, highres_head, standard, standard_head, standard_mask
#===============================================================================================================================
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1_brain highres
/usr/share/fsl/5.0/bin/fslmaths /media/dados/MRI/projects/temperamento_murcia/subjects/4030/s1/mpr/4030-t1  highres_head
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain standard
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm standard_head
/usr/share/fsl/5.0/bin/fslmaths /usr/share/fsl/5.0/data/standard/MNI152_T1_2mm_brain_mask_dil standard_mask

# ---- EPI <--> HIGHRES
# => example_func2highres.mat & example_func2highres.nii.gz
/usr/share/fsl/5.0/bin/flirt -in example_func -ref highres -out example_func2highres -omat example_func2highres.mat -cost corratio -dof 6 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
# => highres2example_func.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat highres2example_func.mat example_func2highres.mat

# ---- HIGHRES <--> STANDARD
# => highres2standard.mat
/usr/share/fsl/5.0/bin/flirt -in highres -ref standard -out highres2standard -omat highres2standard.mat -cost corratio -dof 12 -searchrx -90 90 -searchry -90 90 -searchrz -90 90 -interp trilinear 
# => highres2standard_warp & highres2standard
/usr/share/fsl/5.0/bin/fnirt --iout=highres2standard_head --in=highres_head --aff=highres2standard.mat --cout=highres2standard_warp --iout=highres2standard --jout=highres2highres_jac --config=T1_2_MNI152_2mm --ref=standard_head --refmask=standard_mask --warpres=10,10,10

# => highres2standard.nii.gz
/usr/share/fsl/5.0/bin/applywarp -i highres -r standard -o highres2standard -w highres2standard_warp
# => standard2highres.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2highres.mat highres2standard.mat

# ---- EPI <--> STANDARD
# => example_func2standard.mat
/usr/share/fsl/5.0/bin/convert_xfm -omat example_func2standard.mat -concat highres2standard.mat example_func2highres.mat
# => example_func2standard_warp
/usr/share/fsl/5.0/bin/convertwarp --ref=standard --premat=example_func2highres.mat --warp1=highres2standard_warp --out=example_func2standard_warp
# => example_func2standard.nii.gz
/usr/share/fsl/5.0/bin/applywarp --ref=standard --in=example_func --out=example_func2standard --warp=example_func2standard_warp
# => standard2example_func.mat
/usr/share/fsl/5.0/bin/convert_xfm -inverse -omat standard2example_func.mat example_func2standard.mat


