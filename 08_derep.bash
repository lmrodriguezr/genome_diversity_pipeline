#!/bin/bash

target=$1
dataset=$2
scr=$(readlink -f "$0")
pkg=$(dirname "$scr")
echo "start step 8"
if [[ ! -n $target || ! -n $dataset ]] ; then
  echo "Usage: $0 target_folder dataset
  target_folder Path to the target folder containing the data
  dataset       Name of the dataset to process
  "
  exit 0
fi

# We don't need the genome_diversity_pipeline environment for this one
#. "$pkg/00_env.bash"
cd "$target"

dir="08_derep/$dataset"

echo "before the miga call"
miga new -P "$dir" -t genomes
miga add -P "$dir" -t popgenome -i assembly \
  -R '^(?:.*\/)?(.+?)(?i:\.f[nastq]+)?$' \
  --prefix maxbin_ -v 06_maxbin/"$dataset"-*/*.fasta
miga add -P "$dir" -t popgenome -i assembly \
  -R '^(?:.*\/)?(.+?)(?i:\.f[nastq]+)?$' \
  --prefix metabat_ -v 07_metabat/"$dataset"-*/*.fa

echo "after add adn assembly"

miga derep_wf -o "$dir" --fast -j 12 -t 1 -v 

echo "before calling ruby script"
# load miga environment to run this ruby script.
eval "$(miga env)"
"$pkg/scripts/08_01_gsp_qual.rb" "$dir" > "$dir/method_qual.tsv"

echo "after calling ruby script"
# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 09
