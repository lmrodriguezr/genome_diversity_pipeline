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

RAM=${RAM:-100} # Use 100g if RAM is not given
. "$pkg/00_env.bash"
cd "$target"

conda deactivate
cmd="bbnorm.sh in='02_trim/${dataset}.1.fastq.gz' \
  out='03_norm/${dataset}.1.fastq'"
if [[ -s "02_trim/${dataset}.2.fastq.gz" ]] ; then
  cmd="$cmd in2='02_trim/${dataset}.2.fastq.gz' \
    out2='03_norm/${dataset}.2.fastq'"
fi
cmd="$cmd target=30 min=5 threads=3 prefilter=t -Xmx${RAM}g"
$cmd
gzip -v 03_norm/${dataset}.[12].fastq

# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 04
