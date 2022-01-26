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

# === FUNCTIONS ===

##
# Determine if subsampling is necessary, by checking if the requested
# fraction is 90% or smaller
function do_subsample {
  [[ $(perl -e "print int(10*$USE_FRACTION)") -lt 9 ]]
}

##
# Subsample single reads using FastA.sample.rb from Enveomics Collection
function subsample_single {
  local input=$1
  local output=$2
  if do_subsample ; then
    echo "Subsampling at $USE_FRACTION"
    FastA.sample.rb -i "$input" -o "$output" -f "$USE_FRACTION"
  else
    ln "$input" "$output"
  fi
}

##
# Subsample coupled reads using Roth's Fasta_subsample_interleaved_v3.py
function subsample_coupled {
  local input=$1
  local output=$2
  if do_subsample ; then
    perc="$(perl -e "print int($USE_FRACTION*100)")"
    [[ "$perc" -eq 0 ]] && perc=1
    echo "Subsampling at $perc%"
    Fasta_subsample_interleaved_v3.py -i "$input" -o "$output" -s "$perc"
    mv "${output}_sbsmpl"*.fa "$output"
  else
    ln "$input" "$output"
  fi
}

# === /FUNCTION ===

# initialize
USE_FRACTION=${USE_FRACTION:-1} # Use all reads by default
. "$pkg/00_env.bash"
cd "$target"

# assemble
for i in 0[23]*_*/"$dataset".*.fa ; do
  var=$(echo "$(dirname "$i")" | perl -pe 's/^\d+_//')
  base="04_asm/${dataset}-${var}"
  dir="${base}.d"
  rd="r"

### NEED TO ENSURE INPUT TO SPAdes

  # subsample & run assembly
  if [[ "$i" == *.single.fa ]] ; then
    rd="l" # <- for the assembly run
    subsample_single "$i" "${dir}.fa"
  else
    subsample_coupled "$i" "${dir}.fa"
  fi
 
  # SPAdes hates interleaved reads:
  # FastA.split.pl "${dir}.fa" ${dir} 2

  # reads=`echo -1 "${dir}.1.fa" -2 "${dir}.2.fa"`
  # echo "${reads}"
   spades.py --meta --only-assembler -o "${dataset}_spa" --12 "${dir}.fa" -m "${MEM}" -t 24 -k 21,33,55,77,99,127

  # link result -- SPAdes output in directory is called: contigs.fasta
  if [[ -s "${dataset}_spa/contigs.fasta" ]] ; then
    ln "${dataset}_spa/contigs.fasta" "${base}-spad.AllContigs.fna"
  else
    ln "${dataset}_spa/contigs.fasta" "${base}-spad.AllContigs.fna"
  fi

  # filter by length
  FastA.length.pl "${base}-spad.AllContigs.fna" | awk '$2 >= 1000 { print $1 }' \
    | FastA.filter.pl /dev/stdin "${base}-spad.AllContigs.fna" \
    > "${base}-spad.LargeContigs.fna"

  # cleanup
  rm "${base}-spad.AllContigs.fna"
  rm "${dir}.fa"
  rm "${dir}.1.fa"
  rm "${dir}.2.fa"
  rm -r "$dir"
  rm -r ${dataset}_spa
done

# If successful, Launch next step
if [[ -s "${base}-spad.LargeContigs.fna" ]] ; then
  "$pkg/00_launcher.bash" . "$dataset" 06
fi
