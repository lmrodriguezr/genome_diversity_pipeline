#!/bin/bash

function cardinality {
  grep 'Unique 31-mers out:' "02_trim/${1}.log" | cut -f 2
}

function size_xx {
  SIZE=0
  for i in $@ ; do
    [[ -s "$i" ]] || continue
    let SIZE=$SIZE+$(file_size "$i")
  done
  echo $SIZE
}

function arithm {
  perl -e "print int($1)"
}

function size_01 {
  size_xx "01_reads/${1}.1.fastq.gz" "01_reads/${1}.2.fastq.gz"
}

function size_02 {
  size_xx "02_trim/${1}.1.fastq.gz" "02_trim/${1}.2.fastq.gz"
}

function size_03 {
  size_xx "03_norm/${1}.1.fastq.gz" "03_norm/${1}.2.fastq.gz"
}

function size_04 {
  size_xx \
    "04_asm/${1}-norm.LargeContigs.fna" "04_asm/${1}-trim.LargeContigs.fna"
}

function file_size {
  if [[ -e "$1" ]] ; then
    ls -pl "$1" | awk '{print $5}'
  else
    echo 0
  fi
}

function time_to_minutes {
  local t=$1
  echo "$t" | tr ':' ' ' | awk '{ print $1*60+$2+$3/60 }'
}

function run_stats {
  local dataset=$1
  local step=$2
  file="xx_log/${dataset}.${step}.txt"
  if [[ -s "$file" ]] ; then
    rsrc=$(grep '^Rsrc Used:' "$file" | head -n 1)
    cput=$(time_to_minutes "$(echo "$rsrc" | perl -pe 's/.*cput=(.+?),.*/$1/')")
    wallt=$(time_to_minutes "$(echo "$rsrc"| perl -pe 's/.*walltime=(.+)/$1/')")
    mem=$(echo "$rsrc" | perl -pe 's/.*mem=(.+?)kb,.*/$1/')
  fi
  echo -e "$mem\t$wallt\t$cput"
}

function next_step {
  local dataset=$1
  
  if [[ ! -s "01_reads/${dataset}.1.fastq.gz" ]] ; then
    next_step=01
  elif [[ ! -s "02_trim/${dataset}.1.fastq.gz" ]] ; then
    next_step=02
  elif [[ ! -s "03_norm/${dataset}.1.fastq.gz" ]] ; then
    next_step=03
  elif [[ ! -s "04_asm/${dataset}-norm-idba.LargeContigs.fna" ]] ; then
    next_step=04
  elif [[ ! -s "04_asm/${dataset}-norm-spad.LargeContigs.fna" ]] ; then
   next_step=05
  elif [[ ! -s "06_maxbin/${dataset}-norm-idba.d/${dataset}-norm-idba.summary" ]] ; then
    next_step=06
  elif [[ ! -s "07_metabat/${dataset}-norm-idba.d/${dataset}-norm-idba.1.fa" ]] ; then
    next_step=07
  elif [[ ! -s "08_derep/${dataset}/genomospecies.tsv" ]] ; then
    next_step=08
  elif [[ ! -s "09_anir/${dataset}/anir-95.tsv" ]] ; then
    next_step=09
  else
    next_step=XX
  fi

  echo $next_step
}

