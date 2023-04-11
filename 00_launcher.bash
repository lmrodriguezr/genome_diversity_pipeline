#!/bin/bash

# Launch step 02: trimming
function launch_step_02 {
  local dataset=$1

  # Determine time and RAM
  S01=$(size_01 "$dataset")
  RAM_G=20
  TIME_H=$(arithm "2+0.5*$S01/1e9")

  # Launch
  sbatch --job-name="GD02-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=1 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.02.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=02_trim \
       "$pkg/00_launcher.sbatch"

 # qsub "$pkg/00_launcher.pbs" -N "GD02-$dataset" \
  #  -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=02_trim" \
   # -l nodes=1:ppn=1 -l mem="${RAM_G}g" -l "walltime=${TIME_H}:00:00" \
    #-o "xx_log/${dataset}.02.txt" -j oe
}

# Launch step 03: normalization with different settings
function launch_step_03 {

  local dataset=$1

  # Determine time and RAM
  C02=$(cardinality "$dataset")
  RAM_G=$(arithm "1+$C02*15/1e9")
  S02=$(size_02 "$dataset")
  TIME_H=$(arithm "1+$S02/1e9")

  # Launch
  sbatch --job-name="GD03-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=5 \
       --mem=${RAM_G+10}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.03.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=03_norm,RAM=$RAM_G \
       "$pkg/00_launcher.sbatch"


  #qsub "$pkg/00_launcher.pbs" -N "GD03-$dataset" \
   # -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=03_norm,RAM=$RAM_G" \
    #-l nodes=1:ppn=5 -l mem="$(($RAM_G+10))g" -l walltime="${TIME_H}:00:00" \
    #-o "xx_log/${dataset}.03.txt" -j oe
}

# Launch step 04: Assembly
function launch_step_04 {
  local dataset=$1

  # Determine time and RAM
  C02=$(cardinality "$dataset")
  RAM_G=$(arithm "$C02*175/1e9") # Blake modified RAM estimation
  S02=$(size_02 "$dataset")
  TIME_H=$(arithm "6+$S02*5/1e9")
  USE_FRACTION=1
  # New PACE Phoenix MAX RAM nodes
  # Set 700 to max available RAM for your server
  if [[ $RAM_G -gt 700 ]] 
  then
    USE_FRACTION=$(perl -e "print 700/$RAM_G") # <- Hoping it's linear!
    RAM_G=700 # <- That's the maximum we have
  elif [[ $RAM_G -lt 40 ]]
  then
   RAM_G=40 # don't launch jobs with less than 20gb RAM 
  fi

  # Launch
    sbatch --job-name="GD04-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=24 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.04.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,USE_FRACTION=$USE_FRACTION,STEP=04_idba \
       "$pkg/00_launcher.sbatch"

 # qsub "$pkg/00_launcher.pbs" -N "GD04-$dataset" \
  #  -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,USE_FRACTION=$USE_FRACTION,STEP=04_idba" \
    #-l nodes=1:ppn=24 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
   # -o "xx_log/${dataset}.04.txt" -j oe
}

### metaSPAdes:

function launch_step_05 {
  local dataset=$1

 # Determine time and RAM
  C02=$(cardinality "$dataset")
  RAM_G=$(arithm "$C02*220/1e9") # Modified RAM estimation
  S02=$(size_02 "$dataset")
  TIME_H=$(arithm "10+$S02*8/1e9")
  USE_FRACTION=1
  # New PACE Phoenix MAX RAM nodes
  # Set 700 to max available RAM for your server
  if [[ $RAM_G -gt 700 ]] ; then
    USE_FRACTION=$(perl -e "print 700/$RAM_G") # <- Hoping it's linear!
    RAM_G=700 # <- That's the maximum we have
  elif [[ $RAM_G -lt 40	]]
  then 
   RAM_G=140 # don't launch jobs	with less than 20gb RAM for the love of god don't do it
  fi

  # Launch
      sbatch --job-name="GD05-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=24 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.05.txt \
       --export=PKG=$pkg,TARGET=$PWD,MEM=$RAM_G,DATASET=$dataset,USE_FRACTION=$USE_FRACTION,STEP=05_spad \
       "$pkg/00_launcher.sbatch"

  #qsub "$pkg/00_launcher.pbs" -N "GD05-$dataset" \
  #  -v "PKG=$pkg,TARGET=$PWD,MEM=$RAM_G,DATASET=$dataset,USE_FRACTION=$USE_FRACTION,STEP=05_spad" \
   # -l nodes=1:ppn=24 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    #-o "xx_log/${dataset}.05.txt" -j oe
}

