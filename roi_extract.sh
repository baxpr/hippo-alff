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
