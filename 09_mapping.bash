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

dir="09_mapping/$dataset"
mkdir -p "$dir"

# Compile database
for genome in 08_derep/${dataset}/representatives/*.LargeContigs.fna ; do
  name=$(basename "$genome" .LargeContigs.fna)
  perl -pe 's/^>/>'$name':/' < "$genome" > "${genome}.tag"
done
cat 08_derep/${dataset}/representatives/*.LargeContigs.fna.tag \
  > 08_derep/${dataset}/representatives.fna

# Build mapping index
bwa-mem2 index -p "$dir/index" "08_derep/${dataset}/representatives.fna"

# Run mapping
files="02_trim/${dataset}.1.fastq.gz"
if [[ -e "02_trim/${dataset}.2.fastq.gz" ]] ; then
  files="$files 02_trim/${dataset}.2.fastq.gz"
fi
bwa-mem2 mem "$dir/index" $files

# Compress to BAM and sort it
samtools view -b "$dir/map.sam" -@ 12 \
  | samtools sort -l 9 -@ 11 -m 2G -o "$dir/map.bam" - \
  && rm "$dir/map.sam"

# Build BCF files
# TODO: Implement pi calculation
# for i in 90 95 97.5 ; do
#   sam.filter.rb -m "$dir/map.bam" --m-format bam -i "$i" \
#     | samtools view -b - -@ 12 \
#     | samtools sort -@ 12 - \
#     | bcftools mpileup -Ob -I -f "08_derep/${dataset}/representatives.fna" - \
#     | bcftools call -mv -v -Ob --ploidy 1 \
#     | bcftools filter -i'QUAL>15 && DP>5' -Oz -o "$dir/map-${i}.vcf.gz"
# done

# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 10
