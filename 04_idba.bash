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

# fq -> fa
# The output is .fa, not .fa.gz, despite the relic .gz. in the file name
for i in 0[23]_*/"$dataset".[12].fastq.gz ; do
  gzip -c -d "$i" | awk -f "$(which FastQ.toFastA.awk)" > "${i}.fa_tmp"
done

# paired
for i in 0[23]_*/"$dataset".2.fastq.gz.fa_tmp ; do
  [[ -s "$i" ]] || continue
  d=$(dirname "$i")
  FastA.interpose.pl -T 0 "$d/${dataset}.coupled.fa" \
    "$d/${dataset}".[12].fastq.gz.fa_tmp
  rm "$d/${dataset}".[12].fastq.gz.fa_tmp
done

# single
for i in 0[23]_*/"$dataset".1.fastq.gz.fa_tmp ; do
  [[ -s "$i" ]] || continue
  d=$(dirname "$i")
  mv "$i" "$d/${dataset}.single.fa"
done

# assemble
for i in 0[23]*_*/"$dataset".*.fa ; do
  var=$(echo "$(dirname "$i")" | perl -pe 's/^\d+_//')
  base="04_asm/${dataset}-${var}"
  dir="${base}.d"
  rd="r"

  # subsample & run assembly
  if [[ "$i" == *.single.fa ]] ; then
    rd="l" # <- for the assembly run
    subsample_single "$i" "${dir}.fa"
  else
    subsample_coupled "$i" "${dir}.fa"
  fi
  idba_ud -o "$dir" -$rd "${dir}.fa" --num_threads 24 --maxk 120

  # link result
  if [[ -s "$dir/scaffold.fa" ]] ; then
    ln "$dir/scaffold.fa" "${base}-idba.AllContigs.fna"
  else
    ln "$dir/contig.fa" "${base}-idba.AllContigs.fna"
  fi

  # filter by length
  FastA.length.pl "${base}-idba.AllContigs.fna" | awk '$2 >= 1000 { print $1 }' \
    | FastA.filter.pl /dev/stdin "${base}-idba.AllContigs.fna" \
    > "${base}-idba.LargeContigs.fna"

  # cleanup
  rm "${base}-idba.AllContigs.fna"
  rm -r "$dir"
  rm "${dir}.fa"
done

# If successful, Launch next step
if [[ -s "${base}-idba.LargeContigs.fna" ]] ; then
  "$pkg/00_launcher.bash" . "$dataset" 05
fi
