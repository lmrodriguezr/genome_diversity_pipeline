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

dir="10_coverage/$dataset"
mkdir -p "$dir"

# Run ANIr for each genome
function anir_for_genome {
  local dir=$1
  local genome=$2
  local identity=$3
  name=$(basename "$genome" .LargeContigs.fna.tag)
  anir.rb -g "$genome" -m "$dir/map.bam" --m-format bam \
    -t 12 -a fix -i "$identity" \
    -L "$dir/${name}.identity-${identity}.txt" \
    --tab "$dir/${name}.anir-${identity}.tsv"
}
export -f anir_for_genome
parallel -j 12 anir_for_genome "$dir" {} {} \
  ::: 08_derep/${dataset}/representatives/*.LargeContigs.fna.tag \
  ::: 97.5 95 90
rm 08_derep/${dataset}/representatives/*.LargeContigs.fna.tag
rm "$dir"/*.identity-97.5.txt
rm "$dir"/*.identity-95.txt

# Summary of ANIr at 95% identity threshold
for i in $dir/*.anir-95.tsv ; do
  echo -e "$(basename "$i" .anir-95.tsv)\t$(tail -n 1 "$i")"
done > $dir/anir-95.tsv

# Use CoverM to get MAG abundances
echo "start coverm"
$dir/map.bam

coverm genome -b "$dir/map.bam" -r "08_derep/${dataset}/representatives.fna" \
  -s ':' --min-read-percent-identity 95 --min-read-aligned-percent 70 \
  --output-format sparse --trim-max 90 --trim-min 10 \
  -m 'relative_abundance covered_fraction trimmed_mean' \
  -o "$dir/coverm.tsv" -t 12

# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 11
