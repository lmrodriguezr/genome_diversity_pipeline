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

for asm in trim norm ; do
  dir="06_metabat/${dataset}-${asm}.d"
  out="$dir/${dataset}-${asm}"
  mkdir -p "$dir"
  # sam -> bam
  if [[ ! -s "${out}.bam" ]] ; then
    samtools view -b -@ 11 \
      "05_maxbin/${dataset}-${asm}.d/${dataset}-${asm}.sam0" \
      | samtools sort -@ 11 -m 2G -l 9 -o "${out}.bam" - \
      && rm "05_maxbin/${dataset}-${asm}.d/${dataset}-${asm}.sam0"
  fi
  # depths
  jgi_summarize_bam_contig_depths \
    --outputDepth "${out}.abd" "${out}.bam"
  # binning
  metabat2 \
    -i "04_asm/${dataset}-${asm}.LargeContigs.fna" \
    -a "${out}.abd" \
    -o "$out" \
    -t 12
done

# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 07
