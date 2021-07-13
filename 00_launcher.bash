#!/bin/bash

# Launch step 02: trimming
function launch_step_02 {
  local dataset=$1

  # Determine time and RAM
  S01=$(size_01 "$dataset")
  RAM_G=20
  TIME_H=$(arithm "2+0.5*$S01/1e9")

  # Launch
  qsub "$pkg/00_launcher.pbs" -N "GD02-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=02_trim" \
    -l nodes=1:ppn=1 -l mem="${RAM_G}g" -l "walltime=${TIME_H}:00:00" \
    -o "xx_log/${dataset}.02.txt" -j oe
}

# Launch step 03: normalization with different settings
function launch_step_03 {
  local dataset=$1

  # Determine time and RAM
  C02=$(cardinality "$dataset")
  RAM_G=$(arithm "1+$C02*13/1e9")
  S02=$(size_02 "$dataset")
  TIME_H=$(arithm "1+$S02/1e9")

  # Launch
  qsub "$pkg/00_launcher.pbs" -N "GD03-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=03_norm,RAM=$RAM_G" \
    -l nodes=1:ppn=5 -l mem="$(($RAM_G+10))g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.03.txt" -j oe
}

# Launch step 04: Assembly
function launch_step_04 {
  local dataset=$1

  # Determine time and RAM
  C02=$(cardinality "$dataset")
  #RAM_G=$(arithm "15+$C02*100/1e9") # consistently too high by 50gb or more
  RAM_G=$(arithm "$C02*75/1e9") # I think this lower estimate should work
  S02=$(size_02 "$dataset")
  TIME_H=$(arithm "6+$S02*4/1e9")
  USE_FRACTION=1
  # New PACE Phoenix MAX RAM nodes
  # Set 700 to max available RAM for your server
  if [[ $RAM_G -gt 700 ]] ; then
    USE_FRACTION=$(perl -e "print 700/$RAM_G") # <- Hoping it's linear!
    RAM_G=700 # <- That's the maximum we have
  fi

  # Launch
  qsub "$pkg/00_launcher.pbs" -N "GD04-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,USE_FRACTION=$USE_FRACTION,STEP=04_asm" \
    -l nodes=1:ppn=24 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.04.txt" -j oe
}

# Launch step 05: MaxBin binning (including mapping)
function launch_step_05 {
  local dataset=$1

  # Determine time and RAM
  S02=$(size_02 "$dataset")
  RAM_G=$(arithm "3+0.4*$S02/1e9")
  TIME_H=$(arithm "6+2*$S02/1e9")

  # Launch
  qsub "$pkg/00_launcher.pbs" -N "GD05-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=05_maxbin" \
    -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.05.txt" -j oe
}

# Launch step 06: MetaBAT (reusing MaxBin's mapping)
function launch_step_06 {
  local dataset=$1

  # Determine time by read size
  S04=$(size_04 "$dataset")
  RAM_G=25
  TIME_H=$(arithm "2+15*$S04/1e9")

  # Launch
  qsub "$pkg/00_launcher.pbs" -N "GD06-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=06_metabat" \
    -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.06.txt" -j oe
}

# Launch step 07: MiGA Dereplication and quality evaluation
function launch_step_07 {
  local dataset=$1

  # Determine time by read size
  N05=$(ls 05_maxbin/${dataset}-*.d/*.fasta 2>/dev/null | wc -l)
  N06=$(ls 06_metabat/${dataset}-*.d/*.fa 2>/dev/null | wc -l)
  RAM_G=$(arithm "1+($N05+$N06)/1e3")
  TIME_H=$(arithm "12+8*($N05+$N06)/1e3")

  qsub "$pkg/00_launcher.pbs" -N "GD07-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=07_derep" \
    -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.07.txt" -j oe
}

# Launch step 08: ANIr
function launch_step_08 {
  local dataset=$1

  # No data yet to determine time or RAM
  RAM_G=30
  TIME_H=72

  qsub "$pkg/00_launcher.pbs" -N "GD08-$dataset" \
    -v "PKG=$pkg,TARGET=$PWD,DATASET=$dataset,STEP=08_anir" \
    -l nodes=1:ppn=12 -l mem="${RAM_G}g" -l walltime="${TIME_H}:00:00" \
    -o "xx_log/${dataset}.08.txt" -j oe
}

# Launch step 09: Not yet implemented
function launch_step_09 {
  echo "STEP 09: NOT YET IMPLEMENTED" >&2
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