### BLAKE EDITS ^

# Launch step 06: MaxBin binning (including mapping)
function launch_step_06 {
  local dataset=$1

  # Determine time and RAM
  S02=$(size_02 "$dataset")
  RAM_G=$(arithm "66+0.4*$S02/1e9") # Modified RAM estimation
  TIME_H=$(arithm "6+2*$S02/1e9")

  # Launch
  sbatch --job-name="GD06-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=12 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.06.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=06_maxbin \
       "$pkg/00_launcher.sbatch"

  #qsub "$pkg/00_launcher.pbs" -N "GD06-$dataset" \
   # -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=06_maxbin" \
    #-l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    #-o "xx_log/${dataset}.06.txt" -j oe
}

# Launch step 07: MetaBAT (reusing MaxBin's mapping)
function launch_step_07 {
  local dataset=$1

  # Determine time by read size
  S04=$(size_04 "$dataset")
  RAM_G=25
  TIME_H=$(arithm "2+50*$S04/1e9")

  # Launch
  sbatch --job-name="GD07-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=12 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.07.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=07_metabat \
       "$pkg/00_launcher.sbatch"  

  #qsub "$pkg/00_launcher.pbs" -N "GD07-$dataset" \
   # -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=07_metabat" \
    #-l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    #-o "xx_log/${dataset}.07.txt" -j oe
}

# Launch step 08: MiGA Dereplication and quality evaluation
function launch_step_08 {
  local dataset=$1

  # Determine time by read size
  N05=$(ls 06_maxbin/${dataset}-*.d/*.fasta 2>/dev/null | wc -l)
  N06=$(ls 07_metabat/${dataset}-*.d/*.fa 2>/dev/null | wc -l)
  RAM_G=$(arithm "10+($N05+$N06)/1e3")
  TIME_H=$(arithm "12+8*($N05+$N06)/1e3")

   # Launch
  sbatch --job-name="GD08-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=12 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.08.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=08_derep \
       "$pkg/00_launcher.sbatch"

  #qsub "$pkg/00_launcher.pbs" -N "GD08-$dataset" \
  #  -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=08_derep" \
  #  -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
  #  -o "xx_log/${dataset}.08.txt" -j oe
}

# Launch step 09: ANIr
function launch_step_09 {
  local dataset=$1

  # No data yet to determine time or RAM
  RAM_G=30
  TIME_H=72

   # Launch
  sbatch --job-name="GD09-${dataset}" \
       --nodes=1 \
       --ntasks-per-node=12 \
       --mem=${RAM_G}g \
       --time=${TIME_H}:00:00 \
       --output=xx_log/${dataset}.09.txt \
       --export=PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=09_anir \
       "$pkg/00_launcher.sbatch"

  #qsub "$pkg/00_launcher.pbs" -N "GD09-$dataset" \
  #  -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=09_anir" \
  #  -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
  #  -o "xx_log/${dataset}.09.txt" -j oe
}

# Launch step 10: Not yet implemented
function launch_step_10 {
  echo "STEP 10: NOT YET IMPLEMENTED" >&2
}

# Source code
scr=$(readlink -f "$0" 2>/dev/null)
export pkg=$(dirname "$scr")
. "$pkg/00_sizes.bash"

# Input variables
target="$1"
dataset="$2"
step="$3"

# Engage!
cd "$target"
"launch_step_$step" "$dataset"

