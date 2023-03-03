#!/usr/bin/env bash

# Extract ALFF values from hippocampus ROIs
#
# Input files in /INPUTS:
#
# From alff assessor
#   rsfc_ALFF.nii.gz
#   rsfc_ALFF_norm.nii.gz
#   rsfc_fALFF.nii.gz
#   rsfc_fALFF_norm.nii.gz
#
# From ASLROI assessor
#   lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant.nii.gz
#   lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post.nii.gz
#   lh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_total.nii.gz
#   rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant.nii.gz
#   rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post.nii.gz
#   rh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_total.nii.gz


# Resample ROIs to ALFF image space (assume already registered)
for h in lh rh; do
    for r in ant post total; do
        flirt -usesqform -applyxfm -interp nearestneighbour \
        -in /INPUTS/${h}.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_${r} \
        -out /OUTPUTS/r${h}.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_${r} \
        -ref /INPUTS/rsfc_ALFF.nii.gz
    done
done


# ROI extract
csv=/OUTPUTS/stats.csv
echo "stat,hemisphere,region,value" > ${csv}
for h in lh rh; do
    for r in ant post total; do
        for stat in ALFF ALFF_norm fALFF fALFF_norm; do
            statimg=/INPUTS/rsfc_${stat}
            maskimg=/OUTPUTS/r${h}.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_${r}
            echo ${statimg} ${maskimg}
            val=$(fslstats ${statimg} -k ${maskimg} -m)
            echo "${stat},${h},${r},${val}" >> ${csv}
        done
    done
done


# Make QA PDF showing mean fmri, alff, and ROIs
# Underlays:
#    MEAN_FMRI_NATIVE from connprep of alff-kgm-native
#    BIAS_CORR from cat12 of alff-kgm-native
# Overlays:
#    Hippo ROIs left and right
#    BRAINMASK from ALFF
cp /INPUTS/{mt1.nii.gz,meanadfmri.nii.gz,rmask.nii.gz} /OUTPUTS
cd /OUTPUTS
lcom=( $(fslstats rlh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_total -c) )
rcom=( $(fslstats rrh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_total -c) )

fsleyes render -of lhipp-t1.png -sz 300 300 -wl ${lcom[0]} ${lcom[1]} ${lcom[2]} \
    --scene ortho --displaySpace world -hc -yh -zh \
    mt1 -ot volume -dr 0 99% \
    rmask -ot mask -mc 0.3 0.8 0.3 -o -w3 \
    rlh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant -ot mask -mc 0.9 0.3 0.3 \
    rlh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post -ot mask -mc 0.9 0.7 0.3

fsleyes render -of rhipp-t1.png -sz 300 300 -wl ${rcom[0]} ${rcom[1]} ${rcom[2]} \
    --scene ortho --displaySpace world -hc -yh -zh \
    mt1 -ot volume -dr 0 99% \
    rmask -ot mask -mc 0.3 0.8 0.3 -o -w3 \
    rrh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant -ot mask -mc 0.3 0.3 0.9 \
    rrh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post -ot mask -mc 0.3 0.7 0.9

fsleyes render -of lhipp-fmri.png -sz 300 300 -wl ${lcom[0]} ${lcom[1]} ${lcom[2]} \
    --scene ortho --displaySpace world -hc -yh -zh \
    meanadfmri -ot volume -dr 0 99% \
    rmask -ot mask -mc 0.3 0.8 0.3 -o -w3 \
    rlh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant -ot mask -mc 0.9 0.3 0.3 \
    rlh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post -ot mask -mc 0.9 0.7 0.3

fsleyes render -of rhipp-fmri.png -sz 300 300 -wl ${rcom[0]} ${rcom[1]} ${rcom[2]} \
    --scene ortho --displaySpace world -hc -yh -zh \
    meanadfmri -ot volume -dr 0 99% \
    rmask -ot mask -mc 0.3 0.8 0.3 -o -w3 \
    rrh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_ant -ot mask -mc 0.3 0.3 0.9 \
    rrh.hippoAmygLabels-T1.v21.HBT.FSvoxelSpace_post -ot mask -mc 0.3 0.7 0.9

montage \
    -mode concatenate \
    lhipp-t1.png rhipp-t1.png lhipp-fmri.png rhipp-fmri.png \
    -trim -tile 2x2 -quality 100 -background black -gravity center \
    -border 20 -bordercolor black alff-extract.png

# 8.5 x 11 in is 2550x3300 at 300 dpi
convert \
    -size 2550x3300 xc:white \
    -gravity center \( alff-extract.png -resize 2200x2400 \) -composite \
    alff-extract.pdf
