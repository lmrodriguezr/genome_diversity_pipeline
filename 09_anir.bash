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

dir="09_anir/$dataset"
mkdir -p "$dir"

# Compile database
for genome in 08_derep/${dataset}/representatives/*.LargeContigs.fna ; do
  name=$(basename "$genome" .LargeContigs.fna)
  perl -pe 's/^>/>'$name':/' < "$genome" > "${genome}.tag"
done
cat 08_derep/${dataset}/representatives/*.LargeContigs.fna.tag \
  > 08_derep/${dataset}/representatives.fna

# Determine query settings
reads="single"
reads_file="02_trim/${dataset}.1.fastq.gz"
if [[ -e "02_trim/${dataset}.2.fastq.gz" ]] ; then
  reads="coupled"
  reads_file="${reads_file},02_trim/${dataset}.2.fastq.gz"
fi

# Run base ANIr to generate SAM file
anir.rb -g "08_derep/${dataset}/representatives.fna" \
  -r "$reads_file" --r-type "$reads" --r-format fastq \
  -m "$dir/map.sam" -t 12 -a fix -i 90

# Compress to BAM and sort it
samtools view -b "$dir/map.sam" -@ 12 \
  | samtools sort -l 9 -@ 11 -m 2G -o "$dir/map.bam" - \
  && rm "$dir/map.sam"

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

# Build BCF files
for i in 90 95 97.5 ; do
  sam.filter.rb -m "$dir/map.bam" --m-format bam -i "$i" \
    | samtools view -b - -@ 12 \
    | samtools sort -@ 12 - \
    | bcftools mpileup -Ob -I -f "08_derep/${dataset}/representatives.fna" - \
    | bcftools call -mv -v -Ob --ploidy 1 \
    | bcftools filter -i'QUAL>15 && DP>5' -Oz -o "$dir/map-${i}.vcf.gz"
done

# Summary of ANIr at 95% identity threshold
for i in $dir/*.anir-95.tsv ; do
  echo -e "$(basename "$i" .anir-95.tsv)\t$(tail -n 1 "$i")"
done > $dir/anir-95.tsv

#use coverm to get MAG abundances
echo "start coverm"
#mkdir -p "09_anir/${dataset}/coverm"
g_dir="08_derep/${dataset}/representatives"

for file in 02_trim/*.gz; do
out=$(basename "$file" .gz)
coverm genome --interleaved "${file}" -p bwa-mem -d ${g_dir} \
--min-read-percent-identity 95 --min-read-aligned-percent 70 --output-format sparse \
--trim-max 90 --trim-min 10 -m trimmed_mean -o "09_anir/${dataset}/coverm-out-${out}.txt"  -t 10

done
# Launch next step
"$pkg/00_launcher.bash" . "$dataset" 10
