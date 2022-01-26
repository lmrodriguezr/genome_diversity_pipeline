#!/bin/bash

target=$1
dataset=$2
scr=$(readlink -f "$0")
pkg=$(dirname "$scr")

if [[ ! -n $target || ! -n $dataset ]] ; then
  echo "Usage: $0 target_folder dataset
  target_folder Path to the target folder containing the data
  dataset       Name of the dataset to process
  "
  exit 0
fi

. "$pkg/00_env.bash"
cd "$target"

for asm in trim-idba norm-idba trim-spad norm-spad ; do
  dir="06_maxbin/${dataset}-${asm}.d"
  out="$dir/${dataset}-${asm}"
  mkdir -p "$dir"
  #[[ -d "$dir" ]] && continue
  reads="02_trim/${dataset}.single.fa"
  [[ -e "02_trim/${dataset}.coupled.fa" ]] \
    && reads="02_trim/${dataset}.coupled.fa"
  run_MaxBin.pl \
    -contig "04_asm/${dataset}-${asm}.LargeContigs.fna" \
    -reads  "$reads" \
    -out    "$out" \
    -thread 12 \
    -preserve_intermediate
done

# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 07
